#!/usr/bin/env bash
# Funciones compartidas por los scripts de mantenimiento (se cargan con `source`).
# Variables (todas opcionales salvo credenciales de BD): se leen del entorno o de ENV_FILE.
#   ENV_FILE        archivo KEY=VALUE con credenciales (por defecto /etc/bella-estilo/bella-estilo.env)
#   BACKUP_DIR      carpeta de respaldos        (por defecto <proyecto>/backups)
#   LOG_DIR         carpeta de logs             (por defecto <proyecto>/logs)

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ENV_FILE="${ENV_FILE:-/etc/bella-estilo/bella-estilo.env}"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

BACKUP_DIR="${BACKUP_DIR:-$RAIZ/backups}"
LOG_DIR="${LOG_DIR:-$RAIZ/logs}"
mkdir -p "$BACKUP_DIR" "$LOG_DIR"
LOG_MANT="$LOG_DIR/mantenimiento.log"

# log <ETIQUETA> <mensaje...>  -> escribe en pantalla y en logs/mantenimiento.log
log() {
  local etiqueta="$1"; shift
  printf '%s [%s] %s\n' "$(date '+%F %T')" "$etiqueta" "$*" | tee -a "$LOG_MANT"
}
