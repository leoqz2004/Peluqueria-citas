#!/usr/bin/env bash
# Limpieza de logs: comprime los .log rotados y borra los comprimidos antiguos.
# Los logs JSON de la app (logs/peluqueria.log) ya rotan solos (10 MB, 30 dias, tope 500 MB);
# este script cubre logs/mantenimiento.log y rotaciones sueltas.
# Variables: LOG_DIR (<proyecto>/logs)  RETENCION_LOGS_DIAS (30)  MAX_MB_MANTENIMIENTO (5)
set -euo pipefail
# shellcheck source=_comun.sh
source "$(dirname "$0")/_comun.sh"

RETENCION_LOGS_DIAS="${RETENCION_LOGS_DIAS:-30}"
MAX_MB_MANTENIMIENTO="${MAX_MB_MANTENIMIENTO:-5}"
[[ "$RETENCION_LOGS_DIAS" =~ ^[0-9]+$ ]] || { echo "RETENCION_LOGS_DIAS invalido"; exit 2; }

# 1) Rota logs/mantenimiento.log cuando supera el tamano maximo
if [ -f "$LOG_MANT" ] && [ "$(stat -c %s "$LOG_MANT")" -gt $((MAX_MB_MANTENIMIENTO * 1024 * 1024)) ]; then
  rotado="$LOG_DIR/mantenimiento_$(date +%Y%m%d_%H%M%S).log"
  mv "$LOG_MANT" "$rotado"
fi
# 2) Comprime rotaciones .log con mas de 1 dia (excluye los logs activos)
while IFS= read -r f; do gzip -f "$f"; done < <(find "$LOG_DIR" -maxdepth 1 -type f -name '*_*.log' -mtime +1)
# 3) Borra comprimidos antiguos
borrados="$(find "$LOG_DIR" -maxdepth 1 -type f -name '*.gz' -mtime "+$RETENCION_LOGS_DIAS" -print -delete | wc -l)"
log LOGS "OK retencion_dias=$RETENCION_LOGS_DIAS eliminados=$borrados"
