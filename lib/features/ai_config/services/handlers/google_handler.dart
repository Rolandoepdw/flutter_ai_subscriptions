import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';
import 'base_provider_handler.dart';

class GoogleHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}?key=$apiKey';
    final response = await http.get(Uri.parse(url), headers: getCommonHeaders());
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? modelsList = data['models'];
      
      if (modelsList == null) return [];

      return modelsList.where((m) => (m['supportedGenerationMethods'] as List?)?.contains('generateContent') ?? false).map((m) {
        final id = (m['name'] as String).replaceFirst('models/', '');
        final name = m['displayName'] as String? ?? id;
        final contextTokens = m['inputTokenLimit'] as int?;
        final supportedMethods = m['supportedGenerationMethods'] as List?;
        final description = m['description']?.toString().toLowerCase() ?? '';
        final bool isThinkingModel = m['thinking'] == true;
        
        return AIModel(
          id: id,
          name: name,
          tier: AITier.free, 
          contextTokens: contextTokens,
          inputPrice: 0,
          outputPrice: 0,
          hasVision: id.contains('flash') || id.contains('pro') || description.contains('multimodal') || description.contains('image'),
          hasTools: supportedMethods?.contains('generateContent') ?? false,
          hasReasoning: isThinkingModel || id.contains('thinking') || id.contains('reasoning') || description.contains('thinking'),
        );
      }).toList();
    } else {
      throw Exception('Google error (${response.statusCode}): ${response.body}');
    }
  }
}
