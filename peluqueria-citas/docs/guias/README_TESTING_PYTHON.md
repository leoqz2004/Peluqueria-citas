# Pruebas Python (pytest) - Bella Estilo

Capa de pruebas **de caja negra** que se ejecuta con **Python (pytest)** contra la aplicación Spring Boot en marcha.
Convive con las pruebas **JUnit/Maven** existentes (`src/test/java`), que no se modificaron. No toca el código de la
aplicación ni la conexión a MySQL / SQL Server: usa el perfil `demo` (H2 en memoria) por defecto.

## 1. Preparar entorno
```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
playwright install chromium
```
Levantar la aplicación (en **otra terminal**, y dejarla corriendo):
```bash
mvn spring-boot:run
```
> Alternativa: `set START_APP=1` y las pruebas inician la app solas con Maven.
> Otra URL: `set BASE_URL=http://localhost:8080` (valor por defecto).

## 2. Pruebas funcionales (HTTP)
```bash
pytest tests_python/test_01_funcional_publico.py -v
pytest tests_python/test_02_funcional_cliente.py -v
pytest tests_python/test_03_funcional_admin_estilista.py -v
```

## 3. Pruebas E2E con navegador (Playwright)
```bash
pytest tests_python/test_08_e2e_navegador.py -v
```
Para verlas en pantalla durante la sustentación: `set E2E_HEADED=1`.

## 4. Pruebas de seguridad (OWASP Top 10)
```bash
pytest tests_python/test_04_seguridad_acceso.py -v
pytest tests_python/test_05_seguridad_entradas.py -v
pytest tests_python/test_06_seguridad_configuracion.py -v
pytest tests_python/test_07_seguridad_autenticacion.py -v
pytest -m seguridad -v          # todas las de seguridad
```

## 5. Todas las pruebas
```bash
pytest -v
```

## 6. Informe HTML y resumen (evidencia para el anexo)
```bash
pytest -v --html=reportes_pruebas/reporte_pruebas.html --self-contained-html --junitxml=reportes_pruebas/junit.xml
python tests_python/resumen_resultados.py
```
Genera `reportes_pruebas/reporte_pruebas.html` y `reportes_pruebas/resumen_pruebas.md`.
Atajo: `scripts\pruebas\run_tests_python.bat` (Windows) o `scripts/pruebas/pruebas_python.sh` (Linux/macOS) hacen los pasos 1, 5 y 6.

## 7. Cobertura
`pytest --cov` mide código Python, no el Java. La cobertura real del código de la app la entrega **JaCoCo** (ya configurado):
```bash
mvn test
```
Reporte: `target/site/jacoco/index.html`.

## 8. Pruebas en Maven
```bash
mvn test                      # JUnit + JaCoCo (como antes)
mvn verify                    # igual que test + verificacion
mvn -Ppython-tests verify     # ADEMAS: levanta la app, ejecuta pytest y la detiene (perfil opcional)
```
Con `-Ppython-tests` se requiere Python con `pip install -r requirements.txt` ya hecho.

## 9. Base de datos
- Por defecto las pruebas usan los datos demo (H2). **No se modificó** `application-mysql.properties`,
  `application-sqlserver.properties` ni `database/`.
- Si la app corre con otra BD y los usuarios demo no existen, defina `TEST_CLIENTE_EMAIL`, `TEST_CLIENTE_PASSWORD`,
  `TEST_ADMIN_EMAIL`, `TEST_ADMIN_PASSWORD`, `TEST_ESTILISTA_EMAIL`, `TEST_ESTILISTA_PASSWORD`
  (las pruebas que dependen de datos demo se omiten si no puede iniciarse sesión).
- La prueba JUnit de MySQL sigue igual: `TEST_DB_ENABLED=1` (ver `README_TESTING.md`).

## 10. Opcional: OWASP ZAP (DAST, solo localhost)
```bash
set ZAP_API_KEY=MI_CLAVE
python tests_python/zap_escaneo.py
```

## Mapa de archivos
| Archivo (`tests_python/`) | Tipo | Cubre |
|---|---|---|
| `test_01_funcional_publico` | Funcional | login, registro, rutas privadas sin sesión |
| `test_02_funcional_cliente` | Funcional/Integración | catálogo, reserva, cruce de horarios (RN), cancelación |
| `test_03_funcional_admin_estilista` | Funcional | panel, servicios (CRUD), clientes, reportes, agenda |
| `test_04_seguridad_acceso` | Seguridad A01 + CSRF | matriz ruta×rol, IDOR, CSRF |
| `test_05_seguridad_entradas` | Seguridad A05 | SQL injection, XSS, validación, open redirect |
| `test_06_seguridad_configuracion` | Seguridad A02/A10 | cabeceras, CSP, cookies, errores, archivos sensibles |
| `test_07_seguridad_autenticacion` | Seguridad A07 | mensajes genéricos, bloqueo por intentos |
| `test_08_e2e_navegador` | E2E | interfaz, filtros, asistente de reserva, CSP |

Notas: las pruebas que modifican datos (reservas, servicios) los **limpian al terminar**. Las pruebas de bloqueo de login
usan **cuentas descartables**, nunca las de la demo. Los casos marcados `observacion` (xfail) son hallazgos conocidos y
documentados; no rompen la ejecución.
