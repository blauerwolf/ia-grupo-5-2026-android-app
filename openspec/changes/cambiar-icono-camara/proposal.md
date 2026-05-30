## Why

Actualmente, el botón de alternancia de cámara muestra íconos específicos que cambian según la lente activa (`Icons.camera_front_rounded` y `Icons.camera_rear_rounded`). Para simplificar y estandarizar la interfaz de usuario, se solicita cambiar estos íconos dinámicos por un único ícono de dos flechas en ciclo (como `Icons.switch_camera_rounded` o similar), que representa de forma universal e intuitiva la acción de alternar o rotar cámaras en dispositivos móviles.

## What Changes

- **MODIFICADO**: El ícono del botón de alternancia de cámara en `_buildHeader()`. Se elimina la selección condicional basada en la lente activa y se adopta un ícono estático de flechas en ciclo (`Icons.switch_camera_rounded`).

## Capabilities

### New Capabilities
*(Ninguna. Es un ajuste visual e iconográfico sobre una capacidad existente).*

### Modified Capabilities
- `camera-toggle`: Se modifica la apariencia visual del botón de alternancia de cámara en la cabecera principal.

## Impact

- `lib/main.dart`:
  - Modificación del elemento `Icon` secundario dentro del `GestureDetector` de alternancia de cámara en `_buildHeader()`, usando `Icons.switch_camera_rounded` de forma estática en lugar de la lógica condicional anterior.
