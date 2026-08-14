import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/provider_definitions.dart';
import '../models/ai_model.dart';
import '../services/ai_config_manager.dart';
import 'ai_config_state.dart';

class AIConfigCubit extends Cubit<AIConfigState> {
  final AIConfigManager _manager;

  AIConfigCubit(this._manager) : super(const AIConfigState());

  Future<void> loadConfig() async {
    emit(state.copyWith(status: AIConfigStatus.loading));
    try {
      final providers = ProviderDefinitions.definitions;
      _updateState(providers: providers);
    } catch (e) {
      emit(state.copyWith(
        status: AIConfigStatus.error,
        errorMessage: 'Error loading configuration: $e',
      ));
    }
  }

  void _updateState({
    List<ProviderDefinition>? providers, 
    AIConfigStatus? status, 
    String? successMessage, 
    String? errorMessage,
  }) {
    final currentProviders = providers ?? state.providers;
    final Map<String, String> modelIds = {};
    final Map<String, List<AIModel>> providerModels = {};

    for (final p in currentProviders) {
      final selectedModel = _manager.getSelectedModelId(p.id);
      if (selectedModel != null) {
        modelIds[p.id] = selectedModel;
      }
      providerModels[p.id] = _manager.getModels(p.id);
    }

    emit(state.copyWith(
      providers: currentProviders,
      selectedProviderId: _manager.selectedProviderId,
      selectedModelIds: modelIds,
      providerModels: providerModels,
      keyPools: {
        for (final p in currentProviders)
          if (_manager.getPool(p.id) != null) p.id: _manager.getPool(p.id)!
      },
      status: status ?? AIConfigStatus.ready,
      successMessage: successMessage,
      errorMessage: errorMessage,
    ));
  }

  Future<void> selectProvider(String providerId) async {
    await _manager.selectProvider(providerId);
    _updateState(successMessage: 'Provider updated');
  }

  Future<void> selectModel(String providerId, String modelId) async {
    await _manager.selectModel(providerId, modelId);
    _updateState(successMessage: 'Model selected');
  }

  Future<void> addKey(String providerId, String key) async {
    emit(state.copyWith(status: AIConfigStatus.discoveryInProgress));
    try {
      await _manager.addKey(providerId, key);
      final models = _manager.getModels(providerId);
      if (models.isNotEmpty) {
        _updateState(successMessage: 'Key added and ${models.length} models discovered');
      } else {
        _updateState(errorMessage: 'Key added, but no models found. Check your key.');
      }
    } catch (e) {
      _updateState(errorMessage: 'Error adding key: $e');
    }
  }

  Future<void> removeKey(String providerId, String key) async {
    await _manager.removeKey(providerId, key);
    _updateState(successMessage: 'Key removed');
  }

  Future<void> reportExhausted() async {
    await _manager.reportKeyExhausted();
    _updateState(errorMessage: 'Key exhausted, rotating...');
  }

  Future<void> refreshModels(String providerId) async {
    emit(state.copyWith(status: AIConfigStatus.discoveryInProgress));
    try {
      await _manager.refreshModels(providerId);
      final models = _manager.getModels(providerId);
      if (models.isNotEmpty) {
        _updateState(successMessage: 'Sync completed: ${models.length} models');
      } else {
        _updateState(errorMessage: 'Sync finished with no new models');
      }
    } catch (e) {
      _updateState(errorMessage: 'Sync error: $e');
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void toggleOnlyFree(bool value) {
    emit(state.copyWith(onlyFree: value));
  }

  void clearMessages() {
    emit(state.copyWith(successMessage: null, errorMessage: null));
  }
}
