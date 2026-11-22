#!/usr/bin/env bash
# Respaldo programado de la base de datos de Bella Estilo (MySQL o SQL Server).
# Uso:  DB_USER=... DB_PASSWORD=... ./backup_bd.sh        (o definir ENV_FILE, ver _comun.sh)
# Variables: DB_TYPE=mysql|sqlserver (mysql)  DB_NAME (peluqueria_citas)  DB_HOST (localhost)
#            DB_PORT (3306 / 1433)  RETENCION_DIAS (14)  BACKUP_DIR (<proyecto>/backups)
# Nota SQL Server: BACKUP escribe en el SERVIDOR; BACKUP_DIR debe existir ahi y ser escribible por el motor.
# La clave nunca se pasa como argumento (no aparece en `ps`): se usa MYSQL_PWD / SQLCMDPASSWORD.
set -euo pipefail
# shellcheck source=_comun.sh
source "$(dirname "$0")/_comun.sh"

DB_TYPE="${DB_TYPE:-mysql}"
DB_NAME="${DB_NAME:-peluqueria_citas}"
DB_HOST="${DB_HOST:-localhost}"
RETENCION_DIAS="${RETENCION_DIAS:-14}"

: "${DB_USER:?Definir DB_USER}"
: "${DB_PASSWORD:?Definir DB_PASSWORD}"
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { log BACKUP "ERROR nombre de BD invalido"; exit 2; }
[[ "$RETENCION_DIAS" =~ ^[0-9]+$ ]] || { log BACKUP "ERROR RETENCION_DIAS invalido"; exit 2; }

marca="$(date +%Y%m%d_%H%M%S)"
archivo=""
limpiar_parcial() { [ -n "$archivo" ] && rm -f "$archivo.tmp"; }
fallar() { log BACKUP "ERROR respaldo fallido db=$DB_NAME tipo=$DB_TYPE"; limpiar_parcial; exit 1; }
trap fallar ERR

log BACKUP "INICIO db=$DB_NAME tipo=$DB_TYPE"
case "$DB_TYPE" in
  mysql)
    archivo="$BACKUP_DIR/${DB_NAME}_${marca}.sql.gz"
    MYSQL_PWD="$DB_PASSWORD" mysqldump -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USER" \
      --single-transaction --routines --triggers --no-tablespaces "$DB_NAME" | gzip -9 > "$archivo.tmp"
    gzip -t "$archivo.tmp"                       # verifica que el comprimido no este corrupto
    mv "$archivo.tmp" "$archivo"
    ;;
  sqlserver)
    archivo="$BACKUP_DIR/${DB_NAME}_${marca}.bak"
    SQLCMDPASSWORD="$DB_PASSWORD" sqlcmd -S "${DB_HOST},${DB_PORT:-1433}" -U "$DB_USER" -C -b \
      -Q "BACKUP DATABASE [$DB_NAME] TO DISK = N'$archivo' WITH INIT, CHECKSUM"
    SQLCMDPASSWORD="$DB_PASSWORD" sqlcmd -S "${DB_HOST},${DB_PORT:-1433}" -U "$DB_USER" -C -b \
      -Q "RESTORE VERIFYONLY FROM DISK = N'$archivo' WITH CHECKSUM"
    ;;
  *) log BACKUP "ERROR DB_TYPE debe ser mysql o sqlserver"; exit 2 ;;
esac

[ -s "$archivo" ] || fallar
( cd "$BACKUP_DIR" && sha256sum "$(basename "$archivo")" > "$(basename "$archivo").sha256" )
tam="$(du -h "$archivo" | cut -f1)"

# Retencion: borra respaldos (y sus .sha256) mas antiguos que RETENCION_DIAS
borrados="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*" -mtime "+$RETENCION_DIAS" -print -delete | wc -l)"
log BACKUP "OK archivo=$(basename "$archivo") tamano=$tam retencion_dias=$RETENCION_DIAS eliminados=$borrados"
