import 'package:equatable/equatable.dart';
import 'ai_tier.dart';

class AIModel extends Equatable {
  final String id;
  final String name;
  final AITier tier;
  final int? contextTokens;

  const AIModel({
    required this.id,
    required this.name,
    required this.tier,
    this.contextTokens,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier.name,
      'contextTokens': contextTokens,
    };
  }

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'],
      name: json['name'],
      tier: AITier.values.byName(json['tier']),
      contextTokens: json['contextTokens'],
    );
  }

  @override
  List<Object?> get props => [id, name, tier, contextTokens];
}
