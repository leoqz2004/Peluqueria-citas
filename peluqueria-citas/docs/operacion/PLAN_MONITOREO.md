# Plan de monitoreo · Bella Estilo

Objetivo: observar el **comportamiento** (logs), el **rendimiento** (latencia, memoria, conexiones) y la **salud** (¿está arriba?, ¿responde la BD?) de la aplicación, y avisar cuando algo se sale de lo normal.

## 1. Logs estructurados con niveles
| Qué | Dónde | Detalle |
|---|---|---|
| Consola | salida estándar | formato legible para desarrollo |
| Archivo JSON | `logs/peluqueria.log` | formato *logstash* (una línea JSON por evento, con `@timestamp`, `level`, `logger_name`, `message` y `requestId`) |
| Rotación | automática | 10 MB por archivo, 30 días, tope total 500 MB (`logging.logback.rollingpolicy.*`) |
| Auditoría de seguridad | logger `SEGURIDAD` | `LOGIN_OK`, `LOGIN_FALLIDO`, `LOGIN_BLOQUEADO`, `ACCESO_DENEGADO`, `LOGOUT` (correos enmascarados) |
| Mantenimiento | logger `MANTENIMIENTO` + `logs/mantenimiento.log` | limpieza nocturna, respaldos, verificaciones |

Niveles: `ERROR` fallos que requieren atención (excepciones inesperadas), `WARN` situaciones anómalas pero controladas (login fallido, notificación que no se pudo enviar, pendientes vencidos), `INFO` hechos de negocio y operación, `DEBUG` solo diagnóstico (`LOG_LEVEL=DEBUG`).
Correlación: cada petición recibe un `requestId` (también en la cabecera `X-Request-Id`) que aparece en todas sus líneas de log.

## 2. Salud (Actuator)
| Endpoint | Acceso | Uso |
|---|---|---|
| `/actuator/health` | público, solo `{"status":"UP"}` (sin detalles) | balanceador, `verificar_salud.*`, Docker `HEALTHCHECK` |
| `/actuator/health/liveness`, `/readiness` | público | readiness incluye la BD (`db`) |
| `/actuator/prometheus`, `/actuator/metrics` | redes de confianza (`app.monitoreo.ips-permitidas`) **o** rol ADMINISTRADOR | Prometheus / revisión manual |
| `env`, `beans`, `heapdump`, `info`… | denegados (y no expuestos) | — |

> Con un proxy inverso la app ve las peticiones como `127.0.0.1`; por eso `deploy/nginx-bella-estilo.conf` bloquea `/actuator/` salvo `health`.

## 3. Herramienta de rendimiento: Prometheus + Grafana
`cd deploy && docker compose --env-file ../.env up -d --build` → Grafana en `http://localhost:3000` (dashboard **Bella Estilo – Monitoreo**, aprovisionado automáticamente) y Prometheus en `http://localhost:9090`. Alternativa sin Docker: abrir `http://localhost:8080/actuator/prometheus` con sesión de ADMINISTRADOR para ver las métricas en texto.

## 4. Métricas clave
| Métrica | Tipo | Para qué sirve |
|---|---|---|
| `http_server_requests_seconds` (p95, por estado) | tiempo de respuesta | rendimiento percibido y tasa de errores 5xx |
| `peluqueria_citas_hoy` | gauge | carga operativa del día |
| `peluqueria_citas_por_estado{estado}` | gauge | embudo de citas (PENDIENTE, CONFIRMADA…) |
| `peluqueria_notificaciones_por_estado{estado}` | gauge | cola de recordatorios; `FALLIDA` alta = problema de envío |
| `peluqueria_login_fallidos_total` / `_correctos_total` | contador | detección de fuerza bruta |
| `peluqueria_mantenimiento_notificaciones_eliminadas_total` | contador | efecto de la limpieza nocturna |
| `jvm_memory_used_bytes`, `jvm_gc_*` | JVM | memoria y recolector |
| `hikaricp_connections_*` | pool de BD | saturación de conexiones |
| `disk_free_bytes`, `process_cpu_usage` | sistema | capacidad |

## 5. Alertas (`monitoreo/alertas.yml`)
App caída 1 min · más de 20 logins fallidos en 5 min · p95 > 1 s durante 5 min · 5xx sostenidos · heap > 90 % durante 10 min · más de 10 notificaciones fallidas. Además `scripts/mantenimiento/verificar_salud.*` (cada 5 min) valida app UP, disco libre y respaldo reciente, y puede avisar a un webhook (`ALERTA_WEBHOOK`).

## 6. Responsables y revisión
- Revisión diaria del dashboard (2 min) y de `logs/mantenimiento.log`; revisión semanal de alertas disparadas y de `WARN` frecuentes.
- Ante alerta: 1) `GET /actuator/health`, 2) buscar `ERROR` por `requestId` en `logs/peluqueria.log`, 3) revisar BD y disco, 4) si persiste, restaurar según `PLAN_MANTENIMIENTO.md`.
