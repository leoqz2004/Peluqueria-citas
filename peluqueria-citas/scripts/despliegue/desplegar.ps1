# Despliegue en Windows (servidor local o equipo de pruebas) con Maven y rollback.
#   1) mvn verify  2) respaldo previo  3) copia el JAR a releases\  4) reinicia la app  5) espera /actuator/health = UP
#   6) si falla vuelve al JAR anterior.
# Variables: DESTINO (C:\BellaEstilo)  APP_URL (http://localhost:8080)  OMITIR_PRUEBAS=1  OMITIR_BACKUP=1  ESPERA_SEG (90)
# La app corre en segundo plano con java -jar; credenciales y perfil se leen de C:\BellaEstilo\bella-estilo.env.
# Para correrla como servicio de Windows de forma permanente se puede usar NSSM o WinSW sobre este mismo JAR.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..\..')
function Valor($n, $d) { $v = [Environment]::GetEnvironmentVariable($n); if ([string]::IsNullOrWhiteSpace($v)) { $d } else { $v } }
function Log($m) { Write-Host ('{0} [DESPLIEGUE] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) }

$destino = Valor 'DESTINO' 'C:\BellaEstilo'
$url     = Valor 'APP_URL' 'http://localhost:8080'
$espera  = [int](Valor 'ESPERA_SEG' '90')
$pidFile = Join-Path $destino 'app.pid'
New-Item -ItemType Directory -Force -Path (Join-Path $destino 'releases'), (Join-Path $destino 'logs') | Out-Null

if ($env:OMITIR_PRUEBAS -eq '1') { & mvn -B -q -DskipTests clean package } else { & mvn -B -q clean verify }
if ($LASTEXITCODE -ne 0) { Log 'ERROR Maven fallo'; exit 1 }
$jar = Get-ChildItem target -Filter 'peluqueria-citas-*.jar' | Where-Object { $_.Name -notlike '*.original' } | Select-Object -First 1
if (-not $jar) { Log 'ERROR no se genero el JAR'; exit 1 }

if ($env:OMITIR_BACKUP -ne '1') { & (Join-Path $PSScriptRoot '..\mantenimiento\backup_bd.ps1'); if ($LASTEXITCODE -ne 0) { Log 'ERROR respaldo previo fallo'; exit 1 } }

$actual = Join-Path $destino 'current.jar'
$anterior = $null
if (Test-Path $actual) { $anterior = Join-Path $destino ('releases\anterior_{0}.jar' -f (Get-Date -Format 'yyyyMMdd_HHmmss')); Copy-Item $actual $anterior }
$release = Join-Path $destino ('releases\peluqueria-citas-{0}.jar' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
Copy-Item $jar.FullName $release

function Detener { if (Test-Path $pidFile) { Stop-Process -Id ([int](Get-Content $pidFile)) -ErrorAction SilentlyContinue; Remove-Item $pidFile -Force } }
function Iniciar($archivo) {
    Copy-Item $archivo $actual -Force
    $envFile = Valor 'ENV_FILE' (Join-Path $destino 'bella-estilo.env')
    if (Test-Path $envFile) {
        foreach ($l in Get-Content $envFile) { if ($l -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2].Trim('"'), 'Process') } }
    }
    $env:LOG_DIR = Join-Path $destino 'logs'
    $p = Start-Process java -ArgumentList '-jar', "`"$actual`"" -WorkingDirectory $destino -WindowStyle Hidden -PassThru `
         -RedirectStandardOutput (Join-Path $destino 'logs\consola.out.log') -RedirectStandardError (Join-Path $destino 'logs\consola.err.log')
    Set-Content $pidFile $p.Id
}
function Esta-Arriba {
    for ($i = 0; $i -lt $espera; $i += 3) {
        try { if ((Invoke-RestMethod -Uri "$url/actuator/health" -TimeoutSec 3).status -eq 'UP') { return $true } } catch { }
        Start-Sleep -Seconds 3
    }
    return $false
}

Detener
Iniciar $release
if (Esta-Arriba) {
    Log 'OK aplicacion UP'
    Get-ChildItem (Join-Path $destino 'releases') -Filter '*.jar' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 6 | Remove-Item -Force
    exit 0
}
Log "ERROR la aplicacion no quedo UP en ${espera}s"
Detener
if ($anterior) { Iniciar $anterior; Log "ROLLBACK a $(Split-Path $anterior -Leaf)" }
exit 1
