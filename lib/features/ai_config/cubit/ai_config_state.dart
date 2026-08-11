import 'package:equatable/equatable.dart';
import '../models/ai_provider.dart';
import '../models/api_key_pool.dart';

enum AIConfigStatus { initial, loading, ready, error }

class AIConfigState extends Equatable {
  final List<AIProvider> providers;
  final String? selectedProviderId;
  final Map<String, String> selectedModelIds;
  final Map<String, APIKeyPool> keyPools;
  final AIConfigStatus status;
  final String? errorMessage;

  const AIConfigState({
    this.providers = const [],
    this.selectedProviderId,
    this.selectedModelIds = const {},
    this.keyPools = const {},
    this.status = AIConfigStatus.initial,
    this.errorMessage,
  });

  AIConfigState copyWith({
    List<AIProvider>? providers,
    String? selectedProviderId,
    Map<String, String>? selectedModelIds,
    Map<String, APIKeyPool>? keyPools,
    AIConfigStatus? status,
    String? errorMessage,
  }) {
    return AIConfigState(
      providers: providers ?? this.providers,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelIds: selectedModelIds ?? this.selectedModelIds,
      keyPools: keyPools ?? this.keyPools,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        selectedProviderId,
        selectedModelIds,
        keyPools,
        status,
        errorMessage,
      ];
}
