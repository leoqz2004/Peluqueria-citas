@echo off
REM Registra las tareas programadas de mantenimiento en el Programador de tareas de Windows.
REM Ejecutar UNA VEZ como Administrador (clic derecho > Ejecutar como administrador).
REM Quitar:  schtasks /Delete /TN "BellaEstilo\Backup" /F   (igual para Salud y LimpiezaLogs)
setlocal
set "DIR=%~dp0"
set "PS=powershell.exe -NoProfile -ExecutionPolicy Bypass -File"

schtasks /Create /F /TN "BellaEstilo\Backup" /SC DAILY /ST 02:30 /RL HIGHEST /TR "%PS% \"%DIR%backup_bd.ps1\""
schtasks /Create /F /TN "BellaEstilo\Salud" /SC MINUTE /MO 5 /RL HIGHEST /TR "%PS% \"%DIR%verificar_salud.ps1\""
schtasks /Create /F /TN "BellaEstilo\LimpiezaLogs" /SC WEEKLY /D SUN /ST 03:15 /RL HIGHEST /TR "%PS% \"%DIR%limpiar_logs.ps1\""

echo.
echo Tareas registradas. Verificar con:  schtasks /Query /TN "BellaEstilo\Backup"
echo Las credenciales se leen de C:\BellaEstilo\bella-estilo.env (ver docs\operacion\PLAN_MANTENIMIENTO.md).
endlocal
pause
