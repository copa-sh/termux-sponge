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

# Función para detener la grabación de forma graciosa
detener_grabacion() {
    if pgrep -f termux-microphone-record > /dev/null; then
        echo "$(date) - ⚠️ Grabación en curso detectada. Enviando SIGINT para detenerla..." | tee -a "$LOG_FILE"
        pkill -SIGINT -f termux-microphone-record
        # Esperar hasta que el proceso termine
        while pgrep -f termux-microphone-record > /dev/null; do
            sleep 1
        done
        echo "$(date) - ✔️ Grabación detenida." | tee -a "$LOG_FILE"
    fi
}

while true; do
    # Intenta detener cualquier grabación en curso
    detener_grabacion

    # Genera un nombre de archivo basado en la fecha y hora actual
    FILENAME="$DEST_DIR/audio_$(date +'%Y%m%d_%H%M%S').wav"

    # Notificación de inicio
    termux-notification --id "audio_recording" --title "Grabación en curso" --content "Grabando: $FILENAME (30 min)" --priority high

    echo "$(date) - 🎙️ Iniciando grabación: $FILENAME" | tee -a "$LOG_FILE"

    # Iniciar grabación en segundo plano
    termux-microphone-record -d "$FILENAME" &

    # Dormir por 30 minutos mientras graba
    sleep 10

    echo "$(date) - ⏹️ Finalizando grabación..." | tee -a "$LOG_FILE"
    detener_grabacion

    # Forzamos la escritura en disco (opcional)
    sync

    echo "$(date) - ✅ Grabación finalizada: $FILENAME" | tee -a "$LOG_FILE"
    
    # Notificación de fin de grabación
    termux-notification --id "audio_recording" --title "Grabación finalizada" --content "Archivo guardado: $FILENAME" --priority high

    # Pequeña pausa entre grabaciones (opcional)
    sleep 1
done
