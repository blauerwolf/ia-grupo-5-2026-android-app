## Why

La leyenda "OFFLINE OK" / "CARGANDO" (indicador de estado del motor TFLite) en la esquina superior derecha de la cabecera añade ruido visual innecesario en la pantalla principal. Remover este widget simplifica el diseño de la interfaz de usuario, optimiza el espacio horizontal y mejora la estética minimalista y premium de la aplicación sin alterar la funcionalidad offline nativa subyacente.

## What Changes

- **REMOVIDO**: El widget indicador del estado del motor TFLite ("OFFLINE OK" / "CARGANDO") de la esquina superior derecha del encabezado en la pantalla principal.

## Capabilities

### New Capabilities
*(Ninguna. Es una simplificación puramente visual).*

### Modified Capabilities
- `header-ui`: Se actualiza la interfaz de la cabecera para eliminar el elemento visual indicador de estado del motor offline.

## Impact

- `lib/main.dart`:
  - Remoción del widget de tipo `Container` que dibuja el círculo luminoso y los textos "OFFLINE OK" y "CARGANDO" dentro de `_buildHeader()`.
