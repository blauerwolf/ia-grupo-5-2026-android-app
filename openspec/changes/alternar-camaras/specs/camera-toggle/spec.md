## ADDED Requirements

### Requirement: Toggle de selección de lente de cámara
La aplicación SHALL proveer un botón interactivo (toggle button) en la interfaz principal que permita al usuario cambiar dinámicamente entre la cámara frontal y la cámara trasera del dispositivo.

#### Scenario: Alternar de cámara frontal a cámara trasera
- **WHEN** la aplicación está activa con la cámara frontal e inicializada
- **AND** el usuario presiona el botón de alternancia de cámara
- **THEN** el sistema SHALL liberar el controlador de la cámara activa, cambiar la dirección a trasera, re-inicializar el controlador de cámara, y desactivar el espejado horizontal por defecto

#### Scenario: Alternar de cámara trasera a cámara frontal
- **WHEN** la aplicación está activa con la cámara trasera e inicializada
- **AND** el usuario presiona el botón de alternancia de cámara
- **THEN** el sistema SHALL liberar el controlador de la cámara activa, cambiar la dirección a frontal, re-inicializar el controlador de cámara, y activar el espejado horizontal por defecto
