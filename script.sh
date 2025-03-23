#!/bin/bash

# Verifica si Termux-API está instalado, si no, lo instala
if ! command -v termux-microphone-record &> /dev/null; then
    echo "Instalando dependencias..."
    pkg update -y
    pkg install -y termux-api coreutils
fi

# Asegurar permisos de almacenamiento
termux-setup-storage

# Directorios para grabaciones temporales y archivo
DEST_DIR="/storage/emulated/0/Sponge"
ARCHIVE_DIR="/storage/emulated/0/SpongeArchive"
mkdir -p "$DEST_DIR"
mkdir -p "$ARCHIVE_DIR"

# Archivo de logs
LOG_FILE="$DEST_DIR/sponge.log"

# Bandera para almacenar archivos
store_flag=0

# Manejador de señal SIGUSR1: cuando se reciba, se marca para almacenar la última media hora
handle_sigusr1() {
    echo "$(date) - Señal SIGUSR1 recibida: se almacenarán los archivos de los últimos 30 minutos." | tee -a "$LOG_FILE"
    store_flag=1
}
trap 'handle_sigusr1' SIGUSR1

# Lista para llevar el registro de los últimos 3 archivos (10 minutos c/u = 30 min en total)
declare -a last_files=()

while true; do
    # Genera un nombre de archivo basado en la fecha y hora actual
    FILENAME="$DEST_DIR/audio_$(date +'%Y%m%d_%H%M%S').wav"

    # Notificación de inicio de grabación
    termux-notification --id "audio_recording" --title "Grabación en curso" --content "Grabando: $FILENAME (10 min)" --priority high
    echo "$(date) - 🎙️ Iniciando grabación: $FILENAME" | tee -a "$LOG_FILE"

    # Inicia la grabación en segundo plano
    termux-microphone-record -d "$FILENAME" &
    
    # Espera 10 minutos (600 segundos)
    sleep 60

    echo "$(date) - ⏹️ Finalizando grabación: $FILENAME" | tee -a "$LOG_FILE"
    # Forzar finalización de cualquier grabación en curso
    pkill -SIGINT -f termux-microphone-record 2>/dev/null
    sleep 2
    sync
    termux-notification --id "audio_recording" --title "Grabación finalizada" --content "Archivo guardado: $FILENAME" --priority high

    # Se añade el archivo a la lista de los últimos grabados
    last_files+=("$FILENAME")
    
    # Si hay más de 3 archivos (más de 30 minutos), se elimina el más antiguo
    if [ ${#last_files[@]} -gt 30 ]; then
        echo "$(date) - Eliminando archivo antiguo: ${last_files[0]}" | tee -a "$LOG_FILE"
        rm -f "${last_files[0]}"
        # Se remueve el primer elemento del arreglo
        last_files=("${last_files[@]:1}")
    fi

    # Si se recibió la señal para almacenar, se mueven los archivos a ARCHIVE_DIR
    if [ $store_flag -eq 1 ]; then
        echo "$(date) - Almacenando los archivos de los últimos 30 minutos..." | tee -a "$LOG_FILE"
        for file in "${last_files[@]}"; do
            if [ -f "$file" ]; then
                mv "$file" "$ARCHIVE_DIR"
                echo "$(date) - Archivo almacenado: $(basename "$file")" | tee -a "$LOG_FILE"
            fi
        done
        # Se limpia la lista y se resetea la bandera
        last_files=()
        store_flag=0
    fi
done
