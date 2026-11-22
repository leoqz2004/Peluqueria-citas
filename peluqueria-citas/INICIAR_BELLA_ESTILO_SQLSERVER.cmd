@echo off
setlocal
cd /d "%~dp0"
echo =======================================================
echo    BELLA ESTILO - JAVA 24 Y SQL SERVER EXPRESS
echo =======================================================
echo.
echo Introduce la clave de SQL Server en la ventana segura.
echo La clave NO se guardara en este archivo ni en el ZIP.
echo.
powershell.exe -NoProfile -Command "$ErrorActionPreference = 'Stop'; $env:SPRING_PROFILES_ACTIVE = 'sqlserver'; $env:DB_USER = 'app_citas'; $env:DB_URL = 'jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=peluqueria_citas;encrypt=true;trustServerCertificate=true;sendTimeAsDatetime=false'; $env:COOKIE_SECURE = 'false'; $cred = Get-Credential -UserName $env:DB_USER -Message 'Clave de SQL Server'; if ($null -eq $cred) { Write-Host 'Inicio cancelado'; exit 1 }; $env:DB_PASSWORD = $cred.GetNetworkCredential().Password; $maven = Join-Path $env:USERPROFILE 'Downloads\apache-maven-3.10.1\bin\mvn.cmd'; if (-not (Test-Path -LiteralPath $maven)) { $mavenCmd = Get-Command mvn.cmd -ErrorAction SilentlyContinue; if ($null -eq $mavenCmd) { Write-Host 'No se encontro Maven. Revisa docs\guias\INICIAR_JAVA24_VSCODE.md'; exit 2 }; $maven = $mavenCmd.Source }; try { & $maven spring-boot:run; exit $LASTEXITCODE } finally { Remove-Item Env:\DB_PASSWORD -ErrorAction SilentlyContinue }"
echo.
echo Bella Estilo se ha detenido o no pudo iniciarse.
pause
endlocal
