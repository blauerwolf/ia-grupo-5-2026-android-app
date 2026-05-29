import os
import sys
import io
import json
from pathlib import Path
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn

import numpy as np
from PIL import Image
import tensorflow as tf

# Configuración de rutas
BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / 'assets' / 'modelo_sign_language.keras'

# Mapeo de índices a letras (0 -> A, 1 -> B, ..., 24 -> Y)
LETTERS_MAP = {i: chr(ord('A') + i) for i in range(25)}

print("=" * 60)
print(f"Cargando modelo Keras desde: {MODEL_PATH}")
if not MODEL_PATH.exists():
    print(f"ERROR: No se encontró el modelo en {MODEL_PATH}")
    print("Por favor, asegúrate de que el modelo exista en la carpeta 'assets'.")
    sys.exit(1)

try:
    model = tf.keras.models.load_model(str(MODEL_PATH))
    print("¡Modelo cargado exitosamente!")
except Exception as e:
    print(f"ERROR al cargar el modelo: {e}")
    sys.exit(1)
print("=" * 60)


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Servidor HTTP multihilo para responder múltiples peticiones concurrentemente."""
    pass


class SignLanguageRequestHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        """Maneja la petición pre-flight de CORS (común en Flutter Web)"""
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        """Ruta de salud del servidor"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self._send_cors_headers()
        self.end_headers()
        response = {
            "status": "healthy",
            "model_loaded": model is not None,
            "message": "Servidor de clasificación de Lenguaje de Señas activo."
        }
        self.wfile.write(json.dumps(response).encode('utf-8'))

    def do_POST(self):
        """Maneja el envío de frames de la cámara y retorna la clasificación"""
        if self.path != '/predict':
            self.send_response(404)
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(b'{"error": "Not Found"}')
            return

        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self.send_response(400)
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(b'{"error": "Empty body"}')
                return

            # Leer la imagen enviada en los bytes del cuerpo del POST
            image_bytes = self.rfile.read(content_length)
            
            # Preprocesamiento idéntico al de deteccion.py
            # 1. Abrir imagen usando Pillow y convertir a escala de grises
            img = Image.open(io.BytesIO(image_bytes)).convert('L')
            
            # 2. Redimensionar a 28x28 píxeles usando LANCZOS (antes ANTIALIAS)
            resample = Image.Resampling.LANCZOS
            img = img.resize((28, 28), resample)
            
            # 3. Convertir a array NumPy
            arr = np.array(img, dtype=np.float32)
            
            # 4. Asegurar rango 0-255 si ya venía normalizado
            if arr.max() <= 1.0:
                arr = arr * 255.0
                
            # 5. Normalizar al rango [0,1]
            arr = arr / 255.0
            
            # 6. Añadir dimensiones: (28,28) -> (1, 28, 28, 1)
            arr = arr.reshape(1, 28, 28, 1)

            # Inferencia
            preds = model.predict(arr, verbose=0)
            class_idx = int(np.argmax(preds, axis=1)[0])
            confidence = float(np.max(preds))
            letter = LETTERS_MAP.get(class_idx, "?")

            # Preparar respuesta JSON
            response = {
                "success": True,
                "class_idx": class_idx,
                "letter": letter,
                "confidence": confidence,
            }

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
            # Imprimir resultado en consola
            print(f"[Predicción] Letra: {letter} | Confianza: {confidence*100:.2f}% | Clase: {class_idx}")

        except Exception as e:
            print(f"Error procesando petición: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"success": False, "error": str(e)}).encode('utf-8'))


def run_server(port=5000):
    server_address = ('', port)
    httpd = ThreadedHTTPServer(server_address, SignLanguageRequestHandler)
    print(f"Servidor de inferencia corriendo en http://localhost:{port}")
    print("Presiona Ctrl+C para detener el servidor.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nDeteniendo servidor...")
        httpd.server_close()
        print("Servidor detenido.")


if __name__ == '__main__':
    port = 5000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port)
