import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/provider_definitions.dart';
import '../../models/ai_model.dart';
import '../../models/ai_tier.dart';
import 'base_provider_handler.dart';

class CustomHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    
    final headers = getCommonHeaders();
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? rawModels = data['data'] ?? data['models'];
      
      if (rawModels == null) return [];

      return rawModels.map((m) {
        final id = m['id'] as String;
        return AIModel(
          id: id,
          name: id,
          tier: AITier.free, // Local/Custom models are usually considered free
          hasTools: true,
          hasVision: id.toLowerCase().contains('vision') || id.toLowerCase().contains('vl'),
        );
      }).toList();
    } else {
      throw Exception('Custom provider error (${response.statusCode}): ${response.body}');
    }
  }
}
