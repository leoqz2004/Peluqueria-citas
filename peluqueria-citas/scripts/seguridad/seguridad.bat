@echo off
cd /d "%~dp0..\.."
REM Semana 14 - Pruebas de seguridad. Se puede ejecutar desde cualquier carpeta.
REM Opcional: set NVD_API_KEY=tu_clave  (acelera OWASP Dependency-Check)
if not exist reportes_seguridad mkdir reportes_seguridad
echo == 1) Linea base: mvn test ==
call mvn -q test > reportes_seguridad\baseline_mvn_test.txt 2>&1
echo == 2) SAST: SpotBugs + FindSecBugs (equivalente a Bandit) ==
call mvn -q -Psecurity compile com.github.spotbugs:spotbugs-maven-plugin:4.10.4.1:spotbugs > reportes_seguridad\spotbugs_consola.txt 2>&1
copy /Y target\spotbugsXml.xml reportes_seguridad\spotbugs_findsecbugs.xml >nul 2>&1
echo == 3) SCA: OWASP Dependency-Check (equivalente a pip-audit) ==
if defined NVD_API_KEY (
  call mvn -q -Psecurity org.owasp:dependency-check-maven:10.0.4:check -DnvdApiKey=%NVD_API_KEY% > reportes_seguridad\dependency_check_consola.txt 2>&1
) else (
  call mvn -q -Psecurity org.owasp:dependency-check-maven:10.0.4:check > reportes_seguridad\dependency_check_consola.txt 2>&1
)
echo == 4) Re-test: pruebas de seguridad ==
call mvn -Dtest=Seguridad*Test test > reportes_seguridad\retest_seguridad.txt 2>&1
echo Listo. Evidencias en reportes_seguridad\
