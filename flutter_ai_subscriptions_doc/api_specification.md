# API Specification: Flutter AI Subscriptions

## AIConfigManager

The main engine of the package.

### Methods

#### `Future<void> init()`
Loads the configuration and keys from secure storage.

#### `AIActiveCredentials? getActiveCredentials()`
Returns the active `apiKey`, `providerId`, and `modelId`. Automatically triggers cool-down checks for exhausted keys.

#### `Future<void> reportKeyExhausted()`
Marks the current key as exhausted and rotates to the next one.

#### `Future<void> addKey(String providerId, String key)`
Validates the key with the provider before adding it to the pool.

#### `Future<void> selectModel(String providerId, String modelId)`
Selects the model and sets the provider as the globally active one.

---

## AIRequestFactory

Generates request configurations.

### `static AIRequestDetails generateChatRequest(...)`
Returns an `AIRequestDetails` object containing:
- `url`: Formatted endpoint (with keys if required by Google).
- `headers`: Map including `Authorization` or custom headers.
- `body`: JSON body formatted according to provider requirements.

---

## AIConfigNotifier

Utility class for UI binding.

### Properties
- `status`: Current state (`initial`, `loading`, `ready`, etc.).
- `providers`: List of built-in and custom providers.
- `selectedProviderId`: Currently active provider.

---

## Integration Example

```dart
final manager = AIConfigManager(storage: myStorage, discovery: myDiscovery);
await manager.init();

final credentials = manager.getActiveCredentials();

if (credentials != null) {
  final details = AIRequestFactory.generateChatRequest(
    credentials: credentials,
    allProviders: manager.getAllProviders(),
    messages: [{'role': 'user', 'content': 'Hello!'}],
  );
  
  final response = await http.post(
    Uri.parse(details.url),
    headers: details.headers,
    body: jsonEncode(details.body),
  );
}
```
