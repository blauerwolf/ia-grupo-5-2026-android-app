## MODIFIED Requirements

### Requirement: Simplificación de panel de control
El panel de control de la pantalla principal de la aplicación SHALL presentar únicamente la tarjeta de resultados y el botón principal "CAPTURAR Y ANALIZAR" para realizar inferencia dactilológica manual, eliminando los botones adicionales de prueba con assets.

#### Scenario: Visualizar panel de control limpio
- **WHEN** la aplicación renderiza el panel de control en pantalla
- **THEN** el panel de control SHALL mostrar únicamente la tarjeta de resultados y el botón "CAPTURAR Y ANALIZAR"
- **AND** el sistema SHALL omitir los botones `TEST A` y `TEST U` de prueba simulada
