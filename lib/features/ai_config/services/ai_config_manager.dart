import 'dart:developer' as developer;
import '../data/provider_definitions.dart';
import '../models/ai_active_credentials.dart';
import '../models/ai_model.dart';
import '../models/api_key.dart';
import '../models/api_key_pool.dart';
import 'discovery_service.dart';
import 'secure_storage_service.dart';

class AIConfigManager {
  final SecureStorageService _storage;
  final DiscoveryService _discovery;
  
  String? _selectedProviderId;
  final Map<String, String> _selectedModelIds = {};
  final Map<String, APIKeyPool> _pools = {};
  final Map<String, List<AIModel>> _cachedModels = {};

  AIConfigManager(this._storage, this._discovery);

  String? get selectedProviderId => _selectedProviderId;
  
  String? getSelectedModelId(String providerId) => _selectedModelIds[providerId];

  APIKeyPool? getPool(String providerId) => _pools[providerId];

  List<AIModel> getModels(String providerId) => _cachedModels[providerId] ?? [];

  Future<void> init() async {
    developer.log('Initializing AIConfigManager...', name: 'AIConfigManager');
    
    // 1. Load active provider
    _selectedProviderId = await _storage.loadSelectedProvider();
    
    // 2. Load pools and cached models for ALL providers
    for (final def in ProviderDefinitions.definitions) {
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

    // 3. Fallback logic: Ensure we have a provider if possible
    if (_selectedProviderId == null && _pools.isNotEmpty) {
      _selectedProviderId = _pools.keys.first;
      await _storage.saveSelectedProvider(_selectedProviderId!);
    }

    // 4. Background refresh of models for the active provider if cache is empty
    if (_selectedProviderId != null && (_cachedModels[_selectedProviderId] ?? []).isEmpty) {
      // Don't await this to keep init() fast
      refreshModels(_selectedProviderId!).catchError((e) {
        developer.log('Initial background refresh failed for $_selectedProviderId: $e', name: 'AIConfigManager');
      });
    }

    developer.log('Initialization complete. Active Provider: $_selectedProviderId', name: 'AIConfigManager');
  }

  AIActiveCredentials? getActiveCredentials() {
    if (_selectedProviderId == null) return null;
    
    final providerId = _selectedProviderId!;
    final pool = _pools[providerId];
    final modelId = _selectedModelIds[providerId];
    
    if (pool == null || modelId == null) return null;
    
    // Get the active key. If it's exhausted, try to rotate.
    var activeKey = pool.activeKey;
    if (activeKey == null || activeKey.isExhausted) {
      // Try to find any non-exhausted key in the pool
      final availableKeyIndex = pool.keys.indexWhere((k) => !k.isExhausted);
      if (availableKeyIndex != -1) {
        final updatedPool = pool.copyWith(activeIndex: availableKeyIndex);
        _pools[providerId] = updatedPool;
        _storage.saveKeyPool(updatedPool);
        activeKey = updatedPool.activeKey;
      } else {
        return null; // All keys truly exhausted
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

    developer.log('Reporting key exhausted for provider: $providerId', name: 'AIConfigManager');

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
    developer.log('Key rotated. New index: ${updatedPool.activeIndex}', name: 'AIConfigManager');
  }

  Future<void> addKey(String providerId, String keyValue) async {
    developer.log('Adding key to provider: $providerId', name: 'AIConfigManager');
    final pool = _pools[providerId] ?? APIKeyPool(providerId: providerId, keys: []);
    
    // Check if key already exists to avoid duplicates
    if (pool.keys.any((k) => k.value == keyValue)) {
      developer.log('Key already exists in pool.', name: 'AIConfigManager');
      return;
    }

    final newKey = APIKey(
      value: keyValue,
      createdAt: DateTime.now(),
    );

    final updatedKeys = List<APIKey>.from(pool.keys)..add(newKey);
    final updatedPool = pool.copyWith(keys: updatedKeys);

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    developer.log('Key saved successfully.', name: 'AIConfigManager');

    // Automatically select this provider if it's the first one
    if (_selectedProviderId == null) {
      await selectProvider(providerId);
    }

    await refreshModels(providerId);
  }

  Future<void> removeKey(String providerId, String keyValue) async {
    final pool = _pools[providerId];
    if (pool == null) return;

    final updatedKeys = pool.keys.where((k) => k.value != keyValue).toList();
    
    // Adjust activeIndex if necessary
    int newActiveIndex = pool.activeIndex;
    if (newActiveIndex >= updatedKeys.length) {
      newActiveIndex = updatedKeys.isEmpty ? 0 : updatedKeys.length - 1;
    }

    final updatedPool = pool.copyWith(keys: updatedKeys, activeIndex: newActiveIndex);
    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    
    developer.log('Key removed from $providerId.', name: 'AIConfigManager');
  }

  Future<void> refreshModels(String providerId) async {
    developer.log('Refreshing models for provider: $providerId', name: 'AIConfigManager');
    final definition = ProviderDefinitions.definitions.firstWhere((d) => d.id == providerId);
    final pool = _pools[providerId];
    final apiKey = pool?.activeKey?.value;

    if (definition.requiresKeyForDiscovery && apiKey == null) {
      developer.log('Refresh aborted: Provider $providerId requires an API Key for discovery.', name: 'AIConfigManager');
      return;
    }

    try {
      final models = await _discovery.fetchModels(definition, apiKey);
      if (models.isNotEmpty) {
        developer.log('Successfully discovered ${models.length} models for $providerId', name: 'AIConfigManager');
        _cachedModels[providerId] = models;
        await _storage.saveModels(providerId, models);
        
        if (_selectedModelIds[providerId] == null) {
          await selectModel(providerId, models.first.id);
        }
      } else {
        developer.log('Discovery completed but no models were found for $providerId', name: 'AIConfigManager');
      }
    } catch (e, stack) {
      developer.log('Error refreshing models for $providerId: $e', name: 'AIConfigManager', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> selectProvider(String providerId) async {
    developer.log('Selecting provider: $providerId', name: 'AIConfigManager');
    _selectedProviderId = providerId;
    await _storage.saveSelectedProvider(providerId);
    
    if ((_cachedModels[providerId] ?? []).isEmpty) {
      await refreshModels(providerId);
    }
  }

  Future<void> selectModel(String providerId, String modelId) async {
    developer.log('Selecting model: $modelId for provider: $providerId', name: 'AIConfigManager');
    _selectedModelIds[providerId] = modelId;
    await _storage.saveSelectedModel(providerId, modelId);
  }
}
