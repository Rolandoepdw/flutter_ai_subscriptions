import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/data/mock_providers.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_provider.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/ai_config_manager.dart';
import 'ai_config_state.dart';

class AIConfigCubit extends Cubit<AIConfigState> {
  final AIConfigManager _manager;

  AIConfigCubit(this._manager) : super(const AIConfigState());

  Future<void> loadConfig() async {
    emit(state.copyWith(status: AIConfigStatus.loading));
    try {
      final providers = MockProviders.providers;
      final selectedProviderId = _manager.selectedProviderId;
      
      final Map<String, String> modelIds = {};
      final Map<String, dynamic> pools = {}; // We'll map them properly below

      for (final p in providers) {
        modelIds[p.id] = _manager.getSelectedModelId(p.id) ?? p.models.first.id;
      }

      _updateState(providers: providers, selectedProviderId: selectedProviderId);
    } catch (e) {
      emit(state.copyWith(status: AIConfigStatus.error, errorMessage: e.toString()));
    }
  }

  void _updateState({List<AIProvider>? providers, String? selectedProviderId}) {
    final currentProviders = providers ?? state.providers;
    final Map<String, String> modelIds = {};

    for (final p in currentProviders) {
      modelIds[p.id] = _manager.getSelectedModelId(p.id) ?? p.models.first.id;
    }

    emit(state.copyWith(
      providers: currentProviders,
      selectedProviderId: selectedProviderId ?? _manager.selectedProviderId,
      selectedModelIds: modelIds,
      keyPools: {
        for (final p in currentProviders)
          if (_manager.getPool(p.id) != null) p.id: _manager.getPool(p.id)!
      },
      status: AIConfigStatus.ready,
    ));
  }

  Future<void> selectProvider(String providerId) async {
    await _manager.selectProvider(providerId);
    _updateState();
  }

  Future<void> selectModel(String providerId, String modelId) async {
    await _manager.selectModel(providerId, modelId);
    _updateState();
  }

  Future<void> addKey(String providerId, String key) async {
    await _manager.addKey(providerId, key);
    _updateState();
  }

  Future<void> reportExhausted() async {
    await _manager.reportKeyExhausted();
    _updateState();
  }
}
