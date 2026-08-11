# Módulo de Gestión de Claves y Modelos de IA con Pool de API Keys

## Propuesta de formalización – v3

**Objetivo general**
Módulo reutilizable en Flutter que permite al usuario traer sus propias API keys de proveedores de IA, organizarlas en *pools* con cambio automático ante agotamiento, seleccionar el modelo (diferenciando gratuitos y de pago), y exponer la configuración activa para que otras capas realicen las llamadas.

**Decisiones técnicas**
- Manejo de estados: **Cubit**.
- Inyección de dependencias: **GetIt** (para servicios singleton).
- Almacenamiento seguro: **flutter_secure_storage**.
- Prioridad inicial: proveedores con modelos **gratuitos** (free tier), facilitando el uso sin coste para el usuario.

---

## Alcance concreto

### 1. Proveedores y modelos (con distinción free/paid)
- Lista configurable de proveedores (OpenAI, Google AI, Anthropic, Cohere, Mistral, Groq, etc.).
- Cada proveedor expone modelos, cada uno con un atributo `tier` (`free` o `paid`).
- La UI mostrará esta diferenciación de forma clara (badge/etiqueta).
- Primera implementación: solo proveedores con modelos gratuitos abundantes (Gemini, Groq, Mistral, etc.). Ampliable posteriormente.

### 2. Pool de API keys por proveedor y conmutación automática
- El usuario puede añadir **múltiples claves** para un mismo proveedor (pool).
- El módulo mantiene un índice de clave activa dentro del pool.
- Cuando la capa consumidora detecta un error de cuota/rate limit en la clave activa, llama a `reportKeyExhausted()`. El módulo avanza automáticamente a la siguiente clave disponible.
- Si no quedan claves disponibles, se notifica vía estado Cubit para que el usuario añada más.
- Las claves agotadas se marcan temporalmente; posibilidad de reactivación manual o automática tras un tiempo (a definir en la implementación).

### 3. Selección de modelo (asociada al proveedor activo)
- El usuario elige el proveedor activo y, de su lista, el modelo deseado (filtrando por free/paid si se desea).
- El módulo expone proveedor activo, API key activa y modelo seleccionado mediante `getActiveCredentials()`.

### 4. Arquitectura interna y dependencias
- **Cubit (`AIConfigCubit`)**: maneja todo el estado: lista de proveedores, pools de claves, clave activa, modelo seleccionado, estado de agotamiento, etc.
- **GetIt**: registra el `AIConfigManager` (lógica de negocio, almacenamiento) y opcionalmente el cubit.
- **flutter_secure_storage**: almacena todas las API keys de forma segura.
- El módulo es autocontenido (feature folder o paquete independiente), con sus propios modelos, cubit, servicios y pantallas/widgets.

### 5. UI de configuración incluida
- Pantalla principal: lista de proveedores con indicador de modelos gratuitos disponibles.
- Pantalla de detalle por proveedor:
    - Gestión del pool de claves (añadir, eliminar, ver activa/agotada).
    - Selección de modelo (con distinción visual free/paid).
- Totalmente desacoplada; lista para integrar con cualquier sistema de navegación.

### 6. Interfaz pública del módulo
- **`AIConfigManager`** (servicio registrado en GetIt):
    - `getActiveCredentials()` → `(provider, apiKey, model)`.
    - `reportKeyExhausted()` → avanza a la siguiente clave del pool activo.
- **`AIConfigCubit`**: expone el estado para la UI de configuración y notifica cambios (ej. clave agotada, sin claves disponibles).

### 7. Viabilidad multiplataforma
Probado y compatible con **Android** y **Windows**, gracias a que las dependencias principales (Cubit, GetIt, flutter_secure_storage) funcionan en ambas plataformas sin modificaciones.  
En Windows, `flutter_secure_storage` requiere una inicialización mínima (ya cubierta por el paquete). Todas las demás lógicas son Dart puro.