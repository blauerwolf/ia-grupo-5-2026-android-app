## 1. Actualizar encabezado principal

- [x] 1.1 En `_buildHeader()`, cambiar el texto `'SIGN LANGUAGE AI'` por `'Detección de Lenguaje de Señas'`

## 2. Agregar tile "Grupo 5" en el drawer

- [x] 2.1 En `_buildDrawer()`, agregar una nueva sección `INFORMACIÓN` con etiqueta de sección antes del tile de detección
- [x] 2.2 Agregar un `Container` con `ListTile` estático (sin `onTap`) que muestre el ícono `Icons.group_outlined`, el título `Grupo 5` y el subtítulo `UTN FRLP · IA 2026`, con el mismo estilo glassmorphic del tile existente

## 3. Eliminar botones de test de assets

- [x] 3.1 En `_buildControlPanel()`, eliminar el `Row` completo que contiene los `OutlinedButton.icon` de `ASSET A` y `ASSET U` (y su `SizedBox` separator)
- [x] 3.2 Eliminar el método `_testWithAsset(String assetPath)` de la clase `_SignLanguageScreenState`

## 4. Verificación

- [x] 4.1 Compilar la app (`flutter build` o `flutter run`) sin errores
- [x] 4.2 Confirmar visualmente que el header muestra `'Detección de Lenguaje de Señas'`
- [x] 4.3 Confirmar que el drawer muestra el tile de `Grupo 5` y el switch de detección automática
- [x] 4.4 Confirmar que los botones `ASSET A` y `ASSET U` no aparecen en la UI
