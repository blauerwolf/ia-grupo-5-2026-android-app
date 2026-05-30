## Context

El método `_buildHeader()` en `lib/main.dart` actualmente renderiza un Row que contiene: el botón del Drawer, el botón Toggle de la cámara, un Column con el título/subtítulo, y al final, un Container indicador del estado del motor TFLite. Este indicador dibuja un círculo luminoso verde o rojo con la leyenda "OFFLINE OK" o "CARGANDO" basándose en `_isTfliteModelLoaded`. El usuario ha solicitado remover esta leyenda para simplificar la cabecera.

## Goals / Non-Goals

**Goals:**
- Eliminar el widget contenedor del estado del motor ("OFFLINE OK" / "CARGANDO") de `_buildHeader()`.
- Optimizar el espacio disponible para el título y subtítulo en pantallas de ancho reducido, evitando potenciales overflows.

**Non-Goals:**
- Eliminar la variable `_isTfliteModelLoaded` o la lógica de carga del motor en background (se mantiene intacta para condicionar la habilitación del botón de captura y pruebas).

## Decisions

### 1. Eliminar el Container indicador de la cabecera
- **Razón**: Es una tarea puramente visual. Quitar este Container del Row del encabezado hace que el Column del título se expanda naturalmente ocupando el espacio restante de la pantalla de forma balanceada y armónica.
- **Alternativas consideradas**: Reubicar la leyenda en otra sección. *Rechazada* porque la información del estado de inicialización ya es visible a nivel de logs y en los cambios de interactividad de los botones de captura, por lo que no aporta valor visible en producción.

## Risks / Trade-offs

- **[Riesgo] Pérdida de feedback inmediato sobre la carga del modelo** → *Mitigación*: Se mantiene la variable `_statusMessage` en el HUD de la cámara (esquina superior izquierda de la vista previa) mostrando "Cargando motor offline..." o "TFLite local activo". Esto garantiza que el usuario siga informado sin congestionar la cabecera principal.
