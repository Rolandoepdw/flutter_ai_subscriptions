import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';

class DiscoveryService {
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

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<List<AIModel>> _fetchOpenRouterModels(ProviderDefinition provider, String? apiKey) async {
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final headers = {
      ..._getCommonHeaders(),
      'HTTP-Referer': 'https://github.com/Rolandoepdw/flutter_ai_subscriptions',
      'X-OpenRouter-Title': 'Flutter AI Subscriptions',
    };

    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? rawModels = data['data'];
      
      if (rawModels == null) return [];

      final List<AIModel> models = [];
      final Set<String> seenIds = {};

      for (final m in rawModels) {
        final id = m['id'] as String;
        if (!seenIds.add(id)) continue;

        final name = m['name'] as String? ?? id;
        final contextTokens = m['context_length'] as int?;
        final pricing = m['pricing'];
        final architecture = m['architecture'] as Map<String, dynamic>?;
        final description = m['description']?.toString().toLowerCase() ?? '';
        
        bool isFree = id.contains(':free');
        double? inputPrice;
        double? outputPrice;
        
        if (pricing != null) {
          final promptVal = _parsePrice(pricing['prompt']);
          final completionVal = _parsePrice(pricing['completion']);
          if (promptVal == 0 && completionVal == 0) {
            isFree = true;
          } else {
            inputPrice = promptVal * 1000000;
            outputPrice = completionVal * 1000000;
          }
        }

        // More aggressive reasoning detection
        final bool hasVision = architecture?['modality']?.toString().contains('image') ?? false;
        final bool hasTools = architecture?['tool_use'] == true;
        final bool hasReasoning = id.contains('reasoner') || 
                                 id.contains('o1') || 
                                 id.contains('r1') || 
                                 name.toLowerCase().contains('reason') ||
                                 description.contains('reasoning') ||
                                 description.contains('thinking') ||
                                 description.contains('chain of thought');

        models.add(AIModel(
          id: id,
          name: name,
          tier: isFree ? AITier.free : AITier.paid,
          contextTokens: contextTokens,
          inputPrice: inputPrice,
          outputPrice: outputPrice,
          hasVision: hasVision,
          hasTools: hasTools,
          hasReasoning: hasReasoning,
        ));
      }
      return models;
    } else {
      throw Exception('OpenRouter error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<AIModel>> _fetchGoogleModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}?key=$apiKey';
    final response = await http.get(Uri.parse(url), headers: _getCommonHeaders());
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['models'];
      
      if (models == null) return [];

      return models.where((m) => (m['supportedGenerationMethods'] as List?)?.contains('generateContent') ?? false).map((m) {
        final id = (m['name'] as String).replaceFirst('models/', '');
        final name = m['displayName'] as String? ?? id;
        final contextTokens = m['inputTokenLimit'] as int?;
        final supportedMethods = m['supportedGenerationMethods'] as List?;
        final description = m['description']?.toString().toLowerCase() ?? '';
        
        return AIModel(
          id: id,
          name: name,
          tier: AITier.free, 
          contextTokens: contextTokens,
          inputPrice: 0,
          outputPrice: 0,
          hasVision: id.contains('flash') || id.contains('pro') || description.contains('multimodal'),
          hasTools: supportedMethods?.contains('generateContent') ?? false,
          hasReasoning: id.contains('thinking') || id.contains('reasoning') || description.contains('thinking'),
        );
      }).toList();
    } else {
      throw Exception('Google error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<AIModel>> _fetchAnthropicModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ..._getCommonHeaders(),
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      if (models == null) return [];
      return models.map((m) {
        final id = m['id'] as String;
        return AIModel(
          id: id,
          name: m['display_name'] ?? id,
          tier: AITier.paid,
          hasVision: id.contains('claude-3'), 
          hasTools: true,
        );
      }).toList();
    }
    throw Exception('Anthropic error (${response.statusCode})');
  }

  Future<List<AIModel>> _fetchOpenAICompatibleModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final response = await http.get(
      Uri.parse(url),
      headers: {..._getCommonHeaders(), 'Authorization': 'Bearer $apiKey'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      if (models == null) return [];
      return models.map((m) {
        final id = m['id'] as String;
        return AIModel(
          id: id, 
          name: id, 
          tier: AITier.paid,
          hasReasoning: id.contains('reasoner') || id.contains('r1'),
        );
      }).toList();
    }
    throw Exception('${provider.name} error (${response.statusCode})');
  }
}
