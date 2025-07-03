#!/usr/bin/env python3

import os, sys
import subprocess
from datetime import datetime, timedelta
from flask import Flask, request, send_file, render_template_string

app = Flask(__name__)

# Directorio donde se guardan los audios (el mismo donde se ejecuta el script)
AUDIO_DIR = '.'

# Plantilla HTML para la interfaz web
HTML_TEMPLATE = """
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Descargar Audio</title>
    <style>
        body { font-family: sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; border: 1px solid #ccc; border-radius: 10px; }
        input { width: 100px; padding: 8px; }
        button { padding: 8px 15px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Descargar Audio Reciente 🎙️</h1>
    <form action="/download" method="get">
        <label for="minutes">Últimos</label>
        <input type="number" id="minutes" name="minutes" value="30" min="1">
        <label for="minutes">minutos.</label>
        <br><br>
        <button type="submit">Generar y Descargar</button>
    </form>
</body>
</html>
"""

@app.route('/')
def index():
    """Muestra la página principal."""
    return render_template_string(HTML_TEMPLATE)

@app.route('/download')
def download_audio():
    """Encuentra, combina y sirve los archivos de audio."""
    try:
        minutes_ago = int(request.args.get('minutes', 30))
    except (ValueError, TypeError):
        return "Error: Por favor, introduce un número válido de minutos.", 400

    now = datetime.now()
    cutoff_time = now - timedelta(minutes=minutes_ago)

    # 1. Encontrar los archivos relevantes
    relevant_files = []
    try:
        all_files = sorted([f for f in os.listdir(AUDIO_DIR) if f.endswith('.wav')])
        for filename in all_files:
            # Extraer fecha del nombre de archivo (formato: YYYYMMDD_HHMMSS.wav)
            file_timestamp_str = filename.split('.')[0]
            file_time = datetime.strptime(file_timestamp_str, '%Y%m%d_%H%M%S')
            
            if file_time >= cutoff_time:
                relevant_files.append(filename)
    except Exception as e:
        return f"Error al leer los archivos de audio: {e}", 500

    if not relevant_files:
        return f"No se encontraron grabaciones de los últimos {minutes_ago} minutos.", 404

    # 2. Si solo hay un archivo, servirlo directamente
    if len(relevant_files) == 1:
        print(f"Enviando archivo único: {relevant_files[0]}")
        return send_file(os.path.join(AUDIO_DIR, relevant_files[0]), as_attachment=True)

    # 3. Combinar múltiples archivos con ffmpeg
    output_filename = f"combined_{now.strftime('%Y%m%d_%H%M%S')}.wav"
    list_filename = "concat_list.txt"

    # Crear lista de archivos para ffmpeg
    with open(list_filename, 'w') as f:
        for filename in relevant_files:
            f.write(f"file '{os.path.join(AUDIO_DIR, filename)}'\n")

    # Comando ffmpeg para concatenar sin recodificar (muy rápido)
    command = [
        'ffmpeg', '-y', '-f', 'concat', '-safe', '0', 
        '-i', list_filename, '-c', 'copy', output_filename
    ]

    print(f"Ejecutando comando: {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)
    
    # Limpiar el archivo de lista
    os.remove(list_filename)

    if result.returncode != 0:
        print("Error de FFmpeg:", result.stderr)
        return f"Error al combinar los audios con FFmpeg: <pre>{result.stderr}</pre>", 500

    print(f"Enviando archivo combinado: {output_filename}")
    return send_file(output_filename, as_attachment=True)

if __name__ == '__main__':
    # Escucha en todas las interfaces de red en el puerto 8080
    app.run(host='localhost', port=sys.argv[1] if len(sys.argv)>1 else 8080, debug=True)
