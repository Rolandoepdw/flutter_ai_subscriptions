import 'package:equatable/equatable.dart';
import '../data/provider_definitions.dart';

class CustomProvider extends Equatable {
  final String id;
  final String name;
  final String baseUrl;
  final String discoveryEndpoint;

  const CustomProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.discoveryEndpoint = '/v1/models',
  });

  ProviderDefinition toDefinition() {
    return ProviderDefinition(
      id: id,
      name: name,
      baseUrl: baseUrl,
      discoveryEndpoint: discoveryEndpoint,
      iconPath: 'assets/icons/custom.png',
      requiresKeyForDiscovery: false, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'discoveryEndpoint': discoveryEndpoint,
    };
  }

  factory CustomProvider.fromJson(Map<String, dynamic> json) {
    return CustomProvider(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      discoveryEndpoint: json['discoveryEndpoint'] ?? '/v1/models',
    );
  }

  @override
  List<Object?> get props => [id, name, baseUrl, discoveryEndpoint];
}
