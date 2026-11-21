import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../data/provider_definitions.dart';
import '../models/ai_active_credentials.dart';
import '../models/ai_model.dart';
import '../models/api_key.dart';
import '../models/api_key_pool.dart';
import '../models/custom_provider.dart';
import 'discovery_service.dart';
import 'secure_storage_service.dart';

class AIConfigManager extends ChangeNotifier {
  final SecureStorageService _storage;
  final DiscoveryService _discovery;
  final Duration exhaustionTimeout;
  
  String? _selectedProviderId;
  final Map<String, String> _selectedModelIds = {};
  final Map<String, APIKeyPool> _pools = {};
  final Map<String, List<AIModel>> _cachedModels = {};
  final List<CustomProvider> _customProviders = [];

  AIConfigManager({
    required this._storage,
    required this._discovery,
    this.exhaustionTimeout = const Duration(hours: 8),
  });

  List<CustomProvider> get customProviders => List.unmodifiable(_customProviders);
  String? get selectedProviderId => _selectedProviderId;
  String? getSelectedModelId(String providerId) => _selectedModelIds[providerId];
  APIKeyPool? getPool(String providerId) => _pools[providerId];
  List<AIModel> getModels(String providerId) => _cachedModels[providerId] ?? [];

  Future<void> init() async {
    developer.log('Initializing AIConfigManager...', name: 'AIConfigManager');
    
    _selectedProviderId = await _storage.loadSelectedProvider();
    _customProviders.addAll(await _storage.loadCustomProviders());
    
    final allProviders = getAllProviders();
    for (final def in allProviders) {
      final pool = await _storage.loadKeyPool(def.id);
      if (pool != null) {
        // Apply cool-down check on init
        _pools[def.id] = _checkCoolDown(pool);
      }

      final models = await _storage.loadModels(def.id);
      if (models.isNotEmpty) {
        _cachedModels[def.id] = models;
      }

      final modelId = await _storage.loadSelectedModel(def.id);
      if (modelId != null) {
        _selectedModelIds[def.id] = modelId;
      }
    }

    if (_selectedProviderId == null && _pools.isNotEmpty) {
      _selectedProviderId = _pools.keys.first;
      await _storage.saveSelectedProvider(_selectedProviderId!);
    }

    developer.log('Initialization complete. Active Provider: $_selectedProviderId', name: 'AIConfigManager');
    notifyListeners();
  }

  APIKeyPool _checkCoolDown(APIKeyPool pool) {
    bool changed = false;
    final updatedKeys = pool.keys.map((key) {
      if (key.isExhausted && key.exhaustedAt != null) {
        final timeSinceExhaustion = DateTime.now().difference(key.exhaustedAt!);
        if (timeSinceExhaustion >= exhaustionTimeout) {
          changed = true;
          return key.copyWith(isExhausted: false, exhaustedAt: null);
        }
      }
      return key;
    }).toList();

    if (changed) {
      return pool.copyWith(keys: updatedKeys);
    }
    return pool;
  }

  List<ProviderDefinition> getAllProviders() {
    final List<ProviderDefinition> list = List.from(ProviderDefinitions.definitions);
    list.addAll(_customProviders.map((cp) => cp.toDefinition()));
    return list;
  }

  Future<void> addCustomProvider(CustomProvider provider) async {
    _customProviders.add(provider);
    await _storage.saveCustomProviders(_customProviders);
    notifyListeners();
  }

  Future<void> removeCustomProvider(String providerId) async {
    _customProviders.removeWhere((p) => p.id == providerId);
    await _storage.saveCustomProviders(_customProviders);
    if (_selectedProviderId == providerId) _selectedProviderId = null;
    notifyListeners();
  }

  Future<void> updateCustomProvider(CustomProvider updatedProvider) async {
    final index = _customProviders.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _customProviders[index] = updatedProvider;
      await _storage.saveCustomProviders(_customProviders);
      // Refresh models for this provider
      await refreshModels(updatedProvider.id);
      notifyListeners();
    }
  }

  AIActiveCredentials? getActiveCredentials() {
    if (_selectedProviderId == null) return null;
    
    final providerId = _selectedProviderId!;
    var pool = _pools[providerId];
    if (pool == null) return null;

    // Proactive cool-down check
    pool = _checkCoolDown(pool);
    _pools[providerId] = pool;

    final modelId = _selectedModelIds[providerId];
    if (modelId == null) return null;
    
    var activeKey = pool.activeKey;
    if (activeKey == null || activeKey.isExhausted) {
      final availableKeyIndex = pool.keys.indexWhere((k) => !k.isExhausted);
      if (availableKeyIndex != -1) {
        final updatedPool = pool.copyWith(activeIndex: availableKeyIndex);
        _pools[providerId] = updatedPool;
        _storage.saveKeyPool(updatedPool);
        activeKey = updatedPool.activeKey;
      } else {
        return null;
      }
    }

    return AIActiveCredentials(
      providerId: providerId,
      modelId: modelId,
      apiKey: activeKey!.value,
    );
  }

  Future<void> reportKeyExhausted() async {
    if (_selectedProviderId == null) return;
    final providerId = _selectedProviderId!;
    final pool = _pools[providerId];
    if (pool == null) return;

    final currentKeys = List<APIKey>.from(pool.keys);
    if (pool.activeIndex >= 0 && pool.activeIndex < currentKeys.length) {
      currentKeys[pool.activeIndex] = currentKeys[pool.activeIndex].copyWith(
        isExhausted: true,
        exhaustedAt: DateTime.now(),
      );
    }

    int nextIndex = -1;
    for (int i = 0; i < currentKeys.length; i++) {
      int checkIndex = (pool.activeIndex + 1 + i) % currentKeys.length;
      if (!currentKeys[checkIndex].isExhausted) {
        nextIndex = checkIndex;
        break;
      }
    }

    final updatedPool = pool.copyWith(
      keys: currentKeys,
      activeIndex: nextIndex != -1 ? nextIndex : 0,
    );

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    notifyListeners();
  }

  /// Adds a key with Proactive Validation.
  Future<void> addKey(String providerId, String keyValue) async {
    // 1. Validation check
    final allProviders = getAllProviders();
    final definition = allProviders.firstWhere((d) => d.id == providerId);
    
    // We try to fetch models to validate the key
    try {
      await _discovery.fetchModels(definition, keyValue);
    } catch (e) {
      developer.log('Key validation failed: $e', name: 'AIConfigManager');
      rethrow; // Inform the UI that the key is invalid
    }

    final pool = _pools[providerId] ?? APIKeyPool(providerId: providerId, keys: []);
    if (pool.keys.any((k) => k.value == keyValue)) return;

    final newKey = APIKey(value: keyValue, createdAt: DateTime.now());
    final updatedKeys = List<APIKey>.from(pool.keys)..add(newKey);
    final updatedPool = pool.copyWith(keys: updatedKeys);

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);

    if (_selectedProviderId == null) await selectProvider(providerId);
    await refreshModels(providerId);
    notifyListeners();
  }

  Future<void> removeKey(String providerId, String keyValue) async {
    final pool = _pools[providerId];
    if (pool == null) return;

    final updatedKeys = pool.keys.where((k) => k.value != keyValue).toList();
    int newActiveIndex = pool.activeIndex;
    if (newActiveIndex >= updatedKeys.length) {
      newActiveIndex = updatedKeys.isEmpty ? 0 : updatedKeys.length - 1;
    }

    final updatedPool = pool.copyWith(keys: updatedKeys, activeIndex: newActiveIndex);
    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    notifyListeners();
  }

  Future<void> reorderKeys(String providerId, int oldIndex, int newIndex) async {
    final pool = _pools[providerId];
    if (pool == null) return;

    final keys = List<APIKey>.from(pool.keys);
    
    // Flutter adjustment for ReorderableListView
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = keys.removeAt(oldIndex);
    keys.insert(newIndex, item);

    final updatedPool = pool.copyWith(keys: keys, activeIndex: 0);
    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    notifyListeners();
  }

  Future<void> refreshModels(String providerId) async {
    final allProviders = getAllProviders();
    final definition = allProviders.firstWhere((d) => d.id == providerId);
    final pool = _pools[providerId];
    final apiKey = pool?.activeKey?.value;

    if (definition.requiresKeyForDiscovery && apiKey == null) return;

    try {
      final models = await _discovery.fetchModels(definition, apiKey);
      if (models.isNotEmpty) {
        _cachedModels[providerId] = models;
        await _storage.saveModels(providerId, models);
        if (_selectedModelIds[providerId] == null) {
          await selectModel(providerId, models.first.id);
        }
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> selectProvider(String providerId) async {
    _selectedProviderId = providerId;
    await _storage.saveSelectedProvider(providerId);
    if ((_cachedModels[providerId] ?? []).isEmpty) await refreshModels(providerId);
    notifyListeners();
  }

  Future<void> selectModel(String providerId, String modelId) async {
    _selectedProviderId = providerId;
    _selectedModelIds[providerId] = modelId;
    await _storage.saveSelectedProvider(providerId);
    await _storage.saveSelectedModel(providerId, modelId);
    notifyListeners();
  }
}
