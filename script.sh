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
    echo "$(date) - Revisando grabaciones en curso..." | tee -a "$LOG_FILE"
    # Forzar finalización de cualquier grabación en curso
    pkill -SIGINT -f termux-microphone-record 2>/dev/null
    sleep 2

    # Mostrar procesos para depuración (opcional)
    echo "$(date) - Procesos activos:" | tee -a "$LOG_FILE"
    ps -ef | grep termux-microphone-record | tee -a "$LOG_FILE"

    # Genera un nombre de archivo basado en la fecha y hora actual
    FILENAME="$DEST_DIR/audio_$(date +'%Y%m%d_%H%M%S').wav"

    # Notificación de inicio
    termux-notification --id "audio_recording" --title "Grabación en curso" --content "Grabando: $FILENAME (30 min)" --priority high

    echo "$(date) - 🎙️ Iniciando grabación: $FILENAME" | tee -a "$LOG_FILE"

    # Inicia la grabación en segundo plano
    termux-microphone-record -d "$FILENAME" &

    # Espera 30 minutos mientras se graba
    sleep 1800

    echo "$(date) - ⏹️ Finalizando grabación..." | tee -a "$LOG_FILE"
    pkill -SIGINT -f termux-microphone-record 2>/dev/null
    sleep 2

    # Forzar escritura en disco
    sync

    echo "$(date) - ✅ Grabación finalizada: $FILENAME" | tee -a "$LOG_FILE"
    termux-notification --id "audio_recording" --title "Grabación finalizada" --content "Archivo guardado: $FILENAME" --priority high

    # Pequeña pausa entre grabaciones (opcional)
    sleep 1
done
