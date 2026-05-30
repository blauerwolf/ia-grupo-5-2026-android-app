## Context

Actualmente, la aplicación implementa una detección dual: en tiempo real (streaming continuo de frames a ~1.5 FPS) y modo manual (procesando el próximo frame disponible en el stream). Ambos modos dependen de `_cameraController.startImageStream()` y de preprocesamientos de matrices YUV420 o BGRA. El procesamiento continuo genera un consumo excesivo de batería, sobrecalentamiento del dispositivo y una sobrecarga lógica para manejar las diferencias de formato de píxeles entre plataformas (Android e iOS).

## Goals / Non-Goals

**Goals:**
- Prescindir por completo de la detección en tiempo real y del streaming de cámara en background.
- Implementar la detección de señas basada en capturas instantáneas usando `CameraController.takePicture()`.
- Simplificar el código de preprocesamiento eliminando el flujo de conversión YUV420/BGRA por frames del stream.
- Adaptar la UI/UX: remover el switch de modo automático, eliminar la animación de escaneo láser en tiempo real, y centrar el control en un botón principal "CAPTURAR Y ANALIZAR" con un indicador de carga claro.

**Non-Goals:**
- Cambiar la arquitectura del clasificador offline nativo TFLite ni el entrenamiento del modelo (la entrada sigue siendo 28x28 escala de grises).
- Depender de un servidor externo de inferencia Python para el flujo principal (se conserva la inferencia 100% local nativa).

## Decisions

### 1. Ingesta a partir de `takePicture()` en lugar de `startImageStream()`
- **Razón**: `takePicture()` de la librería `camera` captura una foto completa, maneja automáticamente la rotación del sensor en la mayoría de los casos y genera un archivo JPEG/PNG estándar en disco. Esto elimina la necesidad de mantener un loop de stream consumiendo ciclos de CPU y evita la compleja conversión manual de matrices de color YUV/BGRA.
- **Alternativas consideradas**: Mantener el stream activo pero sin procesar hasta que se presione el botón. *Rechazada* porque mantener la cámara streameando frames a nivel de software sigue consumiendo mucha CPU y energía.

### 2. Procesamiento de JPEG mediante `tfliteClassifier.predict()`
- **Razón**: El método `predict(Uint8List imageBytes)` en `tflite_native.dart` ya está implementado para recibir bytes de una imagen codificada (JPEG/PNG), decodificarla usando el paquete `image`, aplicar crop central cuadrado, convertir a escala de grises, hacer resize a 28x28 usando interpolación cúbica, y normalizar a [0,1]. Esto reutiliza el pipeline que ya coincide exactamente con la ejecución de prueba del script `deteccion.py`.
- **Alternativas consideradas**: Implementar decodificación manual y redimensionamiento en Flutter. *Rechazada* ya que el clasificador nativo ya expone un método robusto y probado para este fin.

### 3. Experiencia de Usuario con Indicador de Procesamiento Estilo Snap
- **Razón**: Dado que `takePicture()` tiene una pequeña latencia (~200ms - 500ms dependiendo del dispositivo) comparado con la captura instantánea de un frame de buffer en stream, el usuario debe ver un feedback claro. Se usará un overlay translúcido con un spinner de carga (`CircularProgressIndicator`) sobre la vista previa de la cámara durante el período de captura e inferencia.

## Risks / Trade-offs

- **[Riesgo] Shutter Lag (Demora al capturar la foto)** → *Mitigación*: Mostrar de inmediato el estado `_isProcessing = true` y deshabilitar el botón de captura durante el proceso para evitar llamadas concurrentes indeseadas.
- **[Riesgo] Rotación de la foto capturada en algunos dispositivos antiguos** → *Mitigación*: El paquete `image` de Dart decodifica el archivo JPEG y lee la información EXIF de orientación en la mayoría de las plataformas. Si hay inconsistencias, la calibración de crop y contraste del drawer (que siguen activas) ayudan a corregir el encuadre.
