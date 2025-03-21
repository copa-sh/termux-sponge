#!/bin/bash
# Script para grabación continua de audio en Termux

# Verifica si Termux-API está instalado, si no, lo instala
if ! command -v termux-microphone-record &> /dev/null; then
    echo "Instalando dependencias..."
    pkg update -y
    pkg install -y termux-api coreutils
fi

# Asegurar permisos de almacenamiento
termux-setup-storage

# Directorio donde se guardarán las grabaciones
DEST_DIR="/storage/emulated/0/Sponge"
mkdir -p "$DEST_DIR"

while true; do
    # Genera un nombre de archivo basado en la fecha y hora actual
    FILENAME="$DEST_DIR/audio_$(date +'%Y%m%d_%H%M%S').wav"

    # Notificación de inicio
    termux-notification --id "audio_recording" --title "Grabación en curso" --content "Grabando: $FILENAME (30 min)" --priority high

    echo "Grabando: $FILENAME (30 minutos)..."
    
    # Graba 1800 segundos (30 minutos) y guarda en el archivo generado
    timeout 1800 termux-microphone-record -d "$FILENAME"

    echo "Grabación finalizada: $FILENAME"
    
    # Notificación de fin de grabación
    termux-notification --id "audio_recording" --title "Grabación finalizada" --content "Archivo guardado: $FILENAME" --priority high

    # Pequeña pausa entre grabaciones (opcional)
    sleep 1
done
