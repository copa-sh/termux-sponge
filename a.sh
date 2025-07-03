#!/bin/bash

# Script para grabar audio cada 15 minutos en formato Ymd_His.mp3

# Detener cualquier grabación anterior al iniciar
termux-microphone-record -q

while true; do
    # Generar nombre de archivo con formato de fecha
    filename=$(date +"%Y%m%d_%H%M%S")
    
    echo "Iniciando grabación: ${filename}.mp3"
    
    # Iniciar grabación en formato wav
    termux-microphone-record -f "${filename}.wav" -r 48000 -c 1 &
    
    # Esperar 15 minutos (900 segundos)
    sleep 900
    
    # Detener grabación
    termux-microphone-record -q
    
    # Esperar un poco para asegurar que se detenga
    sleep 2
    
    echo "Grabación completada: ${filename}.mp3"
    echo "Esperando para próxima grabación..."
    echo "----------------------------------------"
done
