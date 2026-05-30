## Why

Los botones `TEST A` y `TEST U` ubicados en el panel de control son herramientas utilitarias de depuración que permitían probar el clasificador con imágenes predefinidas en los assets. Al estar el proyecto finalizado y listo para su entrega académica, estas opciones de depuración ya no son necesarias en la UI y deben ser removidas para ofrecer una interfaz de usuario final limpia, profesional y libre de elementos de debug.

## What Changes

- **REMOVIDO**: Los botones flotantes `TEST A` y `TEST U` del panel de control de la pantalla principal.
- **REMOVIDO**: El método utilitario `_testWithAsset(String assetPath)` en `lib/main.dart` encargado de la inferencia simulada.
- **MODIFICADO**: El archivo `README.md` para eliminar la mención y explicación de estas pruebas de assets de depuración.

## Capabilities

### New Capabilities
*(Ninguna. Es una simplificación puramente visual y de código utilitario).*

### Modified Capabilities
- `control-panel`: Se actualiza la interfaz de controles para eliminar las opciones de testeo de assets y simplificar la botonera.

## Impact

- `lib/main.dart`:
  - Eliminación de la fila de botones `TEST A` y `TEST U` en `_buildControlPanel()`.
  - Eliminación del método `_testWithAsset()` del estado de la pantalla.
- `README.md`:
  - Remoción de la sección de características que describe la validación por assets (`TEST A` y `TEST U`).
