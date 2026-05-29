import 'dart:typed_data';

class TfliteClassifier {
  bool get isLoaded => false;
  bool get isSupported => false;

  double cropFraction = 0.5;
  bool mirrorHorizontal = false;
  bool contrastStretch = false;

  Future<void> initialize() async {
    // No hace nada en la web
  }

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    return {
      'success': false,
      'error': 'Inferencia TFLite local offline no soportada en la Web. Por favor utiliza el modo Servidor Python.'
    };
  }

  /// Predicción a partir de un frame de cámara (plano Y de YUV420 o grayscale de BGRA).
  Future<Map<String, dynamic>> predictFromCamera(
    Uint8List yPlane,
    int width,
    int height,
    int bytesPerRow,
    int rotationDegrees,
  ) async {
    return {
      'success': false,
      'error': 'Inferencia TFLite local offline no soportada en la Web.'
    };
  }

  void close() {
    // No hace nada en la web
  }
}

TfliteClassifier createClassifier() => TfliteClassifier();
