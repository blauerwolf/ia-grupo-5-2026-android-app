## ADDED Requirements

### Requirement: Umbral de confianza mínima para aceptar detección
El sistema SHALL definir una constante `kMinConfidence` (valor por defecto: `0.70`) en `tflite_native.dart`. La función `predict()` SHALL retornar `detected: false` y `letter: '-'` cuando la confianza máxima del argmax sea menor que `kMinConfidence`, en lugar de emitir una predicción espuria.

#### Scenario: Imagen sin mano — confianza baja
- **WHEN** la imagen capturada no contiene una mano reconocible y el modelo produce una confianza máxima menor a `kMinConfidence`
- **THEN** el resultado SHALL contener `{'success': true, 'detected': false, 'letter': '-', 'confidence': <valor_real>}`

#### Scenario: Imagen con mano clara — confianza alta
- **WHEN** la imagen capturada contiene una mano haciendo una seña clara y el modelo produce una confianza mayor o igual a `kMinConfidence`
- **THEN** el resultado SHALL contener `{'success': true, 'detected': true, 'letter': <letra>, 'confidence': <valor_real>}`

#### Scenario: Excepción en inferencia no afectada por umbral
- **WHEN** ocurre una excepción en `predict()` (modelo no inicializado, imagen inválida)
- **THEN** el resultado SHALL contener `{'success': false, 'error': <mensaje>}` independientemente del umbral

---

### Requirement: Pipeline de preprocesamiento con estiramiento de histograma
El sistema SHALL aplicar estiramiento de histograma (normalización de rango de píxeles al intervalo [0, 255]) sobre la imagen en escala de grises antes del resize a 28×28, para maximizar el contraste y aproximar la distribución de píxeles al dataset de entrenamiento.

#### Scenario: Imagen con bajo contraste (fondo similar a mano)
- **WHEN** la imagen capturada tiene bajo contraste (valores de píxel concentrados en un rango estrecho)
- **THEN** el preprocesamiento SHALL estirar el histograma para que el valor mínimo sea 0 y el máximo sea 255 antes de la normalización [0,1]

#### Scenario: Imagen con contraste normal
- **WHEN** la imagen ya tiene buen contraste (valores distribuidos en todo el rango)
- **THEN** el estiramiento de histograma SHALL tener efecto mínimo y no degradar la imagen

---

### Requirement: UI muestra estado "sin detección"
Cuando la inferencia retorna `detected: false`, la UI SHALL mostrar `'-'` en el indicador de letra estimada y SHALL mostrar la confianza real en la barra de confianza (sin congelar en el valor anterior).

#### Scenario: Cámara apuntando a fondo vacío
- **WHEN** la cámara captura un frame sin mano visible y `predict()` retorna `detected: false`
- **THEN** el widget de letra SHALL mostrar `'-'` y la barra de confianza SHALL reflejar la confianza real (baja)

#### Scenario: Transición de detección a no-detección
- **WHEN** el usuario retira la mano de la cámara después de una detección exitosa
- **THEN** en el próximo ciclo con `detected: false`, la letra SHALL volver a `'-'` en lugar de quedarse congelada en la última letra detectada
