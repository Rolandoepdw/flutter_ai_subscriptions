import 'package:equatable/equatable.dart';

class AIActiveCredentials extends Equatable {
  final String providerId;
  final String modelId;
  final String apiKey;

  const AIActiveCredentials({
    required this.providerId,
    required this.modelId,
    required this.apiKey,
  });

  @override
  List<Object?> get props => [providerId, modelId, apiKey];
}
