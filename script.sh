#!/bin/bash

# Verifica si Termux-API está instalado, si no, lo instala
if! command -v termux-microphone-record &> /dev/null; then
    echo "Instalando dependencias (termux-api, coreutils)..."
    pkg update -y
    pkg install -y termux-api coreutils
fi

# Asegurar permisos de almacenamiento
termux-setup-storage

# --- Configuración ---
DURATION_SECONDS=60      # Duración de cada segmento en segundos
ENCODER_TYPE="opus"      # Codificador: "opus", "aac", "amr_wb", "amr_nb"
OUTPUT_EXTENSION="opus"  # Extensión del archivo, debe coincidir con el codificador
TARGET_BITRATE="64"      # Tasa de bits en kbps (ej. para Opus)
TARGET_SAMPLERATE="24000" # Frecuencia de muestreo en Hz (ej. para Opus, 24kHz es común)
TARGET_CHANNELS="1"      # Canales: 1 para mono

# Directorios
BASE_STORAGE_PATH="/storage/emulated/0" # Ruta base del almacenamiento
TEMP_RECORD_DIR="${BASE_STORAGE_PATH}/AudioTemp_${OUTPUT_EXTENSION}"
ARCHIVE_DIR="${BASE_STORAGE_PATH}/AudioArchive_${OUTPUT_EXTENSION}"

mkdir -p "$TEMP_RECORD_DIR"
mkdir -p "$ARCHIVE_DIR"

LOG_FILE="$ARCHIVE_DIR/recording_log_${OUTPUT_EXTENSION}.log"

# Función para registrar mensajes
log_msg() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_msg "Script de grabación iniciado. Segmentos de ${DURATION_SECONDS}s. Encoder: ${ENCODER_TYPE}."
log_msg "Archivos temporales en: $TEMP_RECORD_DIR"
log_msg "Archivos archivados en: $ARCHIVE_DIR"
log_msg "ADVERTENCIA: Esto podría llenar el almacenamiento con el tiempo."

while true; do
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    TEMP_FILENAME="audio_temp_${TIMESTAMP}.${OUTPUT_EXTENSION}"
    FULL_TEMP_PATH="$TEMP_RECORD_DIR/$TEMP_FILENAME"

    termux-notification --id "audio_recording_status" \
                        --title "Grabando (${DURATION_SECONDS}s, ${ENCODER_TYPE})" \
                        --content "Archivo: $TEMP_FILENAME" \
                        --priority high

    log_msg "🎙️ Iniciando grabación: $FULL_TEMP_PATH (Dur: ${DURATION_SECONDS}s, Enc: ${ENCODER_TYPE}, ${TARGET_BITRATE}kbps, ${TARGET_SAMPLERATE}Hz, Ch: ${TARGET_CHANNELS})"

    termux-microphone-record -f "$FULL_TEMP_PATH" \
                             -l "$DURATION_SECONDS" \
                             -e "$ENCODER_TYPE" \
                             -b "$TARGET_BITRATE" \
                             -r "$TARGET_SAMPLERATE" \
                             -c "$TARGET_CHANNELS"
    
    EXIT_CODE=$?
    log_msg "⏹️ Grabación finalizada. Código de salida: $EXIT_CODE para $TEMP_FILENAME"

    # Sincronizar para asegurar que los datos se escriban en disco (mejores prácticas, aunque el impacto varía)
    sync

    if; then
        if; then # Verificar si el archivo no está vacío
            ARCHIVED_FILENAME="audio_archive_${TIMESTAMP}.${OUTPUT_EXTENSION}"
            FULL_ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVED_FILENAME"

            mv "$FULL_TEMP_PATH" "$FULL_ARCHIVE_PATH"
            
            if [ $? -eq 0 ]; then
                log_msg "✅ Archivo ${OUTPUT_EXTENSION} almacenado en: $FULL_ARCHIVE_PATH"
                termux-notification --id "audio_archived_ok" \
                                    --title "Grabación Archivada" \
                                    --content "Guardado: $ARCHIVED_FILENAME" \
                                    --priority default
            else
                log_msg "⚠️ Error al mover '$FULL_TEMP_PATH' a '$FULL_ARCHIVE_PATH'."
                termux-notification --id "audio_move_error" \
                                    --title "Error de Archivado" \
                                    --content "Fallo al mover: $(basename "$FULL_TEMP_PATH")" \
                                    --priority high
            fi
        else
            log_msg "⚠️ Archivo temporal '$FULL_TEMP_PATH' está vacío. Eliminando."
            rm "$FULL_TEMP_PATH"
            termux-notification --id "audio_empty_error" \
                                --title "Error de Grabación" \
                                --content "Archivo vacío: $(basename "$FULL_TEMP_PATH")" \
                                --priority high
        fi
    else
        log_msg "⚠️ Archivo temporal '$FULL_TEMP_PATH' no encontrado. La grabación pudo haber fallado (Código de salida: $EXIT_CODE)."
        termux-notification --id "audio_missing_error" \
                            --title "Error de Grabación" \
                            --content "Fallo al crear: $(basename "$FULL_TEMP_PATH") (Salida: $EXIT_CODE)" \
                            --priority high
    fi
    
    # Pausa opcional entre grabaciones
    sleep 1
done
