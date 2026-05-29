## 1. Umbral de confianza en tflite_native.dart

- [x] 1.1 Agregar la constante `const double kMinConfidence = 0.70;` al inicio de `tflite_native.dart` (a nivel de archivo, fuera de la clase)
- [x] 1.2 En el método `predict()`, después de calcular `maxConfidence` por argmax, agregar la comprobación: si `maxConfidence < kMinConfidence`, retornar `{'success': true, 'detected': false, 'letter': '-', 'confidence': maxConfidence, 'class_idx': classIdx}`
- [x] 1.3 En el retorno normal (confianza suficiente), agregar el campo `'detected': true` al mapa de retorno

## 2. Pipeline de preprocesamiento mejorado en tflite_native.dart

- [x] 2.1 Después de convertir la imagen a escala de grises (`grayscaleImage`) y antes del resize, agregar estiramiento de histograma usando `img.normalize(grayscaleImage, min: 0, max: 255)` para maximizar contraste
- [x] 2.2 Verificar que el orden del pipeline sea: crop → grayscale → normalize → resize(28×28, cubic) → tensor [1,28,28,1]

## 3. Actualizar main.dart para manejar detected: false

- [x] 3.1 En `_captureAndPredict()` en `main.dart`, leer el campo `detected` del resultado. Si `detected == false` (o está ausente), actualizar `_detectedLetter = '-'` y `_confidence = result['confidence']` igualmente (para mostrar la confianza real)
- [x] 3.2 Asegurarse de que la UI resetee la letra a `'-'` en cada ciclo de detección cuando no hay detección válida, en lugar de quedarse congelada en la última letra

## 4. Verificación

- [x] 4.1 Ejecutar `flutter analyze lib/` sin errores nuevos
- [ ] 4.2 Probar en dispositivo/simulador: con cámara apuntando a fondo vacío, verificar que el indicador muestre `'-'` consistentemente
- [ ] 4.3 Probar con una mano haciendo una seña clara: verificar que el indicador detecte la letra correctamente con confianza ≥ 70%
