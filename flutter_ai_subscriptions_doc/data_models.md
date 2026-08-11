# Data Models: AI Key and Model Management Module

## Enumerations

### AITier
Defines the cost category of a model.
- `free`: No cost for the user (within free tier limits).
- `paid`: Requires a paid subscription or pay-as-you-go credit.

```dart
enum AITier { free, paid }
```

## Classes

### AIModel
Represents a specific AI model provided by a service.
- `id` (String): Unique identifier (e.g., `gemini-1.5-flash`).
- `name` (String): Display name.
- `tier` (AITier): Cost tier.

### AIProvider
Represents an AI service provider.
- `id` (String): Unique identifier (e.g., `google`, `groq`).
- `name` (String): Display name.
- `iconPath` (String): Local asset path for the logo.
- `models` (List<AIModel>): Models supported by this provider.

### APIKey
An individual key within a pool.
- `value` (String): The actual API key (sensitive).
- `isExhausted` (bool): Whether the key has reached its quota.
- `createdAt` (DateTime): For tracking age.
- `lastUsedAt` (DateTime?): For LRU or simple rotation logic.

### APIKeyPool
A collection of keys for a specific provider.
- `providerId` (String): Reference to the provider.
- `keys` (List<APIKey>): The list of keys.
- `activeIndex` (int): Index of the key currently being used.

### AIActiveCredentials
The object returned to the consumer layer.
- `providerId` (String)
- `modelId` (String)
- `apiKey` (String)

## State Objects

### AIConfigState
The state emitted by `AIConfigCubit`.
- `providers` (List<AIProvider>): Master list of supported services.
- `selectedProviderId` (String?)
- `selectedModelId` (String?)
- `keyPools` (Map<String, APIKeyPool>): Map of provider IDs to their respective pools.
- `status` (AIConfigStatus): Enum (`initial`, `loading`, `ready`, `error`).
