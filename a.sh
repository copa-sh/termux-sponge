#!/bin/bash

# Script para grabar audio cada 15 minutos en formato Ymd_His.mp3

while true; do
    # Generar nombre de archivo con formato de fecha
    filename=$(date +"%Y%m%d_%H%M%S")
    
    echo "Iniciando grabación: ${filename}.mp3"
    
    # Iniciar grabación
    termux-microphone-record -e awr_wide -f "${filename}.amr" &
    
    # Esperar 15 minutos (900 segundos)
    sleep 900
    
    # Detener grabación
    termux-microphone-record -q
    
    # Esperar un poco para asegurar que se detenga
    sleep 2
    
    # Convertir a mp3
    ffmpeg -i "${filename}.amr" "${filename}.mp3"
    
    # Eliminar archivo temporal amr
    rm "${filename}.amr"
    
    echo "Grabación completada: ${filename}.mp3"
done
