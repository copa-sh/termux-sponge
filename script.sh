#!/bin/bash

# Verifica si Termux-API está instalado, si no, lo instala
if ! command -v termux-microphone-record &> /dev/null; then
    echo "Instalando dependencias..."
    pkg update -y
    pkg install -y termux-api coreutils
fi

# Asegurar permisos de almacenamiento
termux-setup-storage

# Directorio para la grabación temporal del fragmento actual
# (podríamos grabar directamente en ARCHIVE_DIR, pero así es más limpio por si algo falla)
TEMP_RECORD_DIR="/storage/emulated/0/SpongeTempRec"
# Directorio donde se almacenarán permanentemente todas las grabaciones
ARCHIVE_DIR="/storage/emulated/0/SpongeArchiveAll" # Nombre ligeramente cambiado para indicar que guarda todo

mkdir -p "$TEMP_RECORD_DIR"
mkdir -p "$ARCHIVE_DIR"

# Archivo de logs (lo pondremos en el directorio de archivo)
LOG_FILE="$ARCHIVE_DIR/sponge_always_archive.log"

echo "$(date) - Script de grabación y archivado continuo iniciado." | tee -a "$LOG_FILE"
echo "$(date) - Todos los fragmentos grabados se guardarán en $ARCHIVE_DIR." | tee -a "$LOG_FILE"
echo "$(date) - ADVERTENCIA: Esto podría llenar el almacenamiento con el tiempo." | tee -a "$LOG_FILE"

while true; do
    # Genera un nombre de archivo basado en la fecha y hora actual
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    TEMP_FILENAME="audio_temp_$TIMESTAMP.wav" # Nombre para el archivo temporal
    FULL_TEMP_PATH="$TEMP_RECORD_DIR/$TEMP_FILENAME"

    # Notificación de inicio de grabación (ajusta "(1 min)" si cambias el sleep)
    termux-notification --id "audio_recording" --title "Grabando y Archivando" --content "Grabando: $TEMP_FILENAME (1 min)" --priority high
    echo "$(date) - 🎙️ Iniciando grabación: $FULL_TEMP_PATH" | tee -a "$LOG_FILE"

    # Inicia la grabación en segundo plano usando -f para el archivo
    termux-microphone-record -f "$FULL_TEMP_PATH" &
    REC_PID=$! # Captura el PID del proceso de grabación

    # Espera 1 minuto (60 segundos). Puedes ajustar esto para fragmentos más largos o cortos.
    sleep 60

    echo "$(date) - ⏹️ Finalizando grabación: $FULL_TEMP_PATH" | tee -a "$LOG_FILE"
    # Intenta finalizar la grabación específica por su PID
    if ps -p $REC_PID > /dev/null; then # Verifica si el proceso aún existe
       kill -SIGINT $REC_PID
       wait $REC_PID 2>/dev/null # Espera a que termine limpiamente
    else
       echo "$(date) - Proceso de grabación $REC_PID no encontrado. Pudo haber terminado o fallado." | tee -a "$LOG_FILE"
       # Si la detención por PID falla consistentemente, podrías recurrir a pkill,
       # pero es menos preciso:
       # pkill -SIGINT -f termux-microphone-record 2>/dev/null
    fi
    sleep 2 # Pequeña pausa para asegurar que el archivo se escriba completamente
    sync    # Asegurar que los datos se escriban en disco

    # Mover el archivo al directorio de archivo permanente
    # Verifica primero si el archivo temporal fue creado correctamente
    if [ -f "$FULL_TEMP_PATH" ]; then
        ARCHIVED_FILENAME="audio_archive_$TIMESTAMP.wav" # Nombre para el archivo archivado
        FULL_ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVED_FILENAME"

        mv "$FULL_TEMP_PATH" "$FULL_ARCHIVE_PATH"
        
        if [ $? -eq 0 ]; then # Verifica si el comando mv tuvo éxito
            echo "$(date) - ✅ Archivo almacenado en: $FULL_ARCHIVE_PATH" | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_archived" --title "Grabación Archivada" --content "Guardado: $ARCHIVED_FILENAME" --priority high
        else
            echo "$(date) - ⚠️ Error al mover '$FULL_TEMP_PATH' a '$FULL_ARCHIVE_PATH'." | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_error" --title "Error de Archivado" --content "Fallo al mover: $(basename "$FULL_TEMP_PATH")" --priority high
        fi
    else
        echo "$(date) - ⚠️ Archivo temporal '$FULL_TEMP_PATH' no encontrado. La grabación pudo haber fallado." | tee -a "$LOG_FILE"
        termux-notification --id "audio_recording_error" --title "Error de Grabación" --content "Fallo al crear: $(basename "$FULL_TEMP_PATH")" --priority high
    fi
done
