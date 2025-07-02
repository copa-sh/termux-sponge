#!/bin/bash

# Script para grabar audio cada 15 minutos en formato Ymd_His.mp3

# Función para verificar e instalar dependencias
check_dependencies() {
    echo "Verificando dependencias..."
    
    # Actualizar repositorios
    pkg update -y
    
    # Instalar dependencias necesarias
    dependencies=("termux-api" "ffmpeg")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null && ! dpkg -l | grep -q $dep; then
            echo "Instalando $dep..."
            pkg install -y $dep
        else
            echo "$dep ya está instalado"
        fi
    done
    
    # Verificar que termux-microphone-record funcione
    if ! command -v termux-microphone-record &> /dev/null; then
        echo "Error: termux-microphone-record no está disponible"
        echo "Asegúrate de tener la app Termux:API instalada desde F-Droid"
        exit 1
    fi
    
    echo "Todas las dependencias están listas"
    echo "----------------------------------------"
}

# Verificar dependencias al inicio
check_dependencies

# Detener grabación
termux-microphone-record -q

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
    
    # Eliminar archivo temporal amr si existe
    if [ -f "${filename}.amr" ]; then
        rm "${filename}.amr"
    fi
    
    echo "Grabación completada: ${filename}.mp3"
    echo "Esperando para próxima grabación..."
    echo "----------------------------------------"
done
