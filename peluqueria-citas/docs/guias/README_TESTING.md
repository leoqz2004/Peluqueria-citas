# Testing (Semana 13) - Grupo 1 - Jean Paul Alva Reategui (U21222743)

Requisitos: JDK 24 y Maven 3.9+. Comandos (en la carpeta del proyecto):

    mvn test                      # todas las pruebas + cobertura JaCoCo (target/site/jacoco/index.html)
    mvn -Dtest=CitaServiceReglasTest test   # un archivo
    mvn -Dtest=CitaServiceReglasTest#cancelar_citaAjena_seDeniega test   # un test
    set TEST_DB_ENABLED=1 & set DB_USER=root & set DB_PASSWORD=*** & mvn test   # activa MySQL (opcional)

| Archivo | Tipo |
|---|---|
| dto/RegistroDtoTest | Unitaria (validaciones) |
| service/CitaServiceTest, CitaServiceReglasTest, UsuarioServiceTest, CatalogoServiceTest | Servicio (Mockito) |
| controller/FuncionalWebTest | Funcional (MockMvc) |
| integration/PersistenciaCitaIntegracionTest | Integracion (H2) |
| integration/MySqlIntegracionTest | Integracion MySQL (SKIPPED salvo TEST_DB_ENABLED=1) |

Matriz de trazabilidad, defectos y evidencias: `docs/pruebas/Plan_de_Pruebas_S13.docx`.
Capturas en `evidencias/`: 01_mvn_test.png, 02_cobertura.png, 03_test_fallido.png, 04_test_corregido.png.

## Seguridad (Semana 14)
| Archivo (`src/test/.../seguridad/`) | Control verificado |
|---|---|
| SeguridadCabecerasTest | A02 · CSP, nosniff, X-Frame-Options, Referrer-Policy, Permissions-Policy, HSTS, no-store |
| SeguridadAutorizacionTest | A01 · rutas por rol, IDOR (confirmar/cancelar/horarios/atendida), consolas bloqueadas |
| SeguridadCsrfTest | CSRF · POST sin token = 403, acciones de cambio no permitidas por GET |
| SeguridadInyeccionTest | A05 · SQL injection (payloads), XSS reflejado y almacenado |
| SeguridadValidacionTest | A05 · validación negativa (contraseñas, nombres, fechas, precios, estilistas, open redirect) |
| SeguridadLoginTest | A07 · mensaje genérico, bloqueo tras 5 fallos, bloqueo por usuario |
| SeguridadErroresTest | A10 · 400/404/405 sin trazas ni detalles técnicos |
| SeguridadPasswordTest / SeguridadAuditoriaTest | A07 / A09 · política de contraseñas, BCrypt, límite de intentos, log enmascarado |
| SeguridadConfiguracionTest | A02/A04/A05 · propiedades seguras, sin secretos en código, sin SQL concatenado, sin `th:utext`, CSRF en formularios |

Comandos: `mvn -Dtest="Seguridad*Test" test` · `scripts/seguridad/seguridad.sh` (o `scripts\seguridad\seguridad.bat`).

## Pruebas Python (pytest)
Capa adicional de pruebas de caja negra (funcionales, seguridad OWASP y E2E con Playwright) que se ejecuta con Python
contra la aplicación en marcha. Guía completa en **`README_TESTING_PYTHON.md`**. Resumen: `pip install -r requirements.txt` y
`pytest -v`. Integración con Maven (opcional): `mvn -Ppython-tests verify`.
