# Plan de mantenimiento · Bella Estilo

Objetivo: asegurar la **continuidad operativa** y la **recuperación** del sistema.

## 1. Tareas automatizadas
| Tarea | Frecuencia | Implementación | Resultado |
|---|---|---|---|
| Respaldo de la BD | diario 02:30 | `scripts/mantenimiento/backup_bd.sh` (cron) · `backup_bd.ps1` (Programador de tareas) | `backups/<bd>_<fecha>.sql.gz` o `.bak` + `.sha256`; verificado (`gzip -t` / `RESTORE VERIFYONLY`) |
| Retención de respaldos | en cada respaldo | mismo script (`RETENCION_DIAS`, 14 por defecto) | borra respaldos antiguos |
| Limpieza de notificaciones | diario 03:30 (hora Lima) | `MantenimientoScheduler` (`@Scheduled` cron) → `MantenimientoService` | elimina notificaciones ENVIADA/FALLIDA con más de 90 días (`app.mantenimiento.*`) |
| Revisión de pendientes vencidos | diario 03:30 | `MantenimientoService.revisarPendientesVencidos()` | `WARN` si hay recordatorios sin despachar |
| Despacho de recordatorios | cada 60 s | `RecordatorioScheduler` | envía notificaciones pendientes |
| Limpieza de logs | domingos 03:15 | `limpiar_logs.sh` / `.ps1` | rota y comprime `mantenimiento.log`, borra comprimidos > 30 días |
| Verificación de salud | cada 5 min | `verificar_salud.sh` / `.ps1` | app UP, disco libre ≥ 10 %, último respaldo < 26 h; alerta por webhook |

## 2. Instalación
**Linux (cron):** crear `/etc/bella-estilo/bella-estilo.env` (`chmod 600`) con `DB_USER`, `DB_PASSWORD`, `DB_TYPE`, `DB_NAME`…; ajustar `RUTA` en `scripts/mantenimiento/crontab.txt` y ejecutar `crontab scripts/mantenimiento/crontab.txt`.

**Windows (SQL Server Express):** crear `C:\BellaEstilo\bella-estilo.env` con `DB_USER`, `DB_PASSWORD`, `DB_SERVER=localhost\SQLEXPRESS`, `BACKUP_DIR=C:\BellaEstilo\backups` (carpeta con permiso de escritura para el servicio de SQL Server) y restringirlo con `icacls`. Luego ejecutar **una vez como administrador** `scripts\mantenimiento\programar_tareas.bat`.

Las credenciales nunca se escriben en los scripts ni en Git (`.env` está ignorado).

## 3. Procedimiento de restauración
1. Detener la aplicación (o ponerla en mantenimiento).
2. Elegir el respaldo (`backups/`) y comprobar su `.sha256`.
3. **MySQL:** `DB_USER=… DB_PASSWORD=… scripts/mantenimiento/restaurar_bd.sh backups/<archivo>.sql.gz` (pide escribir `SI`). **SQL Server:** SSMS › Tasks › Restore, o `RESTORE DATABASE [peluqueria_citas] FROM DISK = N'<ruta>.bak' WITH REPLACE;`
4. Iniciar la aplicación y comprobar `/actuator/health` y un inicio de sesión.
5. Registrar el incidente y la hora de recuperación.

Objetivos: **RPO** 24 h (frecuencia del respaldo), **RTO** 1 h.

## 4. Prueba de restauración
Una vez por mes restaurar el último respaldo en una BD de prueba y comprobar conteos de `cita`, `cliente` y `usuario`. Un respaldo que nunca se restauró no está probado.

## 5. Mantenimiento correctivo y evolutivo
- Dependencias: ejecutar `mvn -Psecurity …dependency-check…` (ver `docs/SEGURIDAD.md`) al menos cada mes y tras cada actualización de Spring Boot.
- Cambios de código: rama + `mvn verify` en verde antes de desplegar (`scripts/despliegue/`).
- Cambios de esquema: scripts versionados en `database/` y respaldo previo.
