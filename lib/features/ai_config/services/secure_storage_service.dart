import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ai_model.dart';
import '../models/api_key_pool.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _keyPrefix = 'ai_pool_';
  static const String _selectedProviderKey = 'active_provider_id';
  static const String _selectedModelPrefix = 'active_model_';

  static const String _modelsPrefix = 'ai_models_';

  Future<void> saveModels(String providerId, List<AIModel> models) async {
    final List<Map<String, dynamic>> jsonList = models.map((m) => m.toJson()).toList();
    await _storage.write(key: '$_modelsPrefix$providerId', value: jsonEncode(jsonList));
  }

  Future<List<AIModel>> loadModels(String providerId) async {
    final String? jsonString = await _storage.read(key: '$_modelsPrefix$providerId');
    if (jsonString == null) return [];
    try {
      final List jsonList = jsonDecode(jsonString);
      return jsonList.map((m) => AIModel.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveKeyPool(APIKeyPool pool) async {
    final String jsonString = jsonEncode(pool.toJson());
    await _storage.write(key: '$_keyPrefix${pool.providerId}', value: jsonString);
  }

  Future<APIKeyPool?> loadKeyPool(String providerId) async {
    final String? jsonString = await _storage.read(key: '$_keyPrefix$providerId');
    if (jsonString == null) return null;
    try {
      return APIKeyPool.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSelectedProvider(String providerId) async {
    await _storage.write(key: _selectedProviderKey, value: providerId);
  }

  Future<String?> loadSelectedProvider() async {
    return await _storage.read(key: _selectedProviderKey);
  }

  Future<void> saveSelectedModel(String providerId, String modelId) async {
    await _storage.write(key: '$_selectedModelPrefix$providerId', value: modelId);
  }

  Future<String?> loadSelectedModel(String providerId) async {
    return await _storage.read(key: '$_selectedModelPrefix$providerId');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
