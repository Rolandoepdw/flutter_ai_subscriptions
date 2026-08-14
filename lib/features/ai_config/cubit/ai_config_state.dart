import 'package:equatable/equatable.dart';
import '../data/provider_definitions.dart';
import '../models/ai_model.dart';
import '../models/api_key_pool.dart';

enum AIConfigStatus { initial, loading, discoveryInProgress, ready, error }

class AIConfigState extends Equatable {
  final List<ProviderDefinition> providers;
  final String? selectedProviderId;
  final Map<String, String> selectedModelIds;
  final Map<String, List<AIModel>> providerModels;
  final Map<String, APIKeyPool> keyPools;
  final AIConfigStatus status;
  final String? errorMessage;
  final String? successMessage;
  
  // Search and Filtering
  final String searchQuery;
  final bool onlyFree;

  const AIConfigState({
    this.providers = const [],
    this.selectedProviderId,
    this.selectedModelIds = const {},
    this.providerModels = const {},
    this.keyPools = const {},
    this.status = AIConfigStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.onlyFree = false,
  });

  List<AIModel> getFilteredModels(String providerId) {
    final allModels = providerModels[providerId] ?? [];
    return allModels.where((model) {
      final matchesSearch = model.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                           model.id.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFree = !onlyFree || model.tier.name == 'free';
      return matchesSearch && matchesFree;
    }).toList();
  }

  AIConfigState copyWith({
    List<ProviderDefinition>? providers,
    String? selectedProviderId,
    Map<String, String>? selectedModelIds,
    Map<String, List<AIModel>>? providerModels,
    Map<String, APIKeyPool>? keyPools,
    AIConfigStatus? status,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    bool? onlyFree,
  }) {
    return AIConfigState(
      providers: providers ?? this.providers,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelIds: selectedModelIds ?? this.selectedModelIds,
      providerModels: providerModels ?? this.providerModels,
      keyPools: keyPools ?? this.keyPools,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyFree: onlyFree ?? this.onlyFree,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        selectedProviderId,
        selectedModelIds,
        providerModels,
        keyPools,
        status,
        errorMessage,
        successMessage,
        searchQuery,
        onlyFree,
      ];
}
