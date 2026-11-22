# Funciones compartidas por los scripts de mantenimiento en Windows (se cargan con . .\_comun.ps1).
# Credenciales: variables de entorno o el archivo ENV_FILE (lineas CLAVE=VALOR; por defecto C:\BellaEstilo\bella-estilo.env).
# Restringir ese archivo:  icacls C:\BellaEstilo\bella-estilo.env /inheritance:r /grant:r "%USERNAME%:R"

$script:Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$archivoEnv = if ($env:ENV_FILE) { $env:ENV_FILE } else { 'C:\BellaEstilo\bella-estilo.env' }
if (Test-Path -LiteralPath $archivoEnv) {
    foreach ($linea in Get-Content -LiteralPath $archivoEnv) {
        if ($linea -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$' -and -not $linea.TrimStart().StartsWith('#')) {
            [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2].Trim('"'), 'Process')
        }
    }
}

function Obtener-Valor([string]$Nombre, [string]$PorDefecto) {
    $v = [Environment]::GetEnvironmentVariable($Nombre, 'Process')
    if ([string]::IsNullOrWhiteSpace($v)) { return $PorDefecto } else { return $v }
}

$script:BackupDir = Obtener-Valor 'BACKUP_DIR' (Join-Path $script:Raiz 'backups')
$script:LogDir    = Obtener-Valor 'LOG_DIR'    (Join-Path $script:Raiz 'logs')
New-Item -ItemType Directory -Force -Path $script:BackupDir, $script:LogDir | Out-Null
$script:LogMant = Join-Path $script:LogDir 'mantenimiento.log'

function Escribir-Log([string]$Etiqueta, [string]$Mensaje) {
    $linea = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Etiqueta, $Mensaje
    Write-Host $linea
    Add-Content -LiteralPath $script:LogMant -Value $linea
}
