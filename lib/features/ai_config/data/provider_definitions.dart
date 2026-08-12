class ProviderDefinition {
  final String id;
  final String name;
  final String baseUrl;
  final String discoveryEndpoint;
  final String iconPath;
  final bool requiresKeyForDiscovery;

  const ProviderDefinition({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.discoveryEndpoint,
    required this.iconPath,
    this.requiresKeyForDiscovery = true,
  });
}

class ProviderDefinitions {
  static const List<ProviderDefinition> definitions = [
    ProviderDefinition(
      id: 'google',
      name: 'Google AI Studio',
      baseUrl: 'https://generativelanguage.googleapis.com',
      discoveryEndpoint: '/v1beta/models',
      iconPath: 'assets/icons/google.png',
      requiresKeyForDiscovery: true,
    ),
    ProviderDefinition(
      id: 'openrouter',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai',
      discoveryEndpoint: '/api/v1/models',
      iconPath: 'assets/icons/openrouter.png',
      requiresKeyForDiscovery: false,
    ),
    ProviderDefinition(
      id: 'anthropic',
      name: 'Anthropic',
      baseUrl: 'https://api.anthropic.com',
      discoveryEndpoint: '/v1/models',
      iconPath: 'assets/icons/anthropic.png',
      requiresKeyForDiscovery: true,
    ),
    ProviderDefinition(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      discoveryEndpoint: '/models',
      iconPath: 'assets/icons/deepseek.png',
      requiresKeyForDiscovery: true,
    ),
    ProviderDefinition(
      id: 'xai',
      name: 'X.ai (Elon Musk)',
      baseUrl: 'https://api.x.ai',
      discoveryEndpoint: '/v1/models',
      iconPath: 'assets/icons/xai.png',
      requiresKeyForDiscovery: true,
    ),
    ProviderDefinition(
      id: 'microsoft',
      name: 'Microsoft (Azure OpenAI)',
      baseUrl: '', // Varies by deployment
      discoveryEndpoint: '', 
      iconPath: 'assets/icons/microsoft.png',
      requiresKeyForDiscovery: true,
    ),
  ];
}
