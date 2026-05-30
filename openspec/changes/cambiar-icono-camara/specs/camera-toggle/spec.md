## ADDED Requirements

### Requirement: Botón de alternar cámara con ícono estático de ciclo

El botón de alternancia de cámara en la cabecera principal SHALL mostrar siempre un único ícono de dos flechas en ciclo (`Icons.switch_camera_rounded`) de manera constante, independientemente del estado o la dirección de la lente activa (`_selectedLensDirection`).

#### Scenario: Visualización del botón de alternancia de cámara
- **WHEN** la pantalla principal de la aplicación se renderiza
- **THEN** el botón de alternar cámara en el header de la aplicación SHALL mostrar el ícono `Icons.switch_camera_rounded` con el color `Color(0xFF9B51E0)` y un tamaño de `22`
