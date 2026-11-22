# Plan de despliegue · Bella Estilo

## 1. Artefacto con Maven
`mvn clean verify` ejecuta las pruebas y deja `target/peluqueria-citas-<versión>.jar` (JAR ejecutable de Spring Boot, `spring-boot-maven-plugin`). Ejecución: `java -jar peluqueria-citas-1.0.0.jar`. Requiere **Java 24** (según `pom.xml`).

## 2. Configuración por entorno
| Entorno | Perfil | Base de datos | Notas |
|---|---|---|---|
| Demo / desarrollo | `demo` (por defecto) | H2 en memoria | plantillas sin caché |
| Producción MySQL | `mysql` | MySQL 8 (`database/schema.sql`) | `COOKIE_SECURE=true` bajo HTTPS |
| Producción SQL Server | `sqlserver` | SQL Server (`database/SQLServer/`) | `DB_URL` para instancias con nombre |

Se configura solo con variables de entorno (`SPRING_PROFILES_ACTIVE`, `DB_URL`, `DB_USER`, `DB_PASSWORD`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `COOKIE_SECURE`, `LOG_DIR`, `LOG_LEVEL`, `MONITOREO_IPS`). Ver `.env.example`.

## 3. Servidor
**Opción A – Linux con systemd + nginx**
1. Usuario `bella`, carpeta `/opt/bella-estilo` (`releases/`, `logs/`), JDK 24, MySQL/SQL Server.
2. `/etc/bella-estilo/bella-estilo.env` (`chmod 600`) con las variables.
3. `deploy/peluqueria.service` → `/etc/systemd/system/`, `systemctl enable --now peluqueria`.
4. `deploy/nginx-bella-estilo.conf`: HTTPS (Let's Encrypt), proxy a `127.0.0.1:8080`, bloquea `/actuator/` salvo `health`.
5. Firewall: abrir 80/443; el 8080 solo local.

**Opción B – Docker:** `cd deploy && docker compose --env-file ../.env up -d --build` (app + Prometheus + Grafana). La imagen se construye con `Dockerfile` (compilación Maven en una etapa, JRE en otra, usuario sin privilegios, `HEALTHCHECK`).

**Opción C – Windows:** `scripts\despliegue\desplegar.ps1` publica el JAR en `C:\BellaEstilo` y lo ejecuta en segundo plano (para ejecutarlo como servicio permanente, envolver el JAR con NSSM o WinSW).

## 4. Procedimiento (automatizado)
`scripts/despliegue/desplegar.sh` (Linux) o `desplegar.ps1` (Windows):
1. `mvn clean verify` (pruebas obligatorias; `OMITIR_PRUEBAS=1` solo en emergencias).
2. Respaldo previo de la BD.
3. Publica el JAR como *release* con fecha y apunta `current.jar` a él.
4. Reinicia el servicio.
5. Espera hasta 90 s a `GET /actuator/health` = `UP`.
6. **Rollback automático** al release anterior si no queda `UP`. Se conservan los 5 últimos releases.

## 5. Verificación posterior
`/actuator/health` en `UP` · inicio de sesión de los tres roles · reservar una cita · `logs/peluqueria.log` sin `ERROR` · dashboard de Grafana con tráfico.

## 6. Observaciones levantadas y aplicadas
| Observación | Acción |
|---|---|
| Plantillas con caché desactivada en todos los entornos | caché activa por defecto; solo `demo` la desactiva |
| Sin apagado ordenado | `server.shutdown=graceful` (20 s) |
| Actuator bloqueado: imposible monitorear | `health` público sin detalles; métricas solo para redes de confianza/ADMINISTRADOR |
| Fallo de envío de notificación se perdía en silencio | ahora se registra en `WARN` |
