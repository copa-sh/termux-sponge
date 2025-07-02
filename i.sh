#!/bin/bash

echo "🚀 Verificando e instalando todas las dependencias..."
echo ""

# 1. Actualizar repositorios de Termux
echo "🔄 Actualizando repositorios..."
pkg update -y

# 2. Instalar dependencias de sistema con pkg
# Añadimos 'python' a la lista
dependencies=("termux-api" "ffmpeg" "python")

echo ""
echo "📦 Verificando dependencias de sistema (pkg)..."
for dep in "${dependencies[@]}"; do
    if ! command -v $dep &> /dev/null; then
        echo "   -> Instalando $dep..."
        pkg install -y $dep
    else
        echo "   -> $dep ya está instalado."
    fi
done

# 3. Instalar dependencias de Python con pip
echo ""
echo "🐍 Verificando dependencias de Python (pip)..."
if command -v pip &> /dev/null; then
    if ! python -c "import flask" &> /dev/null; then
        echo "   -> Instalando Flask..."
        pip install Flask
    else
        echo "   -> Flask ya está instalado."
    fi
else
    echo "   -> ⚠️ Error: No se encontró 'pip'. Asegúrate de que Python se instaló correctamente."
    exit 1
fi

# 4. Verificar comando de grabación de Termux
echo ""
if ! command -v termux-microphone-record &> /dev/null; then
    echo "   -> ⚠️ Error: termux-microphone-record no está disponible."
    echo "   Asegúrate de tener la app Termux:API instalada desde F-Droid y de darle permisos."
    exit 1
fi

echo ""
echo "✅ ¡Todo listo! Todas las dependencias están instaladas."
echo "----------------------------------------------------"
