import 'dart:developer' as developer;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_active_credentials.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/api_key.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/api_key_pool.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/custom_provider.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/discovery_service.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/secure_storage_service.dart';

class AIConfigManager {
  final SecureStorageService _storage;
  final DiscoveryService _discovery;
  
  String? _selectedProviderId;
  final Map<String, String> _selectedModelIds = {};
  final Map<String, APIKeyPool> _pools = {};
  final Map<String, List<AIModel>> _cachedModels = {};
  final List<CustomProvider> _customProviders = [];

  AIConfigManager(this._storage, this._discovery);

  List<CustomProvider> get customProviders => List.unmodifiable(_customProviders);

  String? get selectedProviderId => _selectedProviderId;
  
  String? getSelectedModelId(String providerId) => _selectedModelIds[providerId];

  APIKeyPool? getPool(String providerId) => _pools[providerId];

  List<AIModel> getModels(String providerId) => _cachedModels[providerId] ?? [];

  Future<void> init() async {
    developer.log('Initializing AIConfigManager...', name: 'AIConfigManager');
    
    // 1. Load active provider
    _selectedProviderId = await _storage.loadSelectedProvider();
    
    // 2. Load custom providers
    _customProviders.addAll(await _storage.loadCustomProviders());
    
    // 3. Load pools and cached models for ALL providers (Built-in + Custom)
    final allProviders = await getAllProviders();
    for (final def in allProviders) {
      final pool = await _storage.loadKeyPool(def.id);
      if (pool != null) {
        _pools[def.id] = pool;
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
  }

  Future<List<ProviderDefinition>> getAllProviders() async {
    final List<ProviderDefinition> list = List.from(ProviderDefinitions.definitions);
    list.addAll(_customProviders.map((cp) => cp.toDefinition()));
    return list;
  }

  Future<void> addCustomProvider(CustomProvider provider) async {
    _customProviders.add(provider);
    await _storage.saveCustomProviders(_customProviders);
  }

  Future<void> updateCustomProvider(CustomProvider updatedProvider) async {
    final index = _customProviders.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _customProviders[index] = updatedProvider;
      await _storage.saveCustomProviders(_customProviders);
      // If the URL changed, we might need to refresh models
      await refreshModels(updatedProvider.id);
    }
  }

  Future<void> removeCustomProvider(String providerId) async {
    _customProviders.removeWhere((p) => p.id == providerId);
    await _storage.saveCustomProviders(_customProviders);
    // Cleanup storage for this provider if needed
    if (_selectedProviderId == providerId) _selectedProviderId = null;
  }

  AIActiveCredentials? getActiveCredentials() {
    if (_selectedProviderId == null) return null;
    
    final providerId = _selectedProviderId!;
    final pool = _pools[providerId];
    final modelId = _selectedModelIds[providerId];
    
    if (pool == null || modelId == null) return null;
    
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
      currentKeys[pool.activeIndex] = currentKeys[pool.activeIndex].copyWith(isExhausted: true);
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
  }

  Future<void> addKey(String providerId, String keyValue) async {
    final pool = _pools[providerId] ?? APIKeyPool(providerId: providerId, keys: []);
    if (pool.keys.any((k) => k.value == keyValue)) return;

    final newKey = APIKey(value: keyValue, createdAt: DateTime.now());
    final updatedKeys = List<APIKey>.from(pool.keys)..add(newKey);
    final updatedPool = pool.copyWith(keys: updatedKeys);

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);

    if (_selectedProviderId == null) await selectProvider(providerId);
    await refreshModels(providerId);
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
  }

  Future<void> refreshModels(String providerId) async {
    final allProviders = await getAllProviders();
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> selectProvider(String providerId) async {
    _selectedProviderId = providerId;
    await _storage.saveSelectedProvider(providerId);
    if ((_cachedModels[providerId] ?? []).isEmpty) await refreshModels(providerId);
  }

  Future<void> selectModel(String providerId, String modelId) async {
    _selectedModelIds[providerId] = modelId;
    await _storage.saveSelectedModel(providerId, modelId);
  }
}
