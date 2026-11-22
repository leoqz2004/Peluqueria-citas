@echo off
cd /d "%~dp0..\.."
REM Requiere JDK 24 y Maven. Ejecuta todas las pruebas y genera cobertura en target\site\jacoco\index.html
mvn test
REM Integracion MySQL (opcional): set TEST_DB_ENABLED=1 & set DB_USER=... & set DB_PASSWORD=... & mvn test
