#!/bin/bash

# ------------------------------------------------------------
# Script: ejecutar_si_no_ahorro.sh
# Descripción: Ejecuta a.sh solo si el modo ahorro de batería NO está activo.
# Compatible con múltiples dispositivos Android mediante varios métodos.
# ------------------------------------------------------------

# Ruta al script que queremos ejecutar (ajústala si es necesario)
SCRIPT_A="./a.sh"

# Variable para almacenar el estado del ahorro de batería
# 0 = Desactivado (OK para ejecutar)
# 1 = Activado (no ejecutar)
# 2 = No se pudo determinar (no ejecutar por precaución)
ahorro_activo=2

# Función para mostrar mensajes con formato
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# ------------------------------------------------------------
# MÉTODO 1: Usar 'settings' (estándar Android, requiere permiso)
# ------------------------------------------------------------
check_settings() {
    if command -v settings >/dev/null 2>&1; then
        local modo=$(settings get global low_power 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$modo" ]; then
            ahorro_activo=$modo
            log "✅ Método 1 (settings): Modo ahorro = $modo"
            return 0
        fi
    fi
    return 1
}

# ------------------------------------------------------------
# MÉTODO 2: Usar 'cmd power' (interfaz de servicios Android)
# ------------------------------------------------------------
check_cmd() {
    if command -v cmd >/dev/null 2>&1; then
        local salida=$(cmd power get-low-power-state 2>&1)
        if [[ "$salida" == *"true"* ]] || [[ "$salida" == *"1"* ]]; then
            ahorro_activo=1
        elif [[ "$salida" == *"false"* ]] || [[ "$salida" == *"0"* ]]; then
            ahorro_activo=0
        else
            return 1
        fi
        log "✅ Método 2 (cmd): Modo ahorro = $ahorro_activo"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------
# MÉTODO 3: Heurística con dumpsys (útil cuando los otros fallan)
# ------------------------------------------------------------
check_dumpsys() {
    if command -v dumpsys >/dev/null 2>&1; then
        # Verificar si está conectado a corriente (cargando)
        local cargando=$(dumpsys battery 2>/dev/null | grep "AC powered" | grep -c "true")
        if [ "$cargando" -gt 0 ]; then
            # Si está cargando, el sistema suele desactivar ahorro automáticamente
            ahorro_activo=0
            log "✅ Método 3 (dumpsys): Cargando batería. Se asume ahorro DESACTIVADO."
            return 0
        else
            # Si no carga, no podemos estar seguros
            log "⚠️ Método 3 (dumpsys): No conectado a corriente. Estado incierto."
            ahorro_activo=2
            return 0  # Consideramos éxito pero sin certeza
        fi
    fi
    return 1
}

# ------------------------------------------------------------
# INICIO DEL SCRIPT
# ------------------------------------------------------------
log "🔍 Verificando estado del modo ahorro de batería..."

# Intentar métodos en orden de precisión
if check_settings; then
    : # Éxito
elif check_cmd; then
    : # Éxito
elif check_dumpsys; then
    : # Éxito (aunque posiblemente incierto)
else
    log "❌ No se pudo detectar el estado del modo ahorro en este dispositivo."
    log "   Por seguridad, NO se ejecutará $SCRIPT_A."
    exit 1
fi

# Decisión final
if [ "$ahorro_activo" -eq 0 ]; then
    log "⚡ Modo ahorro DESACTIVADO. Ejecutando $SCRIPT_A..."
    if [ -f "$SCRIPT_A" ] && [ -x "$SCRIPT_A" ]; then
        "$SCRIPT_A"
        log "✅ $SCRIPT_A ejecutado correctamente."
    else
        log "❌ Error: $SCRIPT_A no existe o no es ejecutable."
        exit 2
    fi
elif [ "$ahorro_activo" -eq 1 ]; then
    log "🔋 Modo ahorro ACTIVADO. No se ejecutará $SCRIPT_A para conservar batería."
else
    log "⚠️  No se pudo determinar con certeza el estado del ahorro."
    log "   Por precaución, NO se ejecutará $SCRIPT_A."
    exit 3
fi