## Why

El modelo TFLite de lenguaje de señas siempre produce una predicción mediante argmax, sin importar si la imagen de entrada contiene o no una mano haciendo una seña. Esto hace que la app muestre letras aleatorias aun cuando no hay ninguna mano frente a la cámara. El problema tiene dos causas raíz: (1) ausencia de un umbral de confianza mínima para aceptar una predicción, y (2) posibles inconsistencias en el preprocesamiento de la imagen capturada respecto al preprocesamiento usado durante el entrenamiento del modelo (fondo blanco vs fondo real de cámara, sin normalización de contraste).

## What Changes

- **Umbral de confianza**: la función `predict()` en `tflite_native.dart` solo retornará una letra detectada si la confianza del argmax supera un umbral configurable (ej. 0.70). Si no supera el umbral, retornará `letter: '-'` y `confidence: maxConfidence` con `detected: false`.
- **Preprocesamiento mejorado**: antes de enviar la imagen al modelo, se aplicará **normalización de contraste adaptativa** (estiramiento de histograma o CLAHE simplificado) y **umbralización local** para separar mejor la mano del fondo, intentando replicar más fielmente las condiciones del dataset de entrenamiento (ASL Alphabet: fondo blanco, mano con alto contraste).
- **Feedback visual**: cuando la confianza no supera el umbral, la UI mostrará `'-'` en lugar de una letra, y el indicador de confianza quedará en 0% — dejando claro que no se detectó ninguna seña válida.
- **Constante configurable**: el umbral se define como constante `kMinConfidence` en `tflite_native.dart` para facilitar ajustes experimentales.

## Capabilities

### New Capabilities
- `confidence-threshold`: Lógica de umbral mínimo de confianza en `predict()` que suprime detecciones espurias cuando el modelo no está seguro.
- `image-preprocessing-pipeline`: Pipeline de preprocesamiento de imagen robusto que normaliza contraste y aplica umbralización local para mejorar la separación mano/fondo antes de la inferencia.

### Modified Capabilities
- (ninguna — los cambios son de implementación interna sin alterar contratos de API existentes)

## Impact

- **`lib/tflite_native.dart`**: modificaciones en el método `predict()` — agregar umbral de confianza y mejorar el pipeline de preprocesamiento.
- **`lib/main.dart`**: ajuste mínimo en `_captureAndPredict()` para manejar el nuevo campo `detected` en el resultado y mostrar `'-'` cuando no hay detección válida.
- **Sin cambios en dependencias externas**: el paquete `image` ya está disponible y permite todas las operaciones de preprocesamiento necesarias.
- **Sin cambios en el modelo**: el archivo `.tflite` permanece igual.
