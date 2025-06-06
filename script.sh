#!/bin/bash

# Verifica si Termux-API está instalado, si no, lo instala
if ! command -v termux-microphone-record &> /dev/null; then
    echo "Instalando dependencias..."
    pkg update -y
    pkg install -y termux-api coreutils
fi

# Asegurar permisos de almacenamiento
termux-setup-storage

# Directorios
TEMP_RECORD_DIR="/storage/emulated/0/SpongeTempRec"
ARCHIVE_DIR="/storage/emulated/0/SpongeArchiveAll_M4A"

mkdir -p "$TEMP_RECORD_DIR"
mkdir -p "$ARCHIVE_DIR"

# Archivo de logs
LOG_FILE="$ARCHIVE_DIR/sponge_autofinish_m4a.log"

echo "$(date) - Script de grabación iniciado (modo auto-finalizado de 1 min)." | tee -a "$LOG_FILE"
echo "$(date) - Todos los fragmentos se guardarán en $ARCHIVE_DIR." | tee -a "$LOG_FILE"
echo "$(date) - ADVERTENCIA: Esto podría llenar el almacenamiento con el tiempo." | tee -a "$LOG_FILE"

while true; do
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    TEMP_FILENAME="audio_temp_$TIMESTAMP.m4a"
    FULL_TEMP_PATH="$TEMP_RECORD_DIR/$TEMP_FILENAME"

    # Notificación de inicio de grabación
    termux-notification --id "audio_recording" --title "Grabando (1 min)" --content "Grabando: $TEMP_FILENAME" --priority high
    echo "$(date) - 🎙️ Iniciando grabación de 1 minuto a: $FULL_TEMP_PATH" | tee -a "$LOG_FILE"

    # --- CAMBIO CLAVE DE LÓGICA ---
    # Se ejecuta en PRIMER PLANO con un límite de 60 segundos (-l 60).
    # El script esperará aquí hasta que termux-microphone-record finalice por sí solo.
    # Ya no se usa '&' para enviar a segundo plano.
    termux-microphone-record -f "$FULL_TEMP_PATH" -l 60
    
    # Capturamos el código de salida para depuración (0 usualmente significa éxito)
    EXIT_CODE=$?
    echo "$(date) - ⏹️ Grabación finalizada. Código de salida: $EXIT_CODE" | tee -a "$LOG_FILE"

    # Sincronizamos para asegurar que los datos se escriban en disco
    sync

    # Mover el archivo al directorio de archivo permanente
    if [ -f "$FULL_TEMP_PATH" ]; then
        ARCHIVED_FILENAME="audio_archive_$TIMESTAMP.m4a"
        FULL_ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVED_FILENAME"

        mv "$FULL_TEMP_PATH" "$FULL_ARCHIVE_PATH"
        
        if [ $? -eq 0 ]; then
            echo "$(date) - ✅ Archivo M4A almacenado en: $FULL_ARCHIVE_PATH" | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_archived" --title "Grabación Archivada" --content "Guardado: $ARCHIVED_FILENAME" --priority high
        else
            echo "$(date) - ⚠️ Error al mover '$FULL_TEMP_PATH' a '$FULL_ARCHIVE_PATH'." | tee -a "$LOG_FILE"
            termux-notification --id "audio_recording_error" --title "Error de Archivado" --content "Fallo al mover: $(basename "$FULL_TEMP_PATH")" --priority high
        fi
    else
        echo "$(date) - ⚠️ Archivo temporal M4A '$FULL_TEMP_PATH' no encontrado. La grabación pudo haber fallado." | tee -a "$LOG_FILE"
        termux-notification --id "audio_recording_error" --title "Error de Grabación" --content "Fallo al crear: $(basename "$FULL_TEMP_PATH")" --priority high
    fi
    
    # Añadimos una pequeña pausa opcional entre grabaciones
    sleep 1
done
