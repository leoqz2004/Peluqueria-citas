# Informe de Pruebas de Software y Seguridad (capa Python)
Proyecto: Bella Estilo · Java 24 + Spring Boot 3.5 + Maven · Pruebas: Python 3 + pytest + Playwright

## 1. Objetivo
Verificar, de forma independiente al código Java, que la aplicación cumple sus reglas funcionales y los controles de
seguridad (OWASP Top 10:2025) interactuando con ella **como lo haría un usuario o un atacante externo** (caja negra).

## 2. Alcance y estrategia (conceptos de testing aplicados)
| Concepto | Dónde se aplica |
|---|---|
| Pruebas unitarias | JUnit 5 + Mockito en `src/test/java` (servicios, DTO) — ejecutadas con `mvn test` |
| Pruebas de integración | JUnit + H2 (`PersistenciaCitaIntegracionTest`) y Python: reserva completa HTTP → servicio → BD |
| Pruebas funcionales / caja negra | `tests_python/test_01..03` |
| Pruebas E2E (interfaz) | `tests_python/test_08` (Playwright, Chromium) |
| Pruebas negativas y de validación | entradas inválidas, límites, tipos incorrectos |
| Pruebas de regresión | matriz de hallazgos SEG-01…SEG-09 verificada desde fuera |
| Pruebas de seguridad | `tests_python/test_04..07` |
| Pruebas de humo (smoke) | carga de pantallas principales por rol |
| Cobertura de código | JaCoCo (`mvn test` → `target/site/jacoco/index.html`) |

## 3. Herramientas
pytest, pytest-html (informe), requests + BeautifulSoup (HTTP), Playwright (navegador), JUnit/Mockito/MockMvc/JaCoCo (Maven),
SpotBugs + Find Security Bugs (SAST) y OWASP Dependency-Check (SCA) vía `mvn -Psecurity`, OWASP ZAP (DAST, opcional,
`tests_python/zap_escaneo.py`).

## 4. Trazabilidad: control de seguridad → prueba
| Hallazgo/Control | OWASP | Prueba Python |
|---|---|---|
| SEG-01 IDOR en confirmar citas | A01 | `test_04…::test_idor_*` |
| Reglas por rol / consolas bloqueadas | A01/A02 | `test_04…::test_*_no_accede_*`, `test_consolas_y_actuator_no_expuestos` |
| CSRF en todos los POST | — | `test_04…::test_post_sin_token_csrf_es_rechazado` |
| SEG-02 Cabeceras defensivas / CSP | A02 | `test_06…::test_cabeceras_*`, `test_csp_*` |
| SEG-03 Bloqueo de intentos y política de claves | A07/A04 | `test_07…`, `test_05…::test_registro_invalido_es_rechazado` |
| SEG-05 Errores sin trazas | A10 | `test_06…::test_errores_son_genericos_*` |
| SEG-06 Cookies / sesión | A02/A07 | `test_06…::test_cookie_*`, `test_login_renueva_*`, `test_logout_invalida_*` |
| SEG-07 Validación de entradas | A05 | `test_05…` (SQLi, XSS, DTOs, open redirect) |
| Exposición de archivos y secretos | A02 | `test_06…::test_archivos_sensibles_no_se_sirven` |

## 5. Cómo se ejecutó
Ver `docs/guias/README_TESTING_PYTHON.md`. Evidencias generadas: `reportes_pruebas/reporte_pruebas.html`, `reportes_pruebas/junit.xml`,
`reportes_pruebas/resumen_pruebas.md`, `target/site/jacoco/index.html`.

## 6. Resultados  *(completar con la salida real de la ejecución)*
| Métrica | Valor |
|---|---|
| Pruebas ejecutadas | _pegar de `resumen_pruebas.md`_ |
| Correctas / Fallidas / Omitidas | _…_ |
| Observaciones (xfail) | _…_ |
| Cobertura JaCoCo (líneas) | _…_ |
| Fecha y versión (commit) | _…_ |

> No se incluyen cifras inventadas: este apartado se llena con los resultados reales tras ejecutar la suite.

## 7. Observaciones levantadas (reporte de seguridad)
Formato: hallazgo · severidad · evidencia · corrección propuesta · estado.

| ID | Hallazgo | Severidad | Evidencia (prueba) | Corrección propuesta | Estado |
|---|---|---|---|---|---|
| OBS-01 | Respuestas 404 vs 403 permiten enumerar IDs de citas existentes | Baja | `test_obs01_no_se_puede_enumerar_ids_de_citas` (xfail) | Responder 404 tanto si no existe como si es ajena | Abierta |
| OBS-02 | El registro revela si un correo ya existe | Baja (aceptado) | `test_obs02_registro_no_revela_si_un_correo_existe` (xfail) | Verificación por correo o mensaje neutro | Aceptado (ver `docs/SEGURIDAD.md`) |
| OBS-03 | Bloqueo de login por usuario y en memoria (sin límite por IP; se reinicia al reiniciar) | Baja | `test_07…::test_bloqueo_tras_5_*` verifica el comportamiento actual | Almacén compartido + límite por IP | Aceptado (residual) |
| OBS-04 | CSP permite `style-src 'unsafe-inline'` | Baja | `test_06…::test_csp_*` (scripts sí restringidos) | Mover estilos en línea a CSS | Aceptado (residual) |
| OBS-05 | `Secure` de la cookie y HSTS solo aplican bajo HTTPS (en demo local va por HTTP) | Informativa | `test_hsts_activo_por_https`, `test_cookie_de_sesion_*` | Definir `COOKIE_SECURE=true` en producción | Operativa |

Si alguna prueba falla al ejecutarla, **no se oculta**: se registra aquí como nuevo hallazgo (ID OBS-0x / SEG-xx), con su severidad,
la corrección aplicada y el re-test en verde.

## 8. Avance (60 % testing / 70 % seguridad)
La rúbrica no define la base del porcentaje. Propuesta de cálculo (**confirmar con el docente**):
`avance = funcionalidades/controles con al menos una prueba automatizada ÷ funcionalidades/controles comprometidos`.
Inventario de funcionalidades: pantallas P01–P16 (README.md) y controles SEG-01…SEG-09 (`reportes_seguridad/matriz_hallazgos.md`).

## 9. Conclusiones
_Completar tras la ejecución: estado de la suite, hallazgos abiertos y plan de corrección._
