import '../data/mock_providers.dart';
import '../models/ai_active_credentials.dart';
import '../models/ai_provider.dart';
import '../models/api_key.dart';
import '../models/api_key_pool.dart';
import 'secure_storage_service.dart';

class AIConfigManager {
  final SecureStorageService _storage;
  
  String? _selectedProviderId;
  final Map<String, String> _selectedModelIds = {};
  final Map<String, APIKeyPool> _pools = {};

  AIConfigManager(this._storage);

  String? get selectedProviderId => _selectedProviderId;
  
  String? getSelectedModelId(String providerId) => _selectedModelIds[providerId];

  APIKeyPool? getPool(String providerId) => _pools[providerId];

  Future<void> init() async {
    _selectedProviderId = await _storage.loadSelectedProvider();
    
    for (final provider in MockProviders.providers) {
      final pool = await _storage.loadKeyPool(provider.id);
      if (pool != null) {
        _pools[provider.id] = pool;
      }

      final modelId = await _storage.loadSelectedModel(provider.id);
      if (modelId != null) {
        _selectedModelIds[provider.id] = modelId;
      } else {
        // Default to first model if none saved
        _selectedModelIds[provider.id] = provider.models.first.id;
      }
    }
  }

  AIActiveCredentials? getActiveCredentials() {
    if (_selectedProviderId == null) return null;
    
    final providerId = _selectedProviderId!;
    final pool = _pools[providerId];
    final modelId = _selectedModelIds[providerId];
    
    if (pool == null || modelId == null) return null;
    
    final activeKey = pool.activeKey;
    if (activeKey == null || activeKey.isExhausted) return null;

    return AIActiveCredentials(
      providerId: providerId,
      modelId: modelId,
      apiKey: activeKey.value,
    );
  }

  Future<void> reportKeyExhausted() async {
    if (_selectedProviderId == null) return;
    final providerId = _selectedProviderId!;
    final pool = _pools[providerId];
    if (pool == null) return;

    final currentKeys = List<APIKey>.from(pool.keys);
    if (pool.activeIndex >= 0 && pool.activeIndex < currentKeys.length) {
      // Mark current key as exhausted
      currentKeys[pool.activeIndex] = currentKeys[pool.activeIndex].copyWith(isExhausted: true);
    }

    // Try to find next non-exhausted key
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
      activeIndex: nextIndex != -1 ? nextIndex : 0, // Fallback to 0 if all exhausted
    );

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
    
    // TODO: Notify Cubit here in Phase 3
  }

  Future<void> addKey(String providerId, String keyValue) async {
    final pool = _pools[providerId] ?? APIKeyPool(providerId: providerId, keys: []);
    
    final newKey = APIKey(
      value: keyValue,
      createdAt: DateTime.now(),
    );

    final updatedKeys = List<APIKey>.from(pool.keys)..add(newKey);
    final updatedPool = pool.copyWith(keys: updatedKeys);

    _pools[providerId] = updatedPool;
    await _storage.saveKeyPool(updatedPool);
  }

  Future<void> selectProvider(String providerId) async {
    _selectedProviderId = providerId;
    await _storage.saveSelectedProvider(providerId);
  }

  Future<void> selectModel(String providerId, String modelId) async {
    _selectedModelIds[providerId] = modelId;
    await _storage.saveSelectedModel(providerId, modelId);
  }
}
