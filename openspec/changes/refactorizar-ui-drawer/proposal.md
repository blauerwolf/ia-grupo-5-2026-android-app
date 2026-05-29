## Why

La interfaz actual de la aplicación contiene textos y botones en inglés o de prueba que no corresponden al contexto académico del proyecto, y carece de información de autoría del grupo. Se requiere refactorizar la UI para que sea coherente con el nombre real de la materia y refleje la identidad del equipo de desarrollo.

## What Changes

- El título principal de la pantalla cambia de `'SIGN LANGUAGE AI'` a `'Detección de Lenguaje de Señas'`.
- Se agrega una entrada informativa en el drawer que muestra `"Grupo 5"` como identificación del equipo.
- El switch de detección automática se reubica dentro del drawer como entrada independiente con su sección propia.
- Se eliminan los botones de test `ASSET A` y `ASSET U` del panel de control (eran utilidades de debug no aptas para producción).

## Capabilities

### New Capabilities
- `grupo-info-drawer`: Entrada informativa en el drawer que muestra la identificación del grupo (`Grupo 5`).

### Modified Capabilities
- `app-header`: El texto del encabezado principal cambia de inglés (`SIGN LANGUAGE AI`) a español (`Detección de Lenguaje de Señas`).
- `drawer-controls`: El drawer pasa a tener dos secciones: información del grupo y control de detección automática. Se elimina el bloque de botones de asset del panel de control.

## Impact

- **Archivo afectado**: `lib/main.dart` únicamente.
- **Método `_buildHeader()`**: Actualizar el texto del título.
- **Método `_buildDrawer()`**: Agregar tile informativo de "Grupo 5" antes del switch de detección automática.
- **Método `_buildControlPanel()`**: Eliminar el `Row` que contiene los `OutlinedButton.icon` de Asset A y Asset U.
- **Método `_testWithAsset()`**: Puede mantenerse en el código (no se usa si no hay botones) o eliminarse para limpieza.
- Sin cambios en dependencias, APIs ni lógica de negocio.
