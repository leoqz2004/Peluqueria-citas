@echo off
cd /d "%~dp0..\.."
REM Pruebas Python (pytest) de Bella Estilo. Se puede ejecutar desde cualquier carpeta.
REM La app debe estar corriendo (mvn spring-boot:run, perfil demo) o definir START_APP=1.
if not exist .venv (
  python -m venv .venv
)
call .venv\Scripts\activate
pip install -q -r requirements.txt
python -m playwright install chromium
if not exist reportes_pruebas mkdir reportes_pruebas
pytest -v --html=reportes_pruebas\reporte_pruebas.html --self-contained-html --junitxml=reportes_pruebas\junit.xml
python tests_python\resumen_resultados.py
