import 'package:equatable/equatable.dart';
import 'ai_tier.dart';

class AIModel extends Equatable {
  final String id;
  final String name;
  final AITier tier;
  final int? contextTokens;
  final double? inputPrice; // Per 1M tokens
  final double? outputPrice; // Per 1M tokens

  const AIModel({
    required this.id,
    required this.name,
    required this.tier,
    this.contextTokens,
    this.inputPrice,
    this.outputPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier.name,
      'contextTokens': contextTokens,
      'inputPrice': inputPrice,
      'outputPrice': outputPrice,
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
    );
  }

  @override
  List<Object?> get props => [id, name, tier, contextTokens, inputPrice, outputPrice];
}
