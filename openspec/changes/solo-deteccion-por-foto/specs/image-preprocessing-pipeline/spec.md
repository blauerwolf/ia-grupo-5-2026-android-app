## MODIFIED Requirements

### Requirement: Pipeline de preprocesamiento consistente con entrenamiento
El sistema SHALL implementar un pipeline de preprocesamiento en `predict()` que replique las condiciones del dataset de entrenamiento (Sign Language MNIST / ASL Alphabet) a partir de los bytes completos de una foto capturada por la cámara (JPEG): decodificación de imagen → crop central cuadrado → escala de grises → resize 28×28 → normalización [0,1]. El procesamiento en tiempo real de frames crudos de streaming (YUV420/BGRA) SHALL ser eliminado.

#### Scenario: Foto capturada procesada correctamente
- **WHEN** el usuario toma una foto y se obtienen los bytes del archivo JPEG
- **THEN** el sistema SHALL decodificar la imagen → crop cuadrado central → grayscale → normalize(min=0, max=255) → resize(28,28, cubic) → tensor [1,28,28,1] con valores en [0.0, 1.0]
