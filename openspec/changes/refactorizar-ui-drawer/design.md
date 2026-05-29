## Context

La aplicación es una app Flutter de detección de lenguaje de señas que utiliza TFLite para inferencia offline. El archivo principal `lib/main.dart` contiene toda la lógica de UI. Actualmente el encabezado muestra texto en inglés (`SIGN LANGUAGE AI`), el drawer solo tiene el switch de detección automática, y el panel de control incluye botones de debug (`ASSET A`, `ASSET U`) que fueron utilizados durante el desarrollo pero no son apropiados para la entrega final académica del Grupo 5.

## Goals / Non-Goals

**Goals:**
- Actualizar el texto del encabezado principal a español: `'Detección de Lenguaje de Señas'`.
- Agregar en el drawer una entrada informativa que identifique al equipo como `Grupo 5`.
- Conservar el switch de detección automática en el drawer con su diseño actual.
- Eliminar los botones `ASSET A` y `ASSET U` del panel de control.

**Non-Goals:**
- No se modifican temas, paletas de colores ni layouts.
- No se refactoriza la lógica de inferencia, cámara ni TFLite.
- No se agregan nuevas rutas, pantallas ni navegación.
- No se cambia el diseño glassmorphic existente.

## Decisions

### D1: Posición del tile "Grupo 5" en el drawer
**Decisión**: Se ubica inmediatamente después del encabezado del drawer, antes de la sección `MODO DE DETECCIÓN`.  
**Razón**: Es información de contexto / autoría, no un control. Ubicarla primero es coherente con el patrón de "quién somos" antes de "qué configuramos".  
**Alternativa considerada**: Colocarla en el footer, pero el footer es de muy bajo contraste y podría pasar desapercibida.

### D2: Estilo del tile "Grupo 5"
**Decisión**: Usar un `ListTile` estático (no interactivo) con ícono de grupo y texto `Grupo 5` + subtítulo `UTN FRLP · IA 2026`, dentro de un `Container` con el mismo estilo glassmorphic del drawer.  
**Razón**: Mantiene consistencia visual con el tile del switch existente. No necesita ser interactivo.

### D3: Eliminar `_testWithAsset()`
**Decisión**: Eliminar el método `_testWithAsset()` junto con los botones, ya que sin los botones el método queda huérfano.  
**Razón**: Limpieza de código muerto. Si se necesitara en el futuro, puede recuperarse del historial de git.

## Risks / Trade-offs

- **[Riesgo] Eliminar `_testWithAsset()` rompe tests existentes** → Mitigación: El proyecto no tiene tests unitarios que invoquen ese método directamente.
- **[Trade-off] El drawer footer `UTN FRLP · IA 2026` queda redundante con el tile "Grupo 5"** → Se puede mantener ambos por ahora o eliminar el footer; la propuesta lo mantiene para contexto adicional.
