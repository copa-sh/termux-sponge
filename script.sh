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
TEMP_RECORD_DIR="/storage/emulated/0/SpongeTempRec"
# Directorio donde se almacenarán permanentemente todas las grabaciones (ahora M4A)
ARCHIVE_DIR="/storage/emulated/0/SpongeArchiveAll_M4A" # Directorio de archivo para M4A

mkdir -p "$TEMP_RECORD_DIR"
mkdir -p "$ARCHIVE_DIR"

# Archivo de logs (lo pondremos en el directorio de archivo)
LOG_FILE="$ARCHIVE_DIR/sponge_always_archive_m4a.log" # Log para M4A

echo "$(date) - Script de grabación y archivado continuo iniciado (formato M4A)." | tee -a "$LOG_FILE"
echo "$(date) - Todos los fragmentos grabados se guardarán en $ARCHIVE_DIR." | tee -a "$LOG_FILE"
echo "$(date) - ADVERTENCIA: Esto podría llenar el almacenamiento con el tiempo." | tee -a "$LOG_FILE"

while true; do
    # Genera un nombre de archivo basado en la fecha y hora actual
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    # CAMBIO: Extensión de archivo a .m4a
    TEMP_FILENAME="audio_temp_$TIMESTAMP.m4a"
    FULL_TEMP_PATH="$TEMP_RECORD_DIR/$TEMP_FILENAME"

    # Notificación de inicio de grabación (ajusta "(1 min)" si cambias el sleep)
    # CAMBIO: Título y contenido de notificación
    termux-notification --id "audio_recording" --title "Grabando y Archivando (M4A)" --content "Grabando: $TEMP_FILENAME (1 min)" --priority high
    # CAMBIO: Mensaje de log
    echo "$(date) - 🎙️ Iniciando grabación (M4A): $FULL_TEMP_PATH" | tee -a "$LOG_FILE"

    # Inicia la grabación en segundo plano usando -f para el archivo
    termux-microphone-record -f "$FULL_TEMP_PATH" &
    REC_PID=$! # Captura el PID del proceso de grabación

    # Espera 1 minuto (60 segundos). Puedes ajustar esto.
    sleep 60

    # CAMBIO: Mensaje de log
    echo "$(date) - ⏹️ Finalizando grabación (M4A): $FULL_TEMP_PATH" | tee -a "$LOG_FILE"
    # Intenta finalizar la grabación específica por su PID
    if ps -p $REC_PID > /dev/null; then
       kill -SIGINT $REC_PID
       wait $REC_PID 2>/dev/null
    else
       echo "$(date) - Proceso de grabación $REC_PID no encontrado. Pudo haber terminado o fallado." | tee -a "$LOG_FILE"
    fi
    sleep 2
    sync

    # Mover el archivo al directorio de archivo permanente
    if [ -f "$FULL_TEMP_PATH" ]; then
        # CAMBIO: Extensión de archivo archivado a .m4a
        ARCHIVED_FILENAME="audio_archive_$TIMESTAMP.m4a"
        FULL_ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVED_FILENAME"

        mv "$FULL_TEMP_PATH" "$FULL_ARCHIVE_PATH"
        
        if [ $? -eq 0 ]; then
            # CAMBIO: Mensaje de log y notificación
            echo "$(date) - ✅ Archivo M4A almacenado en: $FULL_ARCHIVE_PATH" | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_archived" --title "Grabación M4A Archivada" --content "Guardado: $ARCHIVED_FILENAME" --priority high
        else
            echo "$(date) - ⚠️ Error al mover '$FULL_TEMP_PATH' a '$FULL_ARCHIVE_PATH'." | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_error" --title "Error de Archivado (M4A)" --content "Fallo al mover: $(basename "$FULL_TEMP_PATH")" --priority high
        fi
    else
        # CAMBIO: Mensaje de log y notificación
        echo "$(date) - ⚠️ Archivo temporal M4A '$FULL_TEMP_PATH' no encontrado. La grabación pudo haber fallado." | tee -a "$LOG_FILE"
        termux-notification --id "audio_recording_error" --title "Error de Grabación (M4A)" --content "Fallo al crear: $(basename "$FULL_TEMP_PATH")" --priority high
    fi
done
