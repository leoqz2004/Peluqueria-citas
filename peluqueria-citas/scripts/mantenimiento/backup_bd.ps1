# Respaldo programado de la base de datos de Bella Estilo (SQL Server Express por defecto, o MySQL).
# Uso:  $env:DB_USER='app_citas'; $env:DB_PASSWORD='...'; .\backup_bd.ps1     (o ENV_FILE, ver _comun.ps1)
# Variables: DB_TYPE=sqlserver|mysql (sqlserver)  DB_NAME (peluqueria_citas)
#            DB_SERVER (localhost\SQLEXPRESS, solo SQL Server)  DB_HOST/DB_PORT (solo MySQL)
#            RETENCION_DIAS (14)  BACKUP_DIR (<proyecto>\backups)
# SQL Server: el archivo .bak lo escribe el SERVICIO de SQL Server; BACKUP_DIR debe existir y darle permiso de escritura
#            (ej.: C:\BellaEstilo\backups).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_comun.ps1')

$tipo      = (Obtener-Valor 'DB_TYPE' 'sqlserver').ToLower()
$bd        = Obtener-Valor 'DB_NAME' 'peluqueria_citas'
$retencion = [int](Obtener-Valor 'RETENCION_DIAS' '14')
$usuario   = $env:DB_USER
$clave     = $env:DB_PASSWORD

if ($bd -notmatch '^[A-Za-z0-9_]+$') { Escribir-Log 'BACKUP' 'ERROR nombre de BD invalido'; exit 2 }
if (-not $usuario -or -not $clave)   { Escribir-Log 'BACKUP' 'ERROR definir DB_USER y DB_PASSWORD'; exit 2 }

$marca   = Get-Date -Format 'yyyyMMdd_HHmmss'
$archivo = $null
try {
    Escribir-Log 'BACKUP' "INICIO db=$bd tipo=$tipo"
    if ($tipo -eq 'sqlserver') {
        $servidor = Obtener-Valor 'DB_SERVER' 'localhost\SQLEXPRESS'
        $archivo  = Join-Path $script:BackupDir "${bd}_$marca.bak"
        $env:SQLCMDPASSWORD = $clave          # la clave no viaja como argumento
        & sqlcmd -S $servidor -U $usuario -C -b -Q "BACKUP DATABASE [$bd] TO DISK = N'$archivo' WITH INIT, CHECKSUM"
        if ($LASTEXITCODE -ne 0) { throw 'BACKUP DATABASE fallo' }
        & sqlcmd -S $servidor -U $usuario -C -b -Q "RESTORE VERIFYONLY FROM DISK = N'$archivo' WITH CHECKSUM"
        if ($LASTEXITCODE -ne 0) { throw 'RESTORE VERIFYONLY fallo' }
    }
    elseif ($tipo -eq 'mysql') {
        $archivo = Join-Path $script:BackupDir "${bd}_$marca.sql"
        $env:MYSQL_PWD = $clave
        & mysqldump -h (Obtener-Valor 'DB_HOST' 'localhost') -P (Obtener-Valor 'DB_PORT' '3306') -u $usuario `
            --single-transaction --routines --triggers --no-tablespaces --result-file="$archivo" $bd
        if ($LASTEXITCODE -ne 0) { throw 'mysqldump fallo' }
    }
    else { Escribir-Log 'BACKUP' 'ERROR DB_TYPE debe ser sqlserver o mysql'; exit 2 }

    if (-not (Test-Path -LiteralPath $archivo) -or (Get-Item -LiteralPath $archivo).Length -eq 0) { throw 'respaldo vacio' }
    $hash = (Get-FileHash -LiteralPath $archivo -Algorithm SHA256).Hash
    Set-Content -LiteralPath "$archivo.sha256" -Value "$hash  $(Split-Path $archivo -Leaf)"

    $viejos = Get-ChildItem -LiteralPath $script:BackupDir -File -Filter "${bd}_*" |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retencion) }
    $viejos | Remove-Item -Force
    $mb = [math]::Round((Get-Item -LiteralPath $archivo).Length / 1MB, 2)
    Escribir-Log 'BACKUP' "OK archivo=$(Split-Path $archivo -Leaf) tamano_mb=$mb retencion_dias=$retencion eliminados=$(@($viejos).Count)"
}
catch {
    Escribir-Log 'BACKUP' "ERROR respaldo fallido db=$bd tipo=$tipo detalle=$($_.Exception.Message)"
    if ($archivo -and (Test-Path -LiteralPath $archivo)) { Remove-Item -LiteralPath $archivo -Force -ErrorAction SilentlyContinue }
    exit 1
}
finally {
    Remove-Item Env:\SQLCMDPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue
}
