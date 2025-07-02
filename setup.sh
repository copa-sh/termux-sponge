#!/bin/bash

# Script de instalación y configuración completa
# Grabaciones automáticas cada 15 minutos en Termux
# Archivo: setup_auto_recording.sh

set -e  # Salir si hay errores

echo "🎙️  Configurando grabaciones automáticas cada 15 minutos..."
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en Termux
if [ ! -d "/data/data/com.termux" ]; then
    print_error "Este script debe ejecutarse en Termux"
    exit 1
fi

# Actualizar repositorios
print_status "Actualizando repositorios de paquetes..."
pkg update -y

# Instalar dependencias necesarias
print_status "Instalando dependencias..."
pkg install -y termux-api cronie ffmpeg

print_success "Dependencias instaladas correctamente"

# Crear directorio para grabaciones
RECORD_DIR="$HOME/recordings"
print_status "Creando directorio de grabaciones: $RECORD_DIR"
mkdir -p "$RECORD_DIR"

# Crear script de grabación
SCRIPT_PATH="$HOME/auto_record.sh"
print_status "Creando script de grabación: $SCRIPT_PATH"

cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Script para grabación automática cada 15 minutos
RECORD_DIR="$HOME/recordings"
mkdir -p "$RECORD_DIR"

# Generar nombre de archivo con formato Ymd-His
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
AMR_FILE="$RECORD_DIR/${TIMESTAMP}.amr"
MP3_FILE="$RECORD_DIR/${TIMESTAMP}.mp3"

# Log simple
LOG_FILE="$RECORD_DIR/recording.log"
echo "$(date): Iniciando grabación $MP3_FILE" >> "$LOG_FILE"

# Función para limpiar archivos temporales
cleanup() {
    termux-microphone-record -q 2>/dev/null || true
    if [ -f "$AMR_FILE" ]; then
        ffmpeg -i "$AMR_FILE" "$MP3_FILE" -y -loglevel quiet
        rm "$AMR_FILE"
        echo "$(date): Grabación completada $MP3_FILE" >> "$LOG_FILE"
    fi
    exit 0
}

# Capturar señales
trap cleanup SIGINT SIGTERM EXIT

# Iniciar grabación (silencioso para cron)
termux-microphone-record -e awr_wide -f "$AMR_FILE" >/dev/null 2>&1 &
RECORD_PID=$!

# Esperar 15 minutos (900 segundos)
sleep 900

# Cleanup automático
cleanup
EOF

# Hacer ejecutable el script
chmod +x "$SCRIPT_PATH"
print_success "Script de grabación creado y configurado"

# Verificar si cron ya está configurado
print_status "Configurando crontab..."

# Crear entrada de cron temporal
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Verificar si ya existe la entrada
if grep -q "auto_record.sh" "$TEMP_CRON" 2>/dev/null; then
    print_warning "Entrada de cron ya existe, reemplazando..."
    grep -v "auto_record.sh" "$TEMP_CRON" > "${TEMP_CRON}.tmp" && mv "${TEMP_CRON}.tmp" "$TEMP_CRON"
fi

# Agregar nueva entrada de cron
echo "*/15 * * * * $SCRIPT_PATH" >> "$TEMP_CRON"

# Instalar el crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

print_success "Crontab configurado correctamente"

# Iniciar servicio cron
print_status "Iniciando servicio cron..."
pkill crond 2>/dev/null || true
sleep 2
crond

print_success "Servicio cron iniciado"

# Crear script de control
CONTROL_SCRIPT="$HOME/recording_control.sh"
print_status "Creando script de control: $CONTROL_SCRIPT"

cat > "$CONTROL_SCRIPT" << 'EOF'
#!/bin/bash

# Script de control para grabaciones automáticas

RECORD_DIR="$HOME/recordings"
LOG_FILE="$RECORD_DIR/recording.log"

case "$1" in
    status)
        echo "=== ESTADO DE GRABACIONES ==="
        if pgrep crond >/dev/null; then
            echo "✅ Servicio cron: ACTIVO"
        else
            echo "❌ Servicio cron: INACTIVO"
        fi
        
        echo ""
        echo "📋 Tareas programadas:"
        crontab -l | grep auto_record || echo "No hay tareas configuradas"
        
        echo ""
        echo "📁 Archivos de grabación:"
        ls -la "$RECORD_DIR"/*.mp3 2>/dev/null | tail -5 || echo "No hay grabaciones"
        
        echo ""
        echo "📝 Últimas entradas del log:"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "No hay logs disponibles"
        ;;
        
    start)
        echo "🟢 Iniciando grabaciones automáticas..."
        crond
        echo "Grabaciones iniciadas"
        ;;
        
    stop)
        echo "🔴 Deteniendo grabaciones automáticas..."
        pkill crond 2>/dev/null || true
        termux-microphone-record -q 2>/dev/null || true
        echo "Grabaciones detenidas"
        ;;
        
    restart)
        echo "🔄 Reiniciando grabaciones automáticas..."
        pkill crond 2>/dev/null || true
        sleep 2
        crond
        echo "Grabaciones reiniciadas"
        ;;
        
    clean)
        echo "🗑️  Limpiando grabaciones antiguas (más de 7 días)..."
        find "$RECORD_DIR" -name "*.mp3" -mtime +7 -delete 2>/dev/null || true
        echo "Limpieza completada"
        ;;
        
    test)
        echo "🧪 Ejecutando grabación de prueba (30 segundos)..."
        TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
        TEST_FILE="$RECORD_DIR/test_${TIMESTAMP}.mp3"
        termux-microphone-record -e awr_wide -f "${TEST_FILE%.mp3}.amr" &
        sleep 30
        termux-microphone-record -q
        ffmpeg -i "${TEST_FILE%.mp3}.amr" "$TEST_FILE" -y -loglevel quiet
        rm "${TEST_FILE%.mp3}.amr"
        echo "Prueba completada: $TEST_FILE"
        ;;
        
    *)
        echo "📱 Control de grabaciones automáticas"
        echo ""
        echo "Uso: $0 {status|start|stop|restart|clean|test}"
        echo ""
        echo "Comandos:"
        echo "  status   - Ver estado del sistema"
        echo "  start    - Iniciar grabaciones"
        echo "  stop     - Detener grabaciones"
        echo "  restart  - Reiniciar grabaciones"
        echo "  clean    - Limpiar grabaciones antiguas (>7 días)"
        echo "  test     - Grabación de prueba de 30 segundos"
        ;;
esac
EOF

chmod +x "$CONTROL_SCRIPT"
print_success "Script de control creado"

# Crear directorio de logs
touch "$RECORD_DIR/recording.log"

# Resumen final
echo ""
echo "=================================================="
print_success "🎉 INSTALACIÓN COMPLETADA"
echo "=================================================="
echo ""
echo "📍 Ubicación de archivos:"
echo "   • Grabaciones: $RECORD_DIR"
echo "   • Script principal: $SCRIPT_PATH"
echo "   • Script de control: $CONTROL_SCRIPT"
echo ""
echo "🎮 Comandos disponibles:"
echo "   • recording_control.sh status   - Ver estado"
echo "   • recording_control.sh start    - Iniciar"
echo "   • recording_control.sh stop     - Detener"
echo "   • recording_control.sh test     - Prueba rápida"
echo ""
echo "⏰ Las grabaciones comenzarán automáticamente cada 15 minutos"
echo "   (en los minutos: 00, 15, 30, 45 de cada hora)"
echo ""
echo "🔧 Para probar inmediatamente:"
echo "   ./recording_control.sh test"
echo ""

# Verificar permisos de micrófono
print_warning "IMPORTANTE: Asegúrate de que Termux tenga permisos de micrófono"
print_warning "Ve a Configuración > Apps > Termux > Permisos > Micrófono"

# Ejecutar una prueba rápida de estado
echo "🔍 Verificando configuración..."
sleep 2
"$CONTROL_SCRIPT" status

print_success "¡Todo listo! Las grabaciones automáticas están configuradas."
