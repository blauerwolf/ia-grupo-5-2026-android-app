## MODIFIED Requirements

### Requirement: Encabezado principal muestra título en español
El encabezado de la pantalla principal SHALL mostrar el texto `'Detección de Lenguaje de Señas'` en lugar del texto anterior en inglés `'SIGN LANGUAGE AI'`.

#### Scenario: Título visible en pantalla
- **WHEN** la aplicación carga la pantalla principal
- **THEN** el encabezado SHALL mostrar el texto `'Detección de Lenguaje de Señas'` con overflow ellipsis si no cabe

## MODIFIED Requirements

### Requirement: Drawer contiene switch de detección automática
El drawer SHALL contener el control `SwitchListTile` de detección automática bajo la sección `MODO DE DETECCIÓN`, con el mismo comportamiento que el existente.

#### Scenario: Switch activa detección automática
- **WHEN** el usuario activa el switch en el drawer
- **THEN** la app SHALL iniciar el bucle de detección automática en tiempo real

#### Scenario: Switch desactiva detección automática
- **WHEN** el usuario desactiva el switch en el drawer
- **THEN** la app SHALL detener el bucle automático y mostrar el botón de captura manual

## REMOVED Requirements

### Requirement: Panel de control muestra botones de test de assets
**Reason**: Los botones `ASSET A` y `ASSET U` son utilidades de debug que no corresponden a la versión de entrega académica. El método `_testWithAsset()` también se elimina por quedar sin uso.
**Migration**: No se requiere migración. Los assets `letra_a.png` y `letra_u.png` pueden permanecer en el bundle sin referencia activa.
