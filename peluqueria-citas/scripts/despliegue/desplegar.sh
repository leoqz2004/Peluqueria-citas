#!/usr/bin/env bash
# Despliegue con Maven y rollback automatico (Linux + systemd).
#   1) pruebas + empaquetado (mvn verify)   2) respaldo previo de la BD   3) publica el JAR como "release"
#   4) reinicia el servicio                 5) espera /actuator/health = UP  6) si falla: vuelve al release anterior
# Variables: DESTINO (/opt/bella-estilo)  SERVICIO (peluqueria)  APP_URL (http://localhost:8080)
#            OMITIR_PRUEBAS=1 para saltar las pruebas  OMITIR_BACKUP=1 para saltar el respaldo  ESPERA_SEG (90)
set -euo pipefail
cd "$(dirname "$0")/../.."
DESTINO="${DESTINO:-/opt/bella-estilo}"
SERVICIO="${SERVICIO:-peluqueria}"
APP_URL="${APP_URL:-http://localhost:8080}"
ESPERA_SEG="${ESPERA_SEG:-90}"
SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO="sudo"
log() { printf '%s [DESPLIEGUE] %s\n' "$(date '+%F %T')" "$*"; }

if [ "${OMITIR_PRUEBAS:-0}" = "1" ]; then mvn -B -q -DskipTests clean package; else mvn -B -q clean verify; fi
jar="$(find target -maxdepth 1 -type f -name 'peluqueria-citas-*.jar' | head -1)"
[ -n "$jar" ] && [ -f "$jar" ] || { log "ERROR no se genero el JAR"; exit 1; }

if [ "${OMITIR_BACKUP:-0}" != "1" ]; then scripts/mantenimiento/backup_bd.sh; fi

mkdir -p "$DESTINO/releases"
release="$DESTINO/releases/peluqueria-citas-$(date +%Y%m%d_%H%M%S).jar"
cp "$jar" "$release"
anterior="$(readlink -f "$DESTINO/current.jar" 2>/dev/null || true)"
ln -sfn "$release" "$DESTINO/current.jar"
log "release publicado: $(basename "$release")"

$SUDO systemctl restart "$SERVICIO"
for ((i = 0; i < ESPERA_SEG; i += 3)); do
  if curl -fsS -m 3 "$APP_URL/actuator/health" 2>/dev/null | tr -d ' ' | grep -q '"status":"UP"'; then
    log "OK aplicacion UP"
    # conserva los 5 releases mas recientes
    find "$DESTINO/releases" -maxdepth 1 -type f -name '*.jar' -printf '%T@ %p\n' | sort -rn | tail -n +6 | cut -d' ' -f2- | xargs -r rm -f
    exit 0
  fi
  sleep 3
done

log "ERROR la aplicacion no quedo UP en ${ESPERA_SEG}s"
if [ -n "$anterior" ] && [ -f "$anterior" ]; then
  ln -sfn "$anterior" "$DESTINO/current.jar"
  $SUDO systemctl restart "$SERVICIO"
  log "ROLLBACK a $(basename "$anterior")"
fi
exit 1
