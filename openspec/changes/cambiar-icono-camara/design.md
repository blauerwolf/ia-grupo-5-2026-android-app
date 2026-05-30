## Context

El botón de alternancia de cámara en la cabecera principal (`_buildHeader()` en `lib/main.dart`) muestra de forma dinámica un ícono u otro dependiendo de la lente activa actual (`Icons.camera_front_rounded` para la cámara frontal, e `Icons.camera_rear_rounded` para la cámara trasera). Para lograr una interfaz de usuario más consistente y moderna, se solicita reemplazar estos íconos dinámicos por un ícono estático de flechas en ciclo (`Icons.switch_camera_rounded`) que representa universalmente la acción de alternancia de cámara.

## Goals / Non-Goals

**Goals:**
- Reemplazar la lógica de selección de ícono dinámico en `_buildHeader()` por un ícono estático constante `Icons.switch_camera_rounded`.
- Simplificar el código del widget `Icon` del botón.
- Asegurar que no se altere la funcionalidad de alternancia de cámara subyacente.

**Non-Goals:**
- No se modificará la lógica de negocio ni el método `_toggleCamera`.
- No se realizarán otros cambios estéticos o estructurales en la cabecera principal.
- No se agregará soporte para más de dos tipos de cámara (por ejemplo, teleobjetivo o gran angular) más allá de lo existente.

## Decisions

### 1. Uso de `Icons.switch_camera_rounded` como ícono de alternancia
- **Opción seleccionada**: Usar `Icons.switch_camera_rounded` de forma estática con la palabra clave `const`.
- **Razón**: Es el ícono estándar en Flutter que representa dos flechas en ciclo, encajando perfectamente con la estética premium y minimalista de la app. Al ser estático, se puede definir como `const Icon(Icons.switch_camera_rounded, ...)`, optimizando levemente el renderizado al evitar reconstrucciones innecesarias del ícono.
- **Alternativas consideradas**:
  - `Icons.switch_camera`: Ícono estándar sin bordes redondeados. Se descarta porque la app utiliza estilos redondeados en sus botones y menús.
  - Mantener los íconos dinámicos: Se descarta para simplificar la UI según la especificación del usuario.

## Risks / Trade-offs

- **[Riesgo]** Reducción de la indicación visual de la cámara activa en el ícono del botón.
  - *Mitigación*: La pantalla de la cámara en sí muestra claramente si se está usando la cámara frontal o la trasera, por lo que el estado activo es autoevidente para el usuario.
