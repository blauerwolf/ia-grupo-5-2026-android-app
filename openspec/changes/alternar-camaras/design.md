## Context

Actualmente, al arrancar, la aplicación detecta las cámaras disponibles mediante `availableCameras()` y selecciona la primera cámara que tenga dirección frontal (front). Si no encuentra ninguna frontal, selecciona la primera de la lista. Esta inicialización ocurre una sola vez y no existe ningún mecanismo en la UI para cambiar de cámara tras el inicio de la app.

## Goals / Non-Goals

**Goals:**
- Permitir la alternancia dinámica entre cámara frontal y trasera en tiempo de ejecución.
- Implementar un botón toggle en la cabecera principal (`_buildHeader`) para un acceso rápido y limpio.
- Adaptar automáticamente la calibración de espejado horizontal según la cámara seleccionada (activado para frontal, desactivado para trasera) para ofrecer una UX intuitiva.
- Evitar condiciones de carrera y fugas de memoria al liberar y re-inicializar el `CameraController` de manera asíncrona.

**Non-Goals:**
- Soportar el renderizado de múltiples flujos de cámara en pantalla simultáneamente.
- Modificar el clasificador TFLite o sus requerimientos de entrada de imagen (28x28 grayscale).

## Decisions

### 1. Guardar la dirección seleccionada como variable de estado
- **Razón**: Almacenar `CameraLensDirection _selectedLensDirection = CameraLensDirection.front` permite al sistema conocer reactivamente la dirección de la cámara activa y condicionar la UI o los parámetros de espejado.

### 2. Refactor de `_initializeCamera()` para buscar dinámicamente la lente elegida
- **Razón**: En lugar de imponer la cámara frontal de manera fija en el loop inicial, `_initializeCamera()` consultará `_selectedLensDirection` para buscar la cámara correspondiente de entre la lista `widget.cameras`. Si la lente deseada no está disponible, se caerá en un fallback seguro (la primera cámara disponible).

### 3. Método asíncrono seguro `_toggleCamera()`
- **Razón**: Cambiar de cámara requiere un flujo ordenado para evitar excepciones:
  1. Deshabilitar interactividad de la UI activando `_isCameraInitialized = false`.
  2. Llamar de forma segura a `await _cameraController?.dispose()`.
  3. Alternar la dirección: si era `.front`, pasar a `.back`, y viceversa.
  4. Llamar a `await _initializeCamera()`.
  5. Ajustar el espejado horizontal automático: `_mirrorHorizontal = (_selectedLensDirection == CameraLensDirection.front)`. Actualizar el parámetro en el clasificador TFLite activo.

### 4. Botón Toggle en la cabecera principal (`_buildHeader`)
- **Razón**: Colocar un botón circular e iconográfico con `Icons.switch_camera_rounded` al lado del botón del menú (hamburguesa) en la cabecera principal ofrece alta visibilidad, consistencia con el diseño premium de la app y evita interferir en la previsualización de la cámara.

## Risks / Trade-offs

- **[Riesgo] Fugas de recursos al re-inicializar la cámara repetidamente** → *Mitigación*: Asegurar que siempre se llame a `await _cameraController?.dispose()` antes de asignar una nueva instancia al controlador y manejar bloques `try-finally`.
- **[Riesgo] Toques rápidos repetidos en el botón de alternancia** → *Mitigación*: Deshabilitar el callback del botón toggle (colocar `onPressed: null`) mientras `_isCameraInitialized` sea falso o la app esté procesando una inferencia (`_isProcessing`).
