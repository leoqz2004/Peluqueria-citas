#!/usr/bin/env bash
# Pruebas Python (pytest) de Bella Estilo. Se puede ejecutar desde cualquier carpeta.
# La app debe estar corriendo (mvn spring-boot:run, perfil demo) o exportar START_APP=1.
set -u
cd "$(dirname "$0")/../.."
[ -d .venv ] || python3 -m venv .venv
source .venv/bin/activate
pip install -q -r requirements.txt
python -m playwright install chromium
mkdir -p reportes_pruebas
pytest -v --html=reportes_pruebas/reporte_pruebas.html --self-contained-html --junitxml=reportes_pruebas/junit.xml
python tests_python/resumen_resultados.py
