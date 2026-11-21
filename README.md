# Flutter AI Subscriptions

[![Pub Version](https://img.shields.io/pub/v/flutter_ai_subscriptions)](https://pub.dev/packages/flutter_ai_subscriptions)
[![Tests](https://github.com/Rolandoepdw/flutter_ai_subscriptions/actions/workflows/tests.yml/badge.svg)](https://github.com/Rolandoepdw/flutter_ai_subscriptions/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A professional AI key management and rotation engine for Flutter. Handle multiple AI providers (OpenAI, Google, Anthropic, etc.), manage key pools, and implement automatic cool-down periods for exhausted keys with ease.

## Features

- 🔄 **Smart Rotation**: Automatically switches to the next available API key when quota is exceeded.
- ❄️ **Automatic Cool-down**: Exhausted keys are automatically reactivated after a configurable timeout (default 8 hours).
- 🛠️ **Request Factory**: Generates URLs, Headers, and Bodies for different providers (OpenAI compatible, Google AI) without forcing an HTTP client.
- 🔌 **Custom Providers**: Seamlessly integrate local models (Ollama, LM Studio) using the same logic as cloud providers.
- 🛡️ **Secure by Default**: Built-in integration with `flutter_secure_storage` to protect your sensitive API keys.
- 🔍 **Dynamic Discovery**: Automatically fetches available models for each provider upon key validation.

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_ai_subscriptions: ^1.0.0
```

## Quick Start

### 1. Initialize the Manager

```dart
import 'package:flutter_ai_subscriptions/flutter_ai_subscriptions.dart';

final manager = AIConfigManager(
  storage: SecureStorageService(),
  discovery: DiscoveryService(),
  exhaustionTimeout: Duration(hours: 8),
);

await manager.init();
```

### 2. Get Active Credentials

```dart
final credentials = manager.getActiveCredentials();

if (credentials == null) {
  print("No keys available. Please add a key in the settings.");
  return;
}
```

### 3. Generate a Request

Use the `AIRequestFactory` to get the exact configuration needed for the provider.

```dart
final request = AIRequestFactory.generateChatRequest(
  credentials: credentials,
  allProviders: manager.getAllProviders(),
  messages: [
    {'role': 'user', 'content': 'Hello, AI!'}
  ],
);

final response = await http.post(
  Uri.parse(request.url),
  headers: request.headers,
  body: jsonEncode(request.body),
);
```

### 4. Report Exhaustion

If you receive a 429 (Rate Limit) or Quota error, let the manager know to rotate the key:

```dart
if (response.statusCode == 429) {
  await manager.reportKeyExhausted();
  // Manager will now move to the next key or wait for cool-down
}
```

## Supported Providers

- ✅ **OpenAI** (and compatible like DeepSeek, xAI)
- ✅ **Google AI** (Gemini)
- ✅ **Anthropic** (via OpenRouter or direct)
- ✅ **OpenRouter** (with automatic model discovery)
- ✅ **Custom / Local** (Ollama, LM Studio, etc.)

## Example Project

Check the [example](https://github.com/Rolandoepdw/flutter_ai_subscriptions/tree/main/example) folder for a full-featured Chat UI implementation, including provider management screens and key pool sorting.

## Architecture

This package follows clean architecture principles and uses `ChangeNotifier` for state management, making it compatible with any architectural pattern (Provider, BloC, Riverpod, etc.).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
