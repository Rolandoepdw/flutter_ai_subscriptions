# API Specification: AI Key and Model Management Module

## AIConfigManager (Singleton Service)

This service is accessed via `GetIt.I<AIConfigManager>()`.

### Methods

#### `Future<void> init()`
Loads the configuration and keys from secure storage. Should be called at app startup.

#### `AIActiveCredentials? getActiveCredentials()`
Returns the `apiKey`, `providerId`, and `modelId` for the current selection. Returns `null` if no key is available for the selected provider.

#### `Future<void> reportKeyExhausted()`
Marks the current key as exhausted and rotates to the next available one in the pool. Updates the `AIConfigCubit` state.

#### `Future<void> addKey(String providerId, String key)`
Adds a new key to the pool of the specified provider. Persists the change.

#### `Future<void> removeKey(String providerId, String key)`
Removes a specific key from the pool.

#### `Future<void> selectProvider(String providerId)`
Sets the active provider.

#### `Future<void> selectModel(String modelId)`
Sets the active model for the current provider.

---

## AIConfigCubit (State Management)

### States

- `AIConfigInitial`: Initial state before loading.
- `AIConfigLoading`: State while reading from secure storage.
- `AIConfigReady`: Configuration loaded, UI ready to interact. Contains current `AIConfigState`.
- `AIConfigError`: Something went wrong during initialization or persistence.

### Notifications/Side Effects
- **NoKeysAvailableEvent**: Broadcasted when `reportKeyExhausted` is called but the pool is empty. The UI should react by showing a "Top up keys" prompt.

---

## Integration Example (Consumer Layer)

```dart
void sendMessage(String text) async {
  final credentials = GetIt.I<AIConfigManager>().getActiveCredentials();
  
  if (credentials == null) {
    // Show UI to add keys
    return;
  }

  try {
    final response = await aiClient.call(
      model: credentials.modelId,
      apiKey: credentials.apiKey,
      prompt: text,
    );
  } catch (e) {
    if (e.isQuotaExceeded) {
      GetIt.I<AIConfigManager>().reportKeyExhausted();
      // Retry or notify user
    }
  }
}
```
