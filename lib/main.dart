import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle para assets
import 'package:camera/camera.dart';
import 'tflite_classifier.dart'; // Importación condicional para soporte Web/Desktop/Móvil

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtener la lista de cámaras disponibles antes de iniciar la app
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error inicializando cámaras: $e');
  }

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detección de Lenguaje de Señas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0A15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF9B51E0),
          surface: Color(0xFF181528),
          background: Color(0xFF0C0A15),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          bodyMedium: TextStyle(color: Color(0xFFB3B0C7)),
        ),
      ),
      home: SignLanguageScreen(cameras: cameras),
    );
  }
}

class SignLanguageScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SignLanguageScreen({super.key, required this.cameras});

  @override
  State<SignLanguageScreen> createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  
  // Parámetros de Calibración
  double _cropFraction = 0.5;
  bool _mirrorHorizontal = false; // Espejado desactivado por defecto
  bool _contrastStretch = false;

  // Clasificador TFLite Condicional
  TfliteClassifier? _tfliteClassifier;
  bool _isTfliteModelLoaded = false;

  // Resultados de Predicción
  String _detectedLetter = '-';
  double _confidence = 0.0;
  String _statusMessage = 'Iniciando...';
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTflite();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tfliteClassifier?.close();
    super.dispose();
  }

  // Inicializa el clasificador TFLite offline nativo
  Future<void> _initializeTflite() async {
    try {
      setState(() {
        _statusMessage = 'Cargando motor offline...';
      });
      
      _tfliteClassifier = getClassifier();
      
      if (!_tfliteClassifier!.isSupported) {
        setState(() {
          _isTfliteModelLoaded = false;
          _statusMessage = 'TFLite no soportado en esta plataforma (Web).';
        });
        return;
      }
      
      await _tfliteClassifier!.initialize();
      
      if (mounted) {
        _tfliteClassifier!.cropFraction = _cropFraction;
        _tfliteClassifier!.mirrorHorizontal = _mirrorHorizontal;
        _tfliteClassifier!.contrastStretch = _contrastStretch;
      }
      
      setState(() {
        _isTfliteModelLoaded = _tfliteClassifier!.isLoaded;
        _statusMessage = _isTfliteModelLoaded ? 'TFLite local activo' : 'Error al cargar TFLite';
      });
    } catch (e) {
      debugPrint('Error cargando TFLite nativo: $e');
      setState(() {
        _isTfliteModelLoaded = false;
        _statusMessage = 'Error al inicializar TFLite';
      });
    }
  }

  // Inicializa la cámara principal
  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _statusMessage = 'No se detectaron cámaras';
      });
      return;
    }

    CameraDescription selectedCamera = widget.cameras.first;
    for (var camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Cámara lista';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error de cámara: $e';
        });
      }
    }
  }

  /// Captura una foto y realiza la inferencia TFLite offline de manera asíncrona.
  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (!_isTfliteModelLoaded || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturando imagen...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Analizando seña...';
      });

      final result = await _tfliteClassifier!.predict(bytes);
      if (result['success'] == true && mounted) {
        final double conf = (result['confidence'] as double?) ?? 0.0;
        setState(() {
          _detectedLetter = result['letter'] ?? '-';
          _confidence = conf;
          _statusMessage = 'Inferencia finalizada';
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = result['error'] ?? 'Error en predicción';
        });
      }
    } catch (e) {
      debugPrint('[Capture] Error al capturar y analizar: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error de captura: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Prueba el modelo directamente con uno de los PNG de referencia del asset bundle.
  /// Permite verificar que el pipeline Dart reproduce los resultados de deteccion.py
  /// sin involucrar la cámara. Si Python detecta A con letra_a.png y Flutter también,
  /// el pipeline base es correcto; si difieren, hay un bug de preprocesamiento.
  Future<void> _testWithAsset(String assetPath) async {
    if (!_isTfliteModelLoaded || _isProcessing) return;
    setState(() { _isProcessing = true; });
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      debugPrint('[Test] Probando con asset: $assetPath (${bytes.lengthInBytes} bytes)');
      final result = await _tfliteClassifier!.predict(bytes);
      if (result['success'] == true && mounted) {
        final double conf = (result['confidence'] as double?) ?? 0.0;
        setState(() {
          _detectedLetter = result['letter'] ?? '-';
          _confidence = conf;
          _statusMessage = 'Test asset: $assetPath';
        });
        debugPrint('[Test] Resultado: letra=${result["letter"]} conf=${(conf*100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      debugPrint('[Test] Error al probar asset: $e');
      if (mounted) setState(() { _statusMessage = 'Error al leer asset: $e'; });
    } finally {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }

  // Retorna un color degradado según el nivel de confianza
  Color _getConfidenceColor(double conf) {
    if (conf >= 0.75) return const Color(0xFF00FF87); // Emerald Neon Green
    if (conf >= 0.40) return const Color(0xFFFFB300); // Amber Yellow
    return const Color(0xFFFF2E93); // Pinkish Red
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0914),
              Color(0xFF140F27),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Premium libre de desbordes horizontales
                _buildHeader(),
                const SizedBox(height: 15),

                // Contenido Principal
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Lado Izquierdo: Cámara
                            Expanded(flex: 3, child: _buildCameraContainer(isDesktop)),
                            const SizedBox(width: 20),
                            // Lado Derecho: Resultados y Controles
                            Expanded(flex: 2, child: _buildControlPanel(isDesktop)),
                          ],
                        )
                      : Column(
                          children: [
                            // Superior: Cámara
                            Expanded(flex: 3, child: _buildCameraContainer(isDesktop)),
                            const SizedBox(height: 20),
                            // Inferior: Resultados
                            Expanded(flex: 2, child: _buildControlPanel(isDesktop)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drawer lateral con configuración
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF181528),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1B33), Color(0xFF141223)],
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0x1A00F2FE), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FE).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF00F2FE),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Configuración',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign Language AI · TFLite Offline',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sección: Información del grupo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'INFORMACIÓN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            // Tile de Grupo 5
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF9B51E0).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B51E0).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: Color(0xFF9B51E0),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Grupo 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'UTN FRLP · IA 2026',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const SizedBox(height: 12),

            // Sección: Calibración de Cámara
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CALIBRACIÓN DE CÁMARA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            // Contenedor de Calibración
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Espejado Horizontal Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flip_rounded,
                            color: _mirrorHorizontal ? const Color(0xFF00F2FE) : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Espejar Cámara',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Switch(
                        value: _mirrorHorizontal,
                        activeColor: const Color(0xFF00F2FE),
                        onChanged: (val) {
                          setState(() {
                            _mirrorHorizontal = val;
                            _tfliteClassifier?.mirrorHorizontal = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 12),

                  // Contraste Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tonality_rounded,
                            color: _contrastStretch ? const Color(0xFF00F2FE) : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Contraste Adaptativo',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Switch(
                        value: _contrastStretch,
                        activeColor: const Color(0xFF00F2FE),
                        onChanged: (val) {
                          setState(() {
                            _contrastStretch = val;
                            _tfliteClassifier?.contrastStretch = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 12),

                  // Slider para Fracción de Recorte
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.crop_free_rounded,
                                color: const Color(0xFF00F2FE).withOpacity(0.8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Área de Enfoque (Crop)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          Text(
                            '${(_cropFraction * 100).round()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF00F2FE),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFF00F2FE),
                          overlayColor: const Color(0xFF00F2FE).withOpacity(0.2),
                          trackHeight: 3.0,
                        ),
                        child: Slider(
                          value: _cropFraction,
                          min: 0.20,
                          max: 1.0,
                          divisions: 16,
                          onChanged: (val) {
                            setState(() {
                              _cropFraction = val;
                              _tfliteClassifier?.cropFraction = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer del Drawer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'UTN FRLP · IA 2026',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botón de menú (hamburguesa) para abrir el Drawer
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B33),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00F2FE).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF00F2FE),
              size: 22,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Título centrado / expandido
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.gesture_rounded,
                    color: Color(0xFF00F2FE),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Detección de Lenguaje de Señas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 360 ? 18 : 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0x3300F2FE),
                            blurRadius: 10,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Motor TFLite Nativo (100% Offline)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF8B88A5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Indicador de Estado del Motor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isTfliteModelLoaded
                ? const Color(0x1100FF87)
                : const Color(0x11FF2E93),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isTfliteModelLoaded
                  ? const Color(0xFF00FF87).withOpacity(0.3)
                  : const Color(0xFFFF2E93).withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isTfliteModelLoaded
                      ? const Color(0xFF00FF87)
                      : const Color(0xFFFF2E93),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isTfliteModelLoaded
                          ? const Color(0xFF00FF87).withOpacity(0.6)
                          : const Color(0xFFFF2E93).withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isTfliteModelLoaded ? 'OFFLINE OK' : 'CARGANDO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _isTfliteModelLoaded
                      ? const Color(0xFF00FF87)
                      : const Color(0xFFFF2E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraContainer(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerWidth = constraints.maxWidth;
        final double containerHeight = constraints.maxHeight;
        final double fullSide = containerWidth < containerHeight ? containerWidth : containerHeight;
        final double boxSize = fullSide * _cropFraction;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141223),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00F2FE).withOpacity(0.15),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Feed de la cámara o pantalla de carga con ClipRRect para esquinas perfectas
              if (_isCameraInitialized && _cameraController != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Center(
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF00F2FE),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Inicializando Cámara...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Capa de Procesando (Solo visible durante la captura e inferencia)
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF9B51E0),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Analizando Seña...',
                          style: TextStyle(
                            color: Color(0xFF9B51E0),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // HUD de Caja de Enfoque de Mano (Guía visual para el usuario)
              // El cuadro representa el _cropFraction central del frame que el modelo analiza.
              if (_isCameraInitialized && _isTfliteModelLoaded)
                Center(
                  child: Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00F2FE).withOpacity(0.6),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withOpacity(0.08),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Text(
                            'POSICIONAR MANO AQUÍ',
                            style: TextStyle(
                              fontSize: boxSize > 120 ? 8 : 6,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00F2FE).withOpacity(0.8),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Text(
                            'LLENAR EL CUADRO',
                            style: TextStyle(
                              fontSize: boxSize > 120 ? 7 : 5,
                              color: const Color(0xFF00F2FE).withOpacity(0.55),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Indicador de Estado del Sistema en la esquina inferior izquierda
              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_bolt,
                        color: Color(0xFF00F2FE),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlPanel(bool isDesktop) {
    final resultCard = _buildResultCard(isDesktop);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141223),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Resultados Glassmorphic (con altura fija y robusta para evitar desbordes/superposiciones)
            SizedBox(
              height: isDesktop ? 240 : 160,
              child: resultCard,
            ),
            const SizedBox(height: 15),

            // Botón de Disparo Manual
            ElevatedButton(
              onPressed: _isTfliteModelLoaded && !_isProcessing ? _captureAndAnalyze : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F2FE),
                foregroundColor: Colors.black,
                shadowColor: const Color(0xFF00F2FE).withOpacity(0.4),
                elevation: 8,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined),
                  SizedBox(width: 8),
                  Text(
                    'CAPTURAR Y ANALIZAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Botones de prueba directa con los PNG de referencia
            // Equivalente a ejecutar deteccion.py con letra_a.png / letra_u.png
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTfliteModelLoaded && !_isProcessing
                        ? () => _testWithAsset('assets/letra_a.png')
                        : null,
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text(
                      'TEST A',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF87),
                      side: const BorderSide(color: Color(0xFF00FF87), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTfliteModelLoaded && !_isProcessing
                        ? () => _testWithAsset('assets/letra_u.png')
                        : null,
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text(
                      'TEST U',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF87),
                      side: const BorderSide(color: Color(0xFF00FF87), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isDesktop) {
    final confColor = _getConfidenceColor(_confidence);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'LETRA ESTIMADA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 5),
          
          // Letra Gigante (FittedBox para evitar desbordes en celulares)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _detectedLetter,
                    style: TextStyle(
                      fontSize: isDesktop ? 120 : 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: confColor.withOpacity(0.4),
                          blurRadius: 25,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),

          // Barra de Confianza Estilizada 100% Responsiva
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONFIANZA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    Text(
                      '${(_confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: confColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            width: constraints.maxWidth * _confidence,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  confColor.withOpacity(0.6),
                                  confColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: confColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
