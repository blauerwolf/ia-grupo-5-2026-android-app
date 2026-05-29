import 'tflite_stub.dart';

export 'tflite_stub.dart';

// Conditionally import tflite_native.dart only when dart.library.ffi is available (Native platforms)
// On Web, it will fall back to using the stub.
import 'tflite_stub.dart'
  if (dart.library.ffi) 'tflite_native.dart' as impl;

TfliteClassifier getClassifier() {
  return impl.createClassifier();
}
