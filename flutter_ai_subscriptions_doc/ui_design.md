# UI Design: AI Key and Model Management Module

## Visual Principles
- **Clarity on Tiers**: Distinguish clearly between "Free" and "Paid" models using color-coded badges.
- **Status Visibility**: The user should always know which provider and model are active.
- **Key Health**: Visual indicators for keys in the pool (Active, Exhausted, Validating).

## Screens

### 1. Provider Selection Screen (Main List)
- **Top Bar**: "AI Configuration".
- **List View**:
    - List of available providers (Gemini, Groq, OpenAI, etc.).
    - Each item shows the provider logo, name, and a summary of keys (e.g., "3 keys available").
    - **Free Badge**: If a provider has free models, show a green "Free models available" label.
    - **Active Indicator**: A checkmark or highlight on the currently selected provider.

### 2. Provider Detail Screen
- **Header**: Provider name and logo.
- **Model Selection Section**:
    - Dropdown or horizontal list of models.
    - Labels for `free` vs `paid`.
- **Key Pool Management Section**:
    - "Add New Key" button (opens a text field/dialog).
    - List of current keys:
        - Obfuscated key (e.g., `sk-••••42`).
        - Status icon (Green dot = Active/Ready, Red X = Exhausted).
        - Delete button.
- **Exhaustion Warning**: If all keys are exhausted, a prominent banner appears: "All keys exhausted. Please add more to continue using this provider."

## Global Components

### AI Status Widget (Mini)
A small, floating or anchored widget that can be placed in a sidebar or settings menu:
- Icon of the active provider.
- Text: "[Provider Name] - [Model Name]".
- Simple tap-to-change functionality.

## Interactions
- **Tapping a Provider**: Navigates to the Detail Screen.
- **Adding a Key**: Validates basic format (length, prefix) and adds it to the list immediately.
- **Exhaustion Feedback**: When `reportKeyExhausted` is triggered, the UI shows a Snackbar: "API Key exhausted. Switching to next available key."
