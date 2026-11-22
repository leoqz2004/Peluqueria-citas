#!/usr/bin/env bash
# Semana 14 - Pruebas de seguridad (Java/Spring Boot). Se puede ejecutar desde cualquier carpeta.
set -u
cd "$(dirname "$0")/../.."
mkdir -p reportes_seguridad
echo "== 1) Linea base: pruebas funcionales =="
mvn -q test 2>&1 | tee reportes_seguridad/baseline_pytest_equivalente_mvn_test.txt
echo "== 2) SAST (SpotBugs + FindSecBugs; equivalente a Bandit) =="
mvn -q -Psecurity compile com.github.spotbugs:spotbugs-maven-plugin:4.10.4.1:spotbugs 2>&1 | tee reportes_seguridad/spotbugs_consola.txt
cp -f target/spotbugsXml.xml reportes_seguridad/spotbugs_findsecbugs.xml 2>/dev/null || true
echo "== 3) SCA (OWASP Dependency-Check; equivalente a pip-audit) =="
mvn -q -Psecurity org.owasp:dependency-check-maven:10.0.4:check ${NVD_API_KEY:+-DnvdApiKey=$NVD_API_KEY} 2>&1 | tee reportes_seguridad/dependency_check_consola.txt
echo "== 4) Pruebas automatizadas de seguridad (re-test) =="
mvn -Dtest='Seguridad*Test' test 2>&1 | tee reportes_seguridad/retest_seguridad.txt
echo "Listo. Evidencias en reportes_seguridad/"
