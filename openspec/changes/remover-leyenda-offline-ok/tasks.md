## 1. Limpieza de Interfaz en la Cabecera Principal

- [x] 1.1 Localizar el widget indicador de estado (Container circular que evalúa `_isTfliteModelLoaded`) en `_buildHeader()` de `lib/main.dart`
- [x] 1.2 Remover el bloque del widget indicador de estado del motor y su respectivo `const SizedBox(width: 10)`
- [x] 1.3 Validar que el Column de títulos se expanda y alinee correctamente en el espacio liberado de la fila

## 2. Pruebas y Verificación

- [x] 2.1 Compilar la aplicación y verificar que compile sin ningún tipo de error
- [x] 2.2 Ejecutar `flutter analyze` para asegurar la calidad y consistencia del código sin advertencias
- [x] 2.3 Correr `flutter test` para certificar la integridad de las pruebas de widget tras la limpieza de la UI
