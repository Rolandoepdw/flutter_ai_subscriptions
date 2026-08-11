import 'package:equatable/equatable.dart';
import 'ai_model.dart';

class AIProvider extends Equatable {
  final String id;
  final String name;
  final String iconPath;
  final List<AIModel> models;

  const AIProvider({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.models,
  });

  bool get hasFreeModels => models.any((model) => model.tier.name == 'free');

  @override
  List<Object?> get props => [id, name, iconPath, models];
}
