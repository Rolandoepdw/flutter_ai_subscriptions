import 'package:flutter/foundation.dart';
import '../data/provider_definitions.dart';
import '../models/ai_model.dart';
import '../models/api_key_pool.dart';
import '../models/custom_provider.dart';
import '../services/ai_config_manager.dart';

enum AIConfigStatus { initial, loading, discoveryInProgress, ready, error }

class AIConfigNotifier extends ChangeNotifier {
  final AIConfigManager _manager;

  AIConfigNotifier(this._manager) {
    _manager.addListener(_syncFromManager);
    _syncFromManager();
  }

  AIConfigStatus _status = AIConfigStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';
  bool _onlyFree = false;

  AIConfigStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  bool get onlyFree => _onlyFree;

  // Data from manager
  List<ProviderDefinition> _providers = [];
  List<ProviderDefinition> get providers => _providers;
  List<CustomProvider> get customProviders => _manager.customProviders;
  String? get selectedProviderId => _manager.selectedProviderId;

  Future<void> loadConfig() async {
    _status = AIConfigStatus.loading;
    notifyListeners();
    try {
      await _manager.init();
      _providers = _manager.getAllProviders();
      _status = AIConfigStatus.ready;
    } catch (e) {
      _status = AIConfigStatus.error;
      _errorMessage = 'Error loading configuration: $e';
    }
    notifyListeners();
  }

  void _syncFromManager() {
    _providers = _manager.getAllProviders();
    if (_providers.isNotEmpty && _status == AIConfigStatus.initial) {
      _status = AIConfigStatus.ready;
    }
    notifyListeners();
  }

  List<AIModel> getFilteredModels(String providerId) {
    final allModels = _manager.getModels(providerId);
    return _applyFilters(allModels);
  }

  List<AIModel> _applyFilters(List<AIModel> models) {
    return models.where((model) {
      final matchesSearch = model.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           model.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFree = !_onlyFree || model.tier.name == 'free';
      return matchesSearch && matchesFree;
    }).toList();
  }

  APIKeyPool? getPool(String providerId) => _manager.getPool(providerId);
  String? getSelectedModelId(String providerId) => _manager.getSelectedModelId(providerId);

  // Actions
  Future<void> selectProvider(String providerId) async {
    await _manager.selectProvider(providerId);
    _successMessage = 'Provider updated';
    notifyListeners();
  }

  Future<void> selectModel(String providerId, String modelId) async {
    await _manager.selectModel(providerId, modelId);
    _successMessage = 'Model selected';
    notifyListeners();
  }

  Future<void> addKey(String providerId, String key) async {
    _status = AIConfigStatus.discoveryInProgress;
    _errorMessage = null;
    notifyListeners();
    try {
      await _manager.addKey(providerId, key);
      _successMessage = 'Key added and models refreshed';
      _status = AIConfigStatus.ready;
    } catch (e) {
      _errorMessage = 'Error adding key: $e';
      _status = AIConfigStatus.ready;
    }
    notifyListeners();
  }

  Future<void> removeKey(String providerId, String key) async {
    await _manager.removeKey(providerId, key);
    _successMessage = 'Key removed';
    notifyListeners();
  }

  Future<void> reorderKeys(String providerId, int oldIndex, int newIndex) async {
    await _manager.reorderKeys(providerId, oldIndex, newIndex);
    notifyListeners();
  }

  Future<void> refreshModels(String providerId) async {
    _status = AIConfigStatus.discoveryInProgress;
    notifyListeners();
    try {
      await _manager.refreshModels(providerId);
      _successMessage = 'Sync completed';
      _status = AIConfigStatus.ready;
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _status = AIConfigStatus.ready;
    }
    notifyListeners();
  }

  // Custom Provider CRUD
  Future<void> addCustomProvider(CustomProvider provider) async {
    await _manager.addCustomProvider(provider);
    _successMessage = 'Custom provider added';
    notifyListeners();
  }

  Future<void> removeCustomProvider(String providerId) async {
    await _manager.removeCustomProvider(providerId);
    _successMessage = 'Custom provider removed';
    notifyListeners();
  }

  Future<void> updateCustomProvider(CustomProvider provider) async {
    await _manager.updateCustomProvider(provider);
    _successMessage = 'Custom provider updated';
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleOnlyFree(bool value) {
    _onlyFree = value;
    notifyListeners();
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _manager.removeListener(_syncFromManager);
    super.dispose();
  }
}
