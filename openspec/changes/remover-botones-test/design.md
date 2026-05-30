## Context

El método `_buildControlPanel()` en `lib/main.dart` incluye una botonera adicional con dos botones de depuración: "TEST A" y "TEST U". Estos botones permiten verificar la predictibilidad de la inferencia dactilológica local cargando imágenes estáticas de los assets. Al removerlos, simplificamos la pantalla para el usuario final y eliminamos código muerto en la aplicación.

## Goals / Non-Goals

**Goals:**
- Eliminar el widget `Row` que contiene los botones `TEST A` y `TEST U` de `_buildControlPanel()`.
- Eliminar por completo el método utilitario `_testWithAsset()` de `lib/main.dart`.
- Modificar el archivo `README.md` eliminando la referencia a la depuración y validación por assets en la sección de características.

**Non-Goals:**
- Eliminar los archivos físicos de assets (`letra_a.png` y `letra_u.png`) del directorio de assets, para preservar historial de archivos, aunque ya no tengan referencia activa en el código Flutter.

## Decisions

### 1. Remoción de la Fila de Botones Test
- **Razón**: Al quitar la fila de botones `TEST A` y `TEST U`, el control panel se centra únicamente en la visualización de resultados dactilológicos y la captura de fotos en tiempo real. Esto mejora notablemente la estética de la pantalla reduciendo controles innecesarios.

### 2. Eliminación del método `_testWithAsset`
- **Razón**: Este método fue diseñado únicamente para alimentar la inferencia con bytes extraídos del bundle de assets para los botones de prueba. Al no contar con botones activos, queda huérfano y su remoción mantiene la legibilidad y simplicidad del código del estado.

## Risks / Trade-offs

- **[Riesgo] Pérdida de una forma rápida de verificar el clasificador sin cámara** → *Mitigación*: La consistencia e integridad del preprocesamiento y clasificador TFLite ya ha sido completamente auditada, y los tests unitarios/widgets automatizados se encargan de verificar el montaje. No hay un riesgo operativo real en producción por remover estas utilidades de depuración.
