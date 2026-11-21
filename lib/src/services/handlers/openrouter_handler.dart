import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/provider_definitions.dart';
import '../../models/ai_model.dart';
import '../../models/ai_tier.dart';
import 'base_provider_handler.dart';

class OpenRouterHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final headers = {
      ...getCommonHeaders(),
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
        final supportedParams = m['supported_parameters'] as List?;
        final reasoningObj = m['reasoning'];
        final description = m['description']?.toString().toLowerCase() ?? '';
        
        bool isFree = id.contains(':free');
        double? inputPrice;
        double? outputPrice;
        
        if (pricing != null) {
          final promptVal = parsePrice(pricing['prompt']);
          final completionVal = parsePrice(pricing['completion']);
          if (promptVal == 0 && completionVal == 0) {
            isFree = true;
          } else {
            inputPrice = promptVal * 1000000;
            outputPrice = completionVal * 1000000;
          }
        }

        final List? inputModalities = architecture?['input_modalities'];
        final bool hasVision = (inputModalities?.contains('image') ?? false) || 
                               (architecture?['modality']?.toString().contains('image') ?? false) ||
                               description.contains('vision') || 
                               description.contains('multimodal');
        
        final bool hasTools = (supportedParams?.contains('tools') ?? false) || 
                              (architecture?['tool_use'] == true);
        
        final bool hasReasoning = (reasoningObj != null) || 
                                 (supportedParams?.contains('reasoning') ?? false) ||
                                 id.contains('reasoner') || 
                                 id.contains('o1') || 
                                 id.contains('r1') ||
                                 name.toLowerCase().contains('reason') ||
                                 description.contains('reasoning') ||
                                 description.contains('thinking');

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
}
