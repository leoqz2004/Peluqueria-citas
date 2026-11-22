# Cambios para el Proyecto Final (Semanas 15-18)

Se conservó la base del proyecto: **no se modificaron** `application-mysql.properties`, `application-sqlserver.properties`, los scripts SQL ni el modelo de datos. Los repositorios y servicios existentes solo recibieron métodos nuevos o correcciones puntuales.

## Qué se agregó (por criterio de la rúbrica)
| Criterio | Evidencia en el proyecto |
|---|---|
| Pruebas de software y seguridad | `SeguridadMonitoreoTest`, `MetricasNegocioTest`, `MantenimientoServiceTest`; pruebas Python actualizadas (`test_04`) |
| Despliegue | `docs/operacion/PLAN_DESPLIEGUE.md`, `Dockerfile`, `deploy/` (compose, systemd, nginx), `scripts/despliegue/desplegar.sh/.ps1` con rollback |
| Monitoreo | logs JSON con niveles y rotación, Actuator, métricas propias, `monitoreo/` (Prometheus, alertas, Grafana), `docs/operacion/PLAN_MONITOREO.md` |
| Mantenimiento | `scripts/mantenimiento/` (respaldo, restauración, limpieza, salud, cron / Programador de tareas), limpieza nocturna interna, `docs/operacion/PLAN_MANTENIMIENTO.md` |
| Construcción del producto | estructura ordenada, correcciones de robustez (abajo) |

## Correcciones y optimizaciones en el código
- `CitaService`: `paso-minutos <= 0` ahora falla al iniciar (antes podía producir un bucle infinito); `LocalDateTime.now()` se calcula una sola vez al listar horarios libres.
- `CatalogoService.crearEstilista`: el correo se normaliza (minúsculas, sin espacios) **antes** de comprobar duplicados (antes `Ana@x.com` y `ana@x.com` podían coexistir).
- `NotificacionService.enviar`: el fallo de envío se registra en `WARN` (antes se ignoraba en silencio).
- `RecordatorioScheduler`: registra cuántos recordatorios procesó.
- `application.properties`: caché de plantillas activa (solo `demo` la desactiva), carga por lotes de relaciones (`default_batch_fetch_size`) para evitar consultas N+1, apagado ordenado.
- `SecurityConfig`: único cambio funcional: `/actuator/health` público sin detalles; `/actuator/prometheus` y `/metrics` solo desde redes de confianza o ADMINISTRADOR; el resto sigue denegado.

## Orden de carpetas (sin cambiar código)
Guías → `docs/guias/` · plan e informe de pruebas → `docs/pruebas/` · scripts → `scripts/{pruebas,seguridad,mantenimiento,despliegue}/`. `INICIAR_BELLA_ESTILO_SQLSERVER.cmd` se queda en la raíz. Los scripts movidos se pueden ejecutar desde cualquier carpeta.

## Pendiente (requiere ejecutar en tu equipo)
1. `mvn clean verify` y confirmar que todo pasa; guardar captura de `target/site/jacoco/index.html`.
2. `scripts\seguridad\seguridad.bat` para generar los reportes de SpotBugs y Dependency-Check en `reportes_seguridad/`.
3. Levantar la app y capturar `/actuator/health`, el dashboard de Grafana y `logs/peluqueria.log`.
4. Ejecutar `backup_bd.ps1` una vez y `programar_tareas.bat` como administrador; capturar el respaldo generado y las tareas registradas.
5. Desplegar con `desplegar.ps1` (o Docker) y capturar el resultado.
6. Completar el alcance (≈ 50 % según el README: recuperar contraseña, exportar reportes…) o declarar el alcance comprometido.
