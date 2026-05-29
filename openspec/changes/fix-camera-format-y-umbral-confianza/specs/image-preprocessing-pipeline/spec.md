## ADDED Requirements

### Requirement: Pipeline de preprocesamiento consistente con entrenamiento
El sistema SHALL implementar un pipeline de preprocesamiento en `predict()` que replique las condiciones del dataset de entrenamiento (Sign Language MNIST / ASL Alphabet): crop central cuadrado → escala de grises → estiramiento de histograma → resize 28×28 → normalización [0,1]. La binarización (Otsu) SHALL ser omitida ya que el script de referencia `deteccion.py` no la aplica.

#### Scenario: Frame de cámara real procesado correctamente
- **WHEN** `predict()` recibe bytes JPEG de la cámara
- **THEN** el sistema SHALL aplicar crop cuadrado central → grayscale → normalize(min=0, max=255) → resize(28,28, cubic) → tensor [1,28,28,1] con valores en [0.0, 1.0]

#### Scenario: Orden de pasos preservado
- **WHEN** se ejecuta el pipeline de preprocesamiento
- **THEN** el estiramiento de histograma SHALL aplicarse DESPUÉS del crop y ANTES del resize, para evitar que la interpolación cúbica introduzca artefactos post-normalización
