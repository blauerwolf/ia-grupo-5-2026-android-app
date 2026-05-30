## Why

La detección en tiempo real a través del flujo de imágenes continuo consume recursos de CPU/GPU y batería significativos, además de generar complejidad al procesar formatos de imagen crudos (YUV420 y BGRA) que varían según la plataforma y dispositivo. Al migrar a una detección bajo demanda basada exclusivamente en la captura de fotos (`takePicture()`), se simplifica el pipeline de preprocesamiento, se reduce drásticamente el consumo de batería y se provee una interacción de usuario más determinista y alineada con la ejecución de referencia del script `deteccion.py`.

## What Changes

- **REMOVIDO**: Flujo de detección en tiempo real y componentes asociados (switch `_isAutoDetect`, callback `_onCameraFrame`, animación láser HUD de escaneo en la vista previa y opción de detección automática en el Drawer lateral).
- **MODIFICADO**: Comportamiento de captura manual. El botón "CAPTURAR Y ANALIZAR" ahora disparará una foto real usando `CameraController.takePicture()`, leerá los bytes del archivo JPEG resultante y los procesará a través de la inferencia local del clasificador TFLite.
- **MODIFICADO**: UI Drawer y HUD. Se eliminan los controles de detección automática y calibración innecesarios para el modo de flujo continuo, optimizando la interfaz para centrarse en capturas instantáneas de alta calidad.

## Capabilities

### New Capabilities
*(Ninguna. Se optimiza el comportamiento sobre las capacidades existentes).*

### Modified Capabilities
- `image-preprocessing-pipeline`: Se actualiza para ingerir archivos JPEG de imagen completa capturados por la cámara en lugar de frames YUV420/BGRA continuos en crudo.
- `detection-controls`: Se rediseña el panel de control y el Drawer lateral para remover las configuraciones de detección en tiempo real y centrar la experiencia en la captura fotográfica manual.

## Impact

- `lib/main.dart`:
  - Remoción de `_cameraController.startImageStream()` y del método de procesamiento continuo `_onCameraFrame`.
  - Actualización de `_triggerManualCapture()` (renombrado a `_captureAndAnalyze()`) para invocar `takePicture()`, leer bytes y llamar a `_tfliteClassifier.predict()`.
  - Simplificación del Drawer lateral y del panel de control eliminando los selectores del modo automático.
- `lib/tflite_native.dart` / `lib/tflite_stub.dart`:
  - Verificación de que `predict(Uint8List imageBytes)` escala y procesa correctamente las fotos capturadas a alta resolución reduciendo la latencia y manteniendo la precisión.
