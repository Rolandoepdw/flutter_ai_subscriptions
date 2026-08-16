import 'package:equatable/equatable.dart';
import 'ai_tier.dart';

class AIModel extends Equatable {
  final String id;
  final String name;
  final AITier tier;
  final int? contextTokens;
  final double? inputPrice; // Per 1M tokens
  final double? outputPrice; // Per 1M tokens
  
  // Capabilities
  final bool hasVision;
  final bool hasTools;
  final bool hasReasoning;

  const AIModel({
    required this.id,
    required this.name,
    required this.tier,
    this.contextTokens,
    this.inputPrice,
    this.outputPrice,
    this.hasVision = false,
    this.hasTools = false,
    this.hasReasoning = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier.name,
      'contextTokens': contextTokens,
      'inputPrice': inputPrice,
      'outputPrice': outputPrice,
      'hasVision': hasVision,
      'hasTools': hasTools,
      'hasReasoning': hasReasoning,
    };
  }

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'],
      name: json['name'],
      tier: AITier.values.byName(json['tier']),
      contextTokens: json['contextTokens'],
      inputPrice: (json['inputPrice'] as num?)?.toDouble(),
      outputPrice: (json['outputPrice'] as num?)?.toDouble(),
      hasVision: json['hasVision'] ?? false,
      hasTools: json['hasTools'] ?? false,
      hasReasoning: json['hasReasoning'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id, name, tier, contextTokens, inputPrice, outputPrice, 
    hasVision, hasTools, hasReasoning
  ];
}
