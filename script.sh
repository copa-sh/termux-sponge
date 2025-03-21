#!/bin/bash

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

# Archivo de logs
LOG_FILE="$DEST_DIR/sponge.log"

while true; do
    # Detener cualquier grabación en curso antes de iniciar una nueva
    if pgrep -f termux-microphone-record > /dev/null; then
        echo "$(date) - ⚠️ Grabación en curso detectada. Terminándola..." | tee -a "$LOG_FILE"
        pkill -f termux-microphone-record
        sleep 2
    fi

    # Genera un nombre de archivo basado en la fecha y hora actual
    FILENAME="$DEST_DIR/$(date +'%Y%m%d_%H%M%S').wav"

    # Notificación de inicio
    termux-notification --id "audio_recording" --title "Grabación en curso" --content "Grabando: $FILENAME (30 min)" --priority high

    echo "$(date) - 🎙️ Iniciando grabación: $FILENAME" | tee -a "$LOG_FILE"

    # Iniciar grabación en segundo plano
    termux-microphone-record -d "$FILENAME" &

    # Dormir por 10 segundos mientras graba
    sleep 10

    # Terminar la grabación después de 30 minutos
    echo "$(date) - ⏹️ Deteniendo grabación..." | tee -a "$LOG_FILE"
    pkill -f termux-microphone-record

    echo "$(date) - ✅ Grabación finalizada: $FILENAME" | tee -a "$LOG_FILE"
    
    # Notificación de fin de grabación
    termux-notification --id "audio_recording" --title "Grabación finalizada" --content "Archivo guardado: $FILENAME" --priority high

    # Pequeña pausa entre grabaciones (opcional)
    sleep 1
done
