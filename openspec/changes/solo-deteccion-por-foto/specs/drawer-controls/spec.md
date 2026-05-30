## ADDED Requirements

### Requirement: Detección manual única mediante captura de foto
El sistema SHALL permitir la captura manual de una foto utilizando la cámara del dispositivo y su posterior procesamiento inmediato de manera local con el modelo TFLite.

#### Scenario: Captura y análisis exitoso de una foto
- **WHEN** el usuario presiona el botón "CAPTURAR Y ANALIZAR"
- **THEN** la app SHALL invocar `takePicture()` en el `CameraController`, leer los bytes de la foto, mostrar un indicador visual de procesamiento, realizar la inferencia y actualizar la UI con la letra estimada y nivel de confianza

## REMOVED Requirements

### Requirement: Drawer contiene switch de detección automática
**Reason**: Se prescinde por completo de la detección en tiempo real para optimizar rendimiento y consumo de batería.
**Migration**: Eliminar el switch y el texto descriptivo del Drawer lateral, dejando solo la información del grupo y las opciones de calibración del crop y contraste aplicables a la captura manual.
