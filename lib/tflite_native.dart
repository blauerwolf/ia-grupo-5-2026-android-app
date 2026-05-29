import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'tflite_stub.dart';

/// Confianza mínima requerida para aceptar una detección como válida.
/// Ajustar si hay muchos falsos negativos (bajar) o positivos espurios (subir).
const double kMinConfidence = 0.60;

class TfliteClassifierImpl implements TfliteClassifier {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  @override
  double cropFraction = 0.5;

  @override
  bool mirrorHorizontal = false;

  @override
  bool contrastStretch = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/modelo_sign_language.tflite');
      _isLoaded = true;
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('[TFLite] Inicializado OK. Input: $inputShape  Output: $outputShape');
    } catch (e) {
      _isLoaded = false;
      debugPrint('[TFLite] Error cargando modelo: $e');
      rethrow;
    }
  }

  /// Predicción a partir de bytes JPEG/PNG. Útil para verificación con imágenes de referencia.
  @override
  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    if (_interpreter == null || !_isLoaded) {
      throw Exception('Modelo TFLite no inicializado');
    }
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('No se pudo decodificar la imagen.');
    debugPrint('[TFLite] predict() imagen: ${image.width}x${image.height}');
    return _runInference(image);
  }

  /// Predicción a partir de un frame de cámara en tiempo real.
  ///
  /// [yPlaneBytes] – bytes del plano Y (canal de luminancia) en YUV420,
  ///                 o bytes de grayscale derivados de BGRA8888 (iOS/macOS).
  /// [rotationDegrees] – grados de rotación del sensor respecto a la pantalla
  ///                     (típicamente 90° en cámaras traseras Android).
  @override
  Future<Map<String, dynamic>> predictFromCamera(
    Uint8List yPlaneBytes,
    int srcWidth,
    int srcHeight,
    int bytesPerRow,
    int rotationDegrees,
  ) async {
    if (_interpreter == null || !_isLoaded) {
      throw Exception('Modelo TFLite no inicializado');
    }

    // 1. Construir img.Image RGB a partir del plano Y (R=G=B=luma).
    //    Si mirrorHorizontal es verdadero, invertimos las filas en el sensor de forma vertical
    //    (lo cual, tras la rotación de 90° o 270°, resulta en un espejado horizontal perfecto en la pantalla).
    img.Image image = img.Image(width: srcWidth, height: srcHeight);
    for (int row = 0; row < srcHeight; row++) {
      final int srcRow = mirrorHorizontal ? (srcHeight - 1 - row) : row;
      final int rowStart = srcRow * bytesPerRow;
      for (int col = 0; col < srcWidth; col++) {
        final int luma = yPlaneBytes[rowStart + col];
        image.setPixelRgb(col, row, luma, luma, luma);
      }
    }

    // 2. Corregir orientación del sensor.
    if (rotationDegrees == 90) {
      image = img.copyRotate(image, angle: 90);
    } else if (rotationDegrees == 180) {
      image = img.copyRotate(image, angle: 180);
    } else if (rotationDegrees == 270) {
      image = img.copyRotate(image, angle: 270);
    }

    debugPrint('[TFLite] predictFromCamera() frame: ${image.width}x${image.height} rot=${rotationDegrees}° mirror=$mirrorHorizontal crop=$cropFraction');
    return _runInference(image, cropFraction: cropFraction);
  }

  /// Pipeline de inferencia compartido: crop cuadrado → grayscale → resize 28×28 → tensor → argmax.
  ///
  /// El preprocesamiento replica exactamente lo que hace deteccion.py:
  ///   PIL.convert('L') → resize(28, 28) → arr / 255.0
  /// SIN estiramiento de histograma (img.normalize), que no estaba en el entrenamiento.
  Future<Map<String, dynamic>> _runInference(img.Image rawImage, {double cropFraction = 1.0}) async {
    // 1. Recorte cuadrado centrado.
    //    cropFraction controla qué fraccion del lado menor se usa:
    //      1.0 (default) → usa todo el cuadrado (para imágenes de archivo donde la mano ya llena el frame)
    //      0.5           → usa solo el centro 50% (para frames de cámara real donde la mano es más pequeña)
    final int w = rawImage.width;
    final int h = rawImage.height;
    final int fullSide = w < h ? w : h;
    final int cropSize = (fullSide * cropFraction).round().clamp(1, fullSide);
    final img.Image croppedImage = img.copyCrop(
      rawImage,
      x: (w - cropSize) ~/ 2,
      y: (h - cropSize) ~/ 2,
      width: cropSize,
      height: cropSize,
    );
    debugPrint('[TFLite] Crop: ${croppedImage.width}x${croppedImage.height} (fraction=${cropFraction.toStringAsFixed(2)})');

    // 2. Escala de grises — equivalente a PIL convert('L').
    final img.Image grayscaleImage = img.grayscale(croppedImage);

    // 3. Resize a 28×28 con interpolación cúbica.
    //    PIL usa LANCZOS (sinc) para downscaling; la biblioteca 'image' de Dart no tiene
    //    LANCZOS pero Interpolation.cubic (bicúbica) es la aproximación más cercana y
    //    produce resultados mucho más similares que .linear al reducir de 90-240px a 28px.
    final img.Image resizedImage = img.copyResize(
      grayscaleImage,
      width: 28,
      height: 28,
      interpolation: img.Interpolation.cubic,
    );

    // 4. Construir tensor de entrada [1, 28, 28, 1], normalizar a [0.0, 1.0].
    //    Si contrastStretch está activo, se aplica estiramiento min-max en el tensor.
    double Function(int x, int y) getPixelValue;
    if (contrastStretch) {
      double minVal = 255.0;
      double maxVal = 0.0;
      for (int y = 0; y < 28; y++) {
        for (int x = 0; x < 28; x++) {
          final double val = resizedImage.getPixel(x, y).r.toDouble();
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }
      if (maxVal > minVal) {
        final double range = maxVal - minVal;
        getPixelValue = (x, y) => (resizedImage.getPixel(x, y).r.toDouble() - minVal) / range;
      } else {
        getPixelValue = (x, y) => resizedImage.getPixel(x, y).r.toDouble() / 255.0;
      }
    } else {
      getPixelValue = (x, y) => resizedImage.getPixel(x, y).r.toDouble() / 255.0;
    }

    final inputTensor = List.generate(
      1,
      (_) => List.generate(
        28,
        (y) => List.generate(
          28,
          (x) => [getPixelValue(x, y)],
        ),
      ),
    );

    // 5. Tensor de salida [1, 25] para 25 clases (letras A-Y, sin J ni Z).
    final outputTensor = List.generate(1, (_) => List<double>.filled(25, 0.0));

    // 6. Inferencia TFLite síncrona (~1-5ms para entrada 28×28).
    _interpreter!.run(inputTensor, outputTensor);
    debugPrint('[TFLite] Output raw: ${outputTensor[0]}');

    // 7. Argmax: encontrar la clase con mayor valor de salida.
    int classIdx = 0;
    double maxConf = 0.0;
    for (int i = 0; i < 25; i++) {
      final double val = outputTensor[0][i];
      if (val > maxConf) {
        maxConf = val;
        classIdx = i;
      }
    }

    // Mapeo de índice a letra: 0→A, 1→B, ..., 24→Y
    // (ASL MNIST usa índices 0-24 para las 25 letras estáticas A-Y, excluyendo J y Z)
    final String letter = String.fromCharCode('A'.codeUnitAt(0) + classIdx);
    debugPrint('[TFLite] → idx=$classIdx letra=$letter conf=${(maxConf * 100).toStringAsFixed(1)}%');

    // 8. Aplicar umbral mínimo de confianza.
    if (maxConf < kMinConfidence) {
      debugPrint('[TFLite] Sin detección (${(maxConf * 100).toStringAsFixed(1)}% < ${(kMinConfidence * 100).toStringAsFixed(0)}%)');
      return {
        'success': true,
        'detected': false,
        'letter': '-',
        'confidence': maxConf,
        'class_idx': classIdx,
      };
    }

    debugPrint('[TFLite] ✓ Detección: $letter (${(maxConf * 100).toStringAsFixed(1)}%)');
    return {
      'success': true,
      'detected': true,
      'letter': letter,
      'confidence': maxConf,
      'class_idx': classIdx,
    };
  }

  @override
  void close() {
    _interpreter?.close();
  }
}

TfliteClassifier createClassifier() => TfliteClassifierImpl();
