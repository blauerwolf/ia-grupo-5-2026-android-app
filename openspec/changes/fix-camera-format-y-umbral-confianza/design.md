## Context

El clasificador TFLite actual (`TfliteClassifierImpl.predict()`) ejecuta siempre el argmax sobre el vector de salida de 25 clases, retornando una letra con cualquier valor de confianza, incluso cuando la imagen no contiene una mano. El pipeline de preprocesamiento aplica escala de grises, recorte central y resize a 28×28 — pero no realiza ninguna normalización de contraste ni umbralización adaptativa. El dataset de entrenamiento (ASL Alphabet / Sign Language MNIST) utiliza imágenes con fondo blanco puro y mano de alto contraste. Las imágenes reales de cámara tienen fondos variables y condiciones de iluminación no controladas, lo que produce distribuciones de píxeles muy distintas a las del entrenamiento, causando predicciones espurias con alta confianza relativa pero baja confianza absoluta.

## Goals / Non-Goals

**Goals:**
- Agregar un umbral de confianza mínima (`kMinConfidence = 0.70`) que suprima predicciones cuando el modelo no está lo suficientemente seguro.
- Mejorar el pipeline de preprocesamiento para aproximarse más al preprocesamiento del dataset de entrenamiento: estiramiento de histograma + umbralización local (Otsu simplificado sobre la región central recortada).
- Actualizar la UI en `main.dart` para que cuando `detected == false` se muestre `'-'` y confianza 0%, sin alterar el flujo de detección automática.

**Non-Goals:**
- No se implementa detección de mano con MediaPipe, TensorFlow Lite Object Detection ni ningún modelo secundario (complejidad fuera de alcance).
- No se modifica el modelo `.tflite` ni el proceso de entrenamiento.
- No se implementa CLAHE completo (se usa solo estiramiento de histograma, disponible vía el paquete `image`).
- No se cambia el periodo del timer de detección automática.

## Decisions

### D1: Umbral de confianza fijo vs. adaptativo
**Decisión**: Umbral fijo (`kMinConfidence = 0.70`), declarado como constante en `tflite_native.dart`.  
**Razón**: Simple de ajustar, auditables y sin estado. Un umbral adaptativo necesitaría historial de predicciones y mayor complejidad.  
**Alternativa considerada**: Umbral adaptativo basado en la media móvil de las últimas N predicciones — descartado por complejidad innecesaria en esta etapa.

### D2: Estrategia de preprocesamiento
**Decisión**: Pipeline mejorado en este orden:
1. Crop central cuadrado (ya existente)
2. Escala de grises (ya existente)
3. **Nuevo** — Estiramiento de histograma: estirar los valores de pixel al rango completo [0, 255] usando `img.normalize()` del paquete `image`
4. **Nuevo** — Umbralización de Otsu simplificada: calcular umbral como media de los pixels, binarizar a blanco/negro para separar mano del fondo
5. Resize a 28×28 (ya existente)
6. Normalizar a [0,1] y construir tensor (ya existente)

**Razón**: Replicar el alto contraste mano/fondo del dataset de entrenamiento. El paquete `image` ya disponible provee `normalize()` sin dependencias nuevas.  
**Alternativa considerada**: Usar un modelo de segmentación de mano previo — descartado por overhead de latencia y complejidad.

### D3: Campo `detected` en el resultado de `predict()`
**Decisión**: Agregar campo booleano `detected` al `Map<String, dynamic>` de retorno. Si `maxConfidence < kMinConfidence`, retornar `{'success': true, 'detected': false, 'letter': '-', 'confidence': maxConfidence}`.  
**Razón**: Separar "inferencia exitosa" de "detección válida" sin romper el contrato existente (`success: true` siempre que no haya excepción).

## Risks / Trade-offs

- **[Riesgo] Umbral demasiado alto causa falsos negativos** → Mitigación: `kMinConfidence = 0.70` es conservador pero ajustable. Se puede bajar a 0.60 si se detectan muchos falsos negativos en pruebas reales.
- **[Riesgo] La umbralización de Otsu binariza la imagen y puede perder detalles de la mano en condiciones de baja luz** → Mitigación: aplicar umbralización solo como un paso suave (invertir la imagen si el fondo es oscuro antes de umbralizar).
- **[Trade-off] Latencia adicional** → El estiramiento de histograma y la umbralización agregan ~1-5ms por frame en dispositivos móviles modernos. Aceptable dado el timer de 600ms.
- **[Riesgo] El modelo fue entrenado con imágenes binarizadas o solo en escala de grises** → Si el modelo fue entrenado con grises suavizados (no binarios), la umbralización podría empeorar la precisión. Se puede desactivar la binarización si los tests lo indican.

## Open Questions

- ¿El modelo fue entrenado con imágenes completamente binarizadas (blanco y negro puro) o con grises suavizados? Esto determina si la umbralización de Otsu es beneficiosa o perjudicial. **Verificar con `deteccion.py`**: el script solo hace `convert('L')` + normalize, sin binarizar — por lo tanto, **no aplicar binarización**, solo estiramiento de histograma.
