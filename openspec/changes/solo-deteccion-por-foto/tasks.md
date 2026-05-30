## 1. Refactor de Cámara y Remoción de Real-Time Stream

- [x] 1.1 Eliminar la variable `_isAutoDetect` y las variables asociadas a la tasa de frames (throttle) `_lastFrameProcessed` y `_captureNextFrame` en `lib/main.dart`
- [x] 1.2 Modificar `_initializeCamera()` para omitir la inicialización y ejecución del stream mediante `_cameraController!.startImageStream()`
- [x] 1.3 Eliminar los métodos obsoletos de lectura del stream: `_onCameraFrame(CameraImage cameraImage)` y `_processFrameFromStream(CameraImage cameraImage)` en `lib/main.dart`
- [x] 1.4 Remover el controlador de animación láser del HUD (`_scannerAnimationController`, `_scannerAnimation`) y limpiar el método `dispose()` de los controladores eliminados

## 2. Implementar Captura de Foto y Pipeline de Inferencia

- [x] 2.1 Renombrar `_triggerManualCapture()` a `_captureAndAnalyze()`
- [x] 2.2 Implementar en `_captureAndAnalyze()` la toma de la foto mediante `_cameraController!.takePicture()`, la lectura asíncrona de sus bytes con `readAsBytes()`, y pasar los bytes a `_tfliteClassifier!.predict(bytes)`
- [x] 2.3 Controlar los estados de procesamiento actualizando la UI con `_isProcessing = true` al inicio de la captura, y retornar a `false` actualizando `_detectedLetter`, `_confidence` y `_statusMessage` al culminar
- [x] 2.4 Agregar bloques `try-catch` robustos en la captura y procesamiento de la foto para manejar errores del sensor o formato de imagen sin colapsar la app

## 3. Adaptar Interfaz de Usuario (UI/UX)

- [x] 3.1 Remover del Drawer lateral (`_buildDrawer()`) el switch de Detección Automática bajo la sección `MODO DE DETECCIÓN` y simplificar su estructura
- [x] 3.2 Remover del HUD del contenedor de la cámara (`_buildCameraContainer()`) el widget del escáner láser animado
- [x] 3.3 Asegurar que el overlay de carga translúcido con "Analizando Seña..." con `CircularProgressIndicator` se muestre de manera fluida únicamente en el lapso en que `_isProcessing` sea verdadero

## 4. Pruebas y Verificación

- [x] 4.1 Compilar la aplicación en el emulador o dispositivo real para verificar que no haya errores de dependencias o compilación
- [x] 4.2 Presionar el botón "CAPTURAR Y ANALIZAR" de la pantalla principal, verificar la captura exitosa y validar que la respuesta del clasificador TFLite sea congruente y rápida
- [x] 4.3 Comprobar la resiliencia ante errores desactivando permisos de cámara u otros escenarios límite y asegurar que los logs de consola no muestren excepciones no controladas
