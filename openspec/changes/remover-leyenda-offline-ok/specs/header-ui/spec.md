## MODIFIED Requirements

### Requirement: Simplificación de cabecera principal
La cabecera principal de la aplicación SHALL presentar únicamente el botón de menú lateral, el botón toggle de cámara, el título y subtítulo de la aplicación, omitiendo cualquier indicador de estado offline / online del motor de inferencia.

#### Scenario: Visualizar cabecera limpia
- **WHEN** la aplicación se inicia y renderiza la pantalla principal
- **THEN** la cabecera principal SHALL renderizar el botón de menú lateral, el botón toggle de cámara, el título `'Detección de Lenguaje de Señas'`, el subtítulo `'Motor TFLite Nativo (100% Offline)'` y SHALL omitir el contenedor indicador luminoso del estado del motor
