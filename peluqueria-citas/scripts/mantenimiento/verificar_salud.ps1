# Verificacion operativa (cada 5 min con el Programador de tareas): app arriba, disco libre y respaldo reciente.
# Salida 0 = todo bien; 1 = alguna comprobacion fallo (queda en logs\mantenimiento.log).
# Variables: APP_URL (http://localhost:8080)  MIN_DISCO_LIBRE_PCT (10)  MAX_EDAD_BACKUP_HORAS (26)
#            ALERTA_WEBHOOK (opcional)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_comun.ps1')

$url      = Obtener-Valor 'APP_URL' 'http://localhost:8080'
$minLibre = [int](Obtener-Valor 'MIN_DISCO_LIBRE_PCT' '10')
$maxHoras = [int](Obtener-Valor 'MAX_EDAD_BACKUP_HORAS' '26')
$fallos   = @()

try {
    $resp = Invoke-RestMethod -Uri "$url/actuator/health" -TimeoutSec 5
    if ($resp.status -ne 'UP') { $fallos += "app_estado_$($resp.status)" }
} catch { $fallos += 'app_no_responde' }

$unidad = (Get-Item -LiteralPath $script:BackupDir).PSDrive
$libre  = [int][math]::Round(100 * $unidad.Free / ($unidad.Free + $unidad.Used))
if ($libre -lt $minLibre) { $fallos += "disco_libre_${libre}pct" }

$ultimo = Get-ChildItem -LiteralPath $script:BackupDir -File |
    Where-Object { $_.Name -match '\.(bak|sql|gz)$' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $ultimo) { $fallos += 'sin_respaldos' }
else {
    $edad = [int]((Get-Date) - $ultimo.LastWriteTime).TotalHours
    if ($edad -gt $maxHoras) { $fallos += "ultimo_respaldo_hace_${edad}h" }
}

if ($fallos.Count -eq 0) { Escribir-Log 'SALUD' "OK app=UP disco_libre=${libre}pct"; exit 0 }
$resumen = $fallos -join ' '
Escribir-Log 'SALUD' "ALERTA $resumen"
$hook = Obtener-Valor 'ALERTA_WEBHOOK' ''
if ($hook) {
    try { Invoke-RestMethod -Uri $hook -Method Post -ContentType 'application/json' -Body (@{ text = "Bella Estilo ALERTA: $resumen" } | ConvertTo-Json) -TimeoutSec 10 | Out-Null } catch { }
}
exit 1
