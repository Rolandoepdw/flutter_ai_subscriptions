import 'package:equatable/equatable.dart';
import 'ai_tier.dart';

class AIModel extends Equatable {
  final String id;
  final String name;
  final AITier tier;

  const AIModel({
    required this.id,
    required this.name,
    required this.tier,
  });

  @override
  List<Object?> get props => [id, name, tier];
}
