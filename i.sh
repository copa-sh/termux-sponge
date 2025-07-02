#!/bin/bash

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
