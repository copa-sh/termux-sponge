#!/bin/bash

# Script para grabar audio con termux-microphone-record
# Autor: Script generado para Termux
# Uso: ./grabar_audio.sh [duración_en_segundos] [nombre_archivo]

# Configuración por defecto
DURACION_DEFAULT=10
DIRECTORIO_GRABACIONES="$HOME/Grabaciones"
FORMATO="wav"  # Opciones: wav, m4a, 3gp
LIMITE_BITRATE=128000

# Función para mostrar ayuda
mostrar_ayuda() {
    echo "=== GRABADOR DE AUDIO TERMUX ==="
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -d, --duracion SEGUNDOS    Duración de la grabación (default: $DURACION_DEFAULT)"
    echo "  -f, --archivo NOMBRE       Nombre del archivo (sin extensión)"
    echo "  -o, --output DIRECTORIO    Directorio de salida (default: $DIRECTORIO_GRABACIONES)"
    echo "  -r, --formato FORMATO      Formato: wav, m4a, 3gp (default: $FORMATO)"
    echo "  -b, --bitrate BITRATE      Bitrate de audio (default: $LIMITE_BITRATE)"
    echo "  -i, --interactivo          Modo interactivo"
    echo "  -l, --listar              Listar grabaciones existentes"
    echo "  -h, --help                Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -d 30 -f mi_grabacion"
    echo "  $0 --interactivo"
    echo "  $0 -d 60 -f reunion -r m4a"
}

# Función para crear directorio de grabaciones
crear_directorio() {
    if [ ! -d "$DIRECTORIO_GRABACIONES" ]; then
        mkdir -p "$DIRECTORIO_GRABACIONES"
        echo "✓ Directorio creado: $DIRECTORIO_GRABACIONES"
    fi
}

# Función para generar nombre de archivo único
generar_nombre_archivo() {
    local base_name=${1:-"grabacion"}
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "${base_name}_${timestamp}"
}

# Función para validar formato
validar_formato() {
    case $1 in
        wav|m4a|3gp)
            return 0
            ;;
        *)
            echo "❌ Formato no válido: $1"
            echo "Formatos soportados: wav, m4a, 3gp"
            return 1
            ;;
    esac
}

# Función para listar grabaciones
listar_grabaciones() {
    echo "=== GRABACIONES EXISTENTES ==="
    if [ -d "$DIRECTORIO_GRABACIONES" ] && [ "$(ls -A $DIRECTORIO_GRABACIONES 2>/dev/null)" ]; then
        ls -lh "$DIRECTORIO_GRABACIONES"/*.{wav,m4a,3gp} 2>/dev/null | while read -r line; do
            echo "$line"
        done
    else
        echo "No se encontraron grabaciones en $DIRECTORIO_GRABACIONES"
    fi
}

# Función para el modo interactivo
modo_interactivo() {
    echo "=== MODO INTERACTIVO ==="
    
    # Solicitar duración
    read -p "Duración en segundos (default: $DURACION_DEFAULT): " input_duracion
    DURACION=${input_duracion:-$DURACION_DEFAULT}
    
    # Solicitar nombre
    read -p "Nombre del archivo (sin extensión): " input_nombre
    if [ -z "$input_nombre" ]; then
        NOMBRE_ARCHIVO=$(generar_nombre_archivo)
    else
        NOMBRE_ARCHIVO="$input_nombre"
    fi
    
    # Solicitar formato
    echo "Formatos disponibles: wav (default), m4a, 3gp"
    read -p "Formato: " input_formato
    FORMATO=${input_formato:-wav}
    
    if ! validar_formato "$FORMATO"; then
        exit 1
    fi
}

# Función principal de grabación
grabar_audio() {
    local duracion=$1
    local nombre_archivo=$2
    local formato=$3
    local directorio=$4
    local bitrate=$5
    
    local archivo_completo="$directorio/${nombre_archivo}.$formato"
    
    echo "=== INICIANDO GRABACIÓN ==="
    echo "📁 Directorio: $directorio"
    echo "📄 Archivo: ${nombre_archivo}.$formato"
    echo "⏱️  Duración: $duracion segundos"
    echo "🎵 Formato: $formato"
    echo "🎚️  Bitrate: $bitrate"
    echo ""
    
    # Verificar que termux-microphone-record esté disponible
    if ! command -v termux-microphone-record &> /dev/null; then
        echo "❌ Error: termux-microphone-record no está instalado"
        echo "Instálalo con: pkg install termux-api"
        exit 1
    fi
    
    # Cuenta regresiva
    for i in 3 2 1; do
        echo "Iniciando en $i..."
        sleep 1
    done
    
    echo "🔴 GRABANDO... (presiona Ctrl+C para detener manualmente)"
    
    # Ejecutar la grabación
    if termux-microphone-record -f "$archivo_completo" -l $bitrate -d $duracion; then
        echo ""
        echo "✅ Grabación completada exitosamente!"
        echo "📄 Archivo guardado: $archivo_completo"
        
        # Mostrar información del archivo
        if [ -f "$archivo_completo" ]; then
            local tamaño=$(du -h "$archivo_completo" | cut -f1)
            echo "📊 Tamaño: $tamaño"
        fi
    else
        echo ""
        echo "❌ Error durante la grabación"
        exit 1
    fi
}

# Procesar argumentos de línea de comandos
DURACION=$DURACION_DEFAULT
NOMBRE_ARCHIVO=""
INTERACTIVO=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duracion)
            DURACION="$2"
            shift 2
            ;;
        -f|--archivo)
            NOMBRE_ARCHIVO="$2"
            shift 2
            ;;
        -o|--output)
            DIRECTORIO_GRABACIONES="$2"
            shift 2
            ;;
        -r|--formato)
            FORMATO="$2"
            shift 2
            ;;
        -b|--bitrate)
            LIMITE_BITRATE="$2"
            shift 2
            ;;
        -i|--interactivo)
            INTERACTIVO=true
            shift
            ;;
        -l|--listar)
            crear_directorio
            listar_grabaciones
            exit 0
            ;;
        -h|--help)
            mostrar_ayuda
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1"
            mostrar_ayuda
            exit 1
            ;;
    esac
done

# Crear directorio de grabaciones
crear_directorio

# Modo interactivo
if [ "$INTERACTIVO" = true ]; then
    modo_interactivo
fi

# Validar formato
if ! validar_formato "$FORMATO"; then
    exit 1
fi

# Generar nombre de archivo si no se proporcionó
if [ -z "$NOMBRE_ARCHIVO" ]; then
    NOMBRE_ARCHIVO=$(generar_nombre_archivo)
fi

# Validar duración
if ! [[ "$DURACION" =~ ^[0-9]+$ ]] || [ "$DURACION" -le 0 ]; then
    echo "❌ Error: La duración debe ser un número positivo"
    exit 1
fi

# Iniciar grabación
grabar_audio "$DURACION" "$NOMBRE_ARCHIVO" "$FORMATO" "$DIRECTORIO_GRABACIONES" "$LIMITE_BITRATE"

echo ""
echo "=== GRABACIÓN FINALIZADA ==="
echo "Para reproducir: termux-media-player play '$DIRECTORIO_GRABACIONES/${NOMBRE_ARCHIVO}.$FORMATO'"
