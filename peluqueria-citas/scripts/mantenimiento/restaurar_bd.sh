#!/usr/bin/env bash
# Restaura un respaldo de MySQL (.sql.gz) sobre la base indicada. DESTRUCTIVO: pide confirmacion.
# Uso:  DB_USER=... DB_PASSWORD=... ./restaurar_bd.sh backups/peluqueria_citas_20261121_023000.sql.gz [--yes]
# SQL Server: restaurar desde SSMS (Tasks > Restore) o con
#   RESTORE DATABASE [peluqueria_citas] FROM DISK = N'ruta.bak' WITH REPLACE;
set -euo pipefail
# shellcheck source=_comun.sh
source "$(dirname "$0")/_comun.sh"

archivo="${1:-}"
DB_NAME="${DB_NAME:-peluqueria_citas}"
DB_HOST="${DB_HOST:-localhost}"
: "${DB_USER:?Definir DB_USER}"
: "${DB_PASSWORD:?Definir DB_PASSWORD}"
[ -n "$archivo" ] && [ -f "$archivo" ] || { echo "Uso: $0 <archivo.sql.gz> [--yes]"; exit 2; }
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { echo "Nombre de BD invalido"; exit 2; }

if [ "${2:-}" != "--yes" ]; then
  read -r -p "Se reemplazara el contenido de '$DB_NAME' con $archivo. Escribe SI para continuar: " r
  [ "$r" = "SI" ] || { echo "Cancelado."; exit 1; }
fi

# Integridad antes de tocar la BD
if [ -f "$archivo.sha256" ]; then ( cd "$(dirname "$archivo")" && sha256sum -c "$(basename "$archivo").sha256" ); fi
gzip -t "$archivo"

log RESTORE "INICIO db=$DB_NAME archivo=$(basename "$archivo")"
gunzip -c "$archivo" | MYSQL_PWD="$DB_PASSWORD" mysql -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USER" "$DB_NAME"
log RESTORE "OK db=$DB_NAME"
