#!/usr/bin/env bash
# Verificacion operativa (apta para cron cada 5 min): app arriba, disco libre y respaldo reciente.
# Codigo de salida 0 = todo bien; 1 = al menos una comprobacion fallo (queda en logs/mantenimiento.log).
# Variables: APP_URL (http://localhost:8080)  MIN_DISCO_LIBRE_PCT (10)  MAX_EDAD_BACKUP_HORAS (26)
#            ALERTA_WEBHOOK (opcional: URL a la que se envia un POST con el resumen si algo falla)
set -uo pipefail
# shellcheck source=_comun.sh
source "$(dirname "$0")/_comun.sh"

APP_URL="${APP_URL:-http://localhost:8080}"
MIN_DISCO_LIBRE_PCT="${MIN_DISCO_LIBRE_PCT:-10}"
MAX_EDAD_BACKUP_HORAS="${MAX_EDAD_BACKUP_HORAS:-26}"
fallos=()

# 1) Salud de la aplicacion (Actuator): debe responder {"status":"UP"}
respuesta="$(curl -fsS -m 5 "$APP_URL/actuator/health" 2>/dev/null || true)"
if ! printf '%s' "$respuesta" | tr -d ' ' | grep -q '"status":"UP"'; then
  fallos+=("app_no_responde_o_no_UP")
fi

# 2) Espacio libre en el disco de respaldos
usado="$(df -P "$BACKUP_DIR" | awk 'NR==2 {gsub("%","",$5); print $5}')"
libre=$((100 - ${usado:-100}))
[ "$libre" -ge "$MIN_DISCO_LIBRE_PCT" ] || fallos+=("disco_libre_${libre}pct")

# 3) Antiguedad del ultimo respaldo
ultimo="$(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name '*.sql.gz' -o -name '*.bak' \) -printf '%T@\n' 2>/dev/null | sort -n | tail -1)"
if [ -z "$ultimo" ]; then
  fallos+=("sin_respaldos")
else
  edad_h=$(( ($(date +%s) - ${ultimo%.*}) / 3600 ))
  [ "$edad_h" -le "$MAX_EDAD_BACKUP_HORAS" ] || fallos+=("ultimo_respaldo_hace_${edad_h}h")
fi

if [ "${#fallos[@]}" -eq 0 ]; then
  log SALUD "OK app=UP disco_libre=${libre}pct"
  exit 0
fi
resumen="${fallos[*]}"
log SALUD "ALERTA $resumen"
if [ -n "${ALERTA_WEBHOOK:-}" ]; then
  curl -fsS -m 10 -X POST -H 'Content-Type: application/json' \
    -d "{\"text\":\"Bella Estilo ALERTA: $resumen\"}" "$ALERTA_WEBHOOK" >/dev/null 2>&1 || true
fi
exit 1
