## 1. Definición de Variables y Adaptación de Inicialización de Cámara

- [x] 1.1 Declarar la variable de estado `CameraLensDirection _selectedLensDirection = CameraLensDirection.front;` en `lib/main.dart`
- [x] 1.2 Refactorizar `_initializeCamera()` para buscar la cámara que coincida con `_selectedLensDirection` de la lista de cámaras y usar la primera como fallback si no existe
- [x] 1.3 Asignar el espejado horizontal automático en `_initializeCamera()` según la lente seleccionada: `_mirrorHorizontal = (_selectedLensDirection == CameraLensDirection.front)` y pasarlo al clasificador `_tfliteClassifier`

## 2. Implementar Método de Alternancia Dinámica (Toggle)

- [x] 2.1 Crear el método asíncrono `_toggleCamera()` en `_SignLanguageScreenState` que libere y destruya el controlador actual mediante `dispose()`
- [x] 2.2 Cambiar `_selectedLensDirection` al valor opuesto (si era frontal cambiar a trasera, y viceversa)
- [x] 2.3 Llamar a `_initializeCamera()` de forma asíncrona dentro de `_toggleCamera()` controlando el estado `_isCameraInitialized = false` para mostrar el loader durante el proceso
- [x] 2.4 Ajustar automáticamente `_mirrorHorizontal` tras la alternancia y propagar el cambio al clasificador `_tfliteClassifier`

## 3. Agregar Botón Toggle en la UI

- [x] 3.1 Agregar el botón interactivo con `Icons.switch_camera_rounded` en `_buildHeader()` a la derecha del botón del menú lateral
- [x] 3.2 Asegurar que el botón esté deshabilitado si `_cameraController` se está inicializando o está en curso una inferencia manual (`_isProcessing`)
- [x] 3.3 Dar un diseño premium al botón de alternancia consistente con la cabecera y el botón de menú existente

## 4. Pruebas y Verificación

- [x] 4.1 Compilar la aplicación y verificar que no existan errores de compilación ni advertencias en el análisis estático de Flutter
- [x] 4.2 Probar la alternancia de lentes en un dispositivo físico y constatar que el feed de la cámara trasera se inicialice perfectamente
- [x] 4.3 Verificar que el espejado horizontal se desactive de forma predeterminada al usar la cámara trasera y se active con la frontal
