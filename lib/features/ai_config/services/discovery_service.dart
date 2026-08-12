import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../data/provider_definitions.dart';
import '../models/ai_model.dart';
import '../models/ai_tier.dart';

class DiscoveryService {
  // Common headers to avoid 403 Forbidden / Security Policy blocks
  // Using a very standard browser User-Agent
  Map<String, String> _getCommonHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json',
    };
  }

  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    developer.log('Fetching models for provider: ${provider.name} (ID: ${provider.id})', name: 'DiscoveryService');
    
    try {
      switch (provider.id) {
        case 'openrouter':
          return await _fetchOpenRouterModels(provider, apiKey);
        case 'google':
          return await _fetchGoogleModels(provider, apiKey);
        case 'anthropic':
          return await _fetchAnthropicModels(provider, apiKey);
        case 'deepseek':
        case 'xai':
          return await _fetchOpenAICompatibleModels(provider, apiKey);
        default:
          developer.log('Provider ${provider.id} not implemented for discovery', name: 'DiscoveryService');
          return [];
      }
    } catch (e, stack) {
      developer.log('Unexpected error in fetchModels for ${provider.id}: $e', name: 'DiscoveryService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<AIModel>> _fetchOpenRouterModels(ProviderDefinition provider, String? apiKey) async {
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    developer.log('OpenRouter Request: GET $url', name: 'DiscoveryService');
    
    final headers = {
      ..._getCommonHeaders(),
      'HTTP-Referer': 'https://github.com/Rolandoepdw/flutter_ai_subscriptions',
      'X-OpenRouter-Title': 'Flutter AI Subscriptions',
    };

    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
      developer.log('OpenRouter: Using provided API Key for discovery.', name: 'DiscoveryService');
    } else {
      developer.log('OpenRouter: No API Key provided, performing public discovery.', name: 'DiscoveryService');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    
    developer.log('OpenRouter Response Status: ${response.statusCode}', name: 'DiscoveryService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      
      if (models == null) {
        developer.log('OpenRouter response error: "data" field is null. Body: ${response.body}', name: 'DiscoveryService');
        return [];
      }

      developer.log('OpenRouter found ${models.length} raw items', name: 'DiscoveryService');

      return models.map((m) {
        final id = m['id'] as String;
        final name = m['name'] as String? ?? id;
        final contextTokens = m['context_length'] as int?;
        
        final pricing = m['pricing'];
        bool isFree = id.contains(':free');
        
        if (pricing != null) {
          final promptPrice = pricing['prompt']?.toString() ?? '0';
          final completionPrice = pricing['completion']?.toString() ?? '0';
          if (promptPrice == '0' && completionPrice == '0') {
            isFree = true;
          }
        }

        return AIModel(
          id: id,
          name: name,
          tier: isFree ? AITier.free : AITier.paid,
          contextTokens: contextTokens,
        );
      }).toList();
    } else {
      developer.log('OpenRouter failed. Body: ${response.body}', name: 'DiscoveryService');
      throw Exception('OpenRouter error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<AIModel>> _fetchGoogleModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) {
      developer.log('Google discovery requested but API key is null', name: 'DiscoveryService');
      return [];
    }
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}?key=$apiKey';
    developer.log('Google Request: GET ${provider.baseUrl}${provider.discoveryEndpoint} (Key hidden)', name: 'DiscoveryService');
    
    final response = await http.get(
      Uri.parse(url),
      headers: _getCommonHeaders(),
    );
    
    developer.log('Google Response Status: ${response.statusCode}', name: 'DiscoveryService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['models'];
      
      if (models == null) {
        developer.log('Google response error: "models" field is null. Body: ${response.body}', name: 'DiscoveryService');
        return [];
      }

      return models.where((m) => (m['supportedGenerationMethods'] as List?)?.contains('generateContent') ?? false).map((m) {
        final id = (m['name'] as String).replaceFirst('models/', '');
        final name = m['displayName'] as String? ?? id;
        final contextTokens = m['inputTokenLimit'] as int?;
        // In AI Studio context, flash is usually free
        bool isFree = id.contains('flash');
        return AIModel(
          id: id,
          name: name,
          tier: isFree ? AITier.free : AITier.paid,
          contextTokens: contextTokens,
        );
      }).toList();
    } else {
      developer.log('Google failed. Body: ${response.body}', name: 'DiscoveryService');
      throw Exception('Google error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<AIModel>> _fetchAnthropicModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    developer.log('Anthropic Request: GET $url', name: 'DiscoveryService');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ..._getCommonHeaders(),
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
    );
    
    developer.log('Anthropic Response Status: ${response.statusCode}', name: 'DiscoveryService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      
      if (models == null) return [];

      return models.map((m) {
        return AIModel(
          id: m['id'],
          name: m['display_name'] ?? m['id'],
          tier: AITier.paid,
        );
      }).toList();
    } else {
      developer.log('Anthropic failed. Body: ${response.body}', name: 'DiscoveryService');
      throw Exception('Anthropic error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<AIModel>> _fetchOpenAICompatibleModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    developer.log('${provider.name} Request: GET $url', name: 'DiscoveryService');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ..._getCommonHeaders(),
        'Authorization': 'Bearer $apiKey',
      },
    );
    
    developer.log('${provider.name} Response Status: ${response.statusCode}', name: 'DiscoveryService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      
      if (models == null) return [];

      return models.map((m) {
        return AIModel(
          id: m['id'],
          name: m['id'],
          tier: AITier.paid,
        );
      }).toList();
    } else {
      developer.log('${provider.name} failed. Body: ${response.body}', name: 'DiscoveryService');
      throw Exception('${provider.name} error (${response.statusCode}): ${response.body}');
    }
  }
}
