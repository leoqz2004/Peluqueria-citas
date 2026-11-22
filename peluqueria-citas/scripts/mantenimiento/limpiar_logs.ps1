# Limpieza de logs: rota logs\mantenimiento.log, comprime rotaciones y borra comprimidos antiguos.
# Los logs JSON de la app (logs\peluqueria.log) ya rotan solos (10 MB, 30 dias, tope 500 MB).
# Variables: RETENCION_LOGS_DIAS (30)  MAX_MB_MANTENIMIENTO (5)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_comun.ps1')

$retencion = [int](Obtener-Valor 'RETENCION_LOGS_DIAS' '30')
$maxMb     = [int](Obtener-Valor 'MAX_MB_MANTENIMIENTO' '5')

if ((Test-Path -LiteralPath $script:LogMant) -and ((Get-Item -LiteralPath $script:LogMant).Length -gt $maxMb * 1MB)) {
    Move-Item -LiteralPath $script:LogMant -Destination (Join-Path $script:LogDir ("mantenimiento_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss')))
}
# Comprime rotaciones (*_*.log) con mas de 1 dia; los logs activos no se tocan
Get-ChildItem -LiteralPath $script:LogDir -File -Filter '*_*.log' |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
    ForEach-Object {
        Compress-Archive -LiteralPath $_.FullName -DestinationPath "$($_.FullName).zip" -Force
        Remove-Item -LiteralPath $_.FullName -Force
    }
$viejos = Get-ChildItem -LiteralPath $script:LogDir -File -Filter '*.zip' |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retencion) }
$viejos | Remove-Item -Force
Escribir-Log 'LOGS' "OK retencion_dias=$retencion eliminados=$(@($viejos).Count)"
