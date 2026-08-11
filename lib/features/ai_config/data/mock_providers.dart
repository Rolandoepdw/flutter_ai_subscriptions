import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import '../models/ai_tier.dart';

class MockProviders {
  static const List<AIProvider> providers = [
    AIProvider(
      id: 'google',
      name: 'Google AI (Gemini)',
      iconPath: 'assets/icons/google.png',
      models: [
        AIModel(id: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash', tier: AITier.free),
        AIModel(id: 'gemini-1.5-pro', name: 'Gemini 1.5 Pro', tier: AITier.paid),
      ],
    ),
    AIProvider(
      id: 'groq',
      name: 'Groq',
      iconPath: 'assets/icons/groq.png',
      models: [
        AIModel(id: 'llama-3.1-70b-versatile', name: 'Llama 3.1 70B', tier: AITier.free),
        AIModel(id: 'mixtral-8x7b-32768', name: 'Mixtral 8x7B', tier: AITier.free),
      ],
    ),
    AIProvider(
      id: 'mistral',
      name: 'Mistral AI',
      iconPath: 'assets/icons/mistral.png',
      models: [
        AIModel(id: 'mistral-tiny', name: 'Mistral Tiny', tier: AITier.free),
        AIModel(id: 'mistral-large-latest', name: 'Mistral Large', tier: AITier.paid),
      ],
    ),
    AIProvider(
      id: 'openai',
      name: 'OpenAI',
      iconPath: 'assets/icons/openai.png',
      models: [
        AIModel(id: 'gpt-4o-mini', name: 'GPT-4o Mini', tier: AITier.paid),
        AIModel(id: 'gpt-4o', name: 'GPT-4o', tier: AITier.paid),
      ],
    ),
  ];
}
