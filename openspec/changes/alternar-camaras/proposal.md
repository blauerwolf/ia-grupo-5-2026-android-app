## Why

Actualmente, la aplicación inicializa por defecto la cámara frontal de manera exclusiva. Incorporar la capacidad de alternar entre la cámara frontal y trasera permite al usuario capturar señas realizadas por otras personas o enfocar objetos externos con mayor comodidad utilizando la lente trasera del dispositivo, lo cual expande notablemente la usabilidad y la versatilidad de la aplicación en entornos educativos y prácticos.

## What Changes

- **AGREGADO**: Botón selector (toggle button) en la interfaz para alternar dinámicamente la lente activa entre frontal y trasera.
- **MODIFICADO**: Inicialización de la cámara en `lib/main.dart` para soportar tanto cámaras frontales como traseras, recargando el controlador adecuadamente cuando el usuario decida alternarlas.
- **MODIFICADO**: Ajuste inteligente de la calibración de espejado horizontal según la lente seleccionada (espejado activado por defecto para cámara frontal, y desactivado por defecto para cámara trasera).

## Capabilities

### New Capabilities
- `camera-toggle`: Permite alternar dinámicamente en tiempo de ejecución entre las lentes delantera y trasera disponibles en el dispositivo.

### Modified Capabilities
*(Ninguna. Se reutiliza la infraestructura de inicialización y preprocesamiento existente).*

## Impact

- `lib/main.dart`:
  - Definición de una nueva variable de estado `_selectedLensDirection` para rastrear la lente de cámara elegida (frontal por defecto).
  - Modificación de `_initializeCamera()` para buscar e inicializar la cámara que coincida con `_selectedLensDirection`.
  - Creación de un método `_toggleCamera()` que libere la cámara activa, alterne la dirección de la lente y re-inicialice el controlador.
  - Inserción de un botón flotante / toggle button responsivo en la UI (por ejemplo, al lado del botón del menú en la cabecera) para alternar las cámaras.
