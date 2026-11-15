# Seguridad de la aplicación — Semana 14 (Pruebas de Seguridad)

Proyecto: Bella Estilo · Java 17 + Spring Boot 3.3 + Spring Security + Thymeleaf + JPA (H2 demo / MySQL 8).
Marco: OWASP Top 10:2025. El laboratorio original plantea Python/Flask/SQL Server; aquí se aplican los **mismos controles** con el stack del proyecto y herramientas equivalentes.

## Equivalencia de herramientas
| Laboratorio | Este proyecto | Tipo |
|---|---|---|
| Bandit | SpotBugs + Find Security Bugs (`mvn -Psecurity`) | SAST |
| pip-audit | OWASP Dependency-Check (`mvn -Psecurity`) | SCA |
| pytest | JUnit 5 + MockMvc (`mvn -Dtest="Seguridad*Test" test`) | Controles/regresión |
| OWASP ZAP | OWASP ZAP (opcional, solo `localhost:8080`) | DAST |
| `cursor.execute("... ?", x)` | JPQL/Spring Data con `@Param` (sin concatenación) | Consultas parametrizadas |
| Jinja2 autoescape | Thymeleaf `th:text` (sin `th:utext`) | Salida segura |
| Flask-WTF CSRF | Spring Security CSRF (por defecto + `th:action`) | CSRF |
| `.env` + `os.getenv` | Variables de entorno (`${DB_PASSWORD}`, `.env` ignorado) | Secretos |

## Controles por punto del laboratorio
| Punto del laboratorio | OWASP | Implementación | Archivo / prueba |
|---|---|---|---|
| Control de acceso en servidor, mínimo privilegio, accesos directos | A01 | Reglas por rol + verificación de propiedad (cliente/estilista) + consolas denegadas | `SecurityConfig`, `CitaService.confirmar(id, actor)` · `SeguridadAutorizacionTest` |
| Configuración: debug, errores, cabeceras, rutas innecesarias | A02 | CSP, nosniff, X-Frame-Options, Referrer-Policy, Permissions-Policy, HSTS; `include-stacktrace=never`; H2 console off; `/actuator/**` denegado | `SecurityConfig`, `application.properties` · `SeguridadCabecerasTest`, `SeguridadConfiguracionTest` |
| Cadena de suministro | A03 | Dependencias gestionadas por Spring Boot BOM (versiones fijas); perfil `security` con Dependency-Check | `pom.xml` · `scripts/seguridad.*` |
| Criptografía / contraseñas | A04 | BCrypt (hash con sal), nunca texto plano | `SecurityConfig` · `SeguridadPasswordTest` |
| Inyección y validación de entradas | A05 | Consultas parametrizadas; Bean Validation (tipo, longitud, formato, contexto); `EstilistaDto` | repositorios, `dto/*` · `SeguridadInyeccionTest`, `SeguridadValidacionTest` |
| XSS y salida segura | A05 | Autoescape de Thymeleaf, sin `th:utext`, CSP sin scripts inline | plantillas · `SeguridadInyeccionTest`, `SeguridadConfiguracionTest` |
| CSRF | — | Token en todos los POST; sin acciones de cambio por GET | `SeguridadCsrfTest` |
| Secretos y configuración | A02 | `.env` ignorado, `.env.example`, `DB_*` por entorno, admin inicial exige clave robusta | `.gitignore`, `application-mysql.properties`, `AdminInicial` |
| Autenticación | A07 | Mensaje genérico, bloqueo tras 5 fallos (15 min), sesión nueva al autenticar, timeout 30 min, logout invalida sesión y cookie, política de contraseñas | `LoginAttemptService`, `LoginThrottleFilter`, `PoliticaPassword` · `SeguridadLoginTest` |
| Errores y excepciones (fallar de forma seguro) | A10 | `GlobalExceptionHandler` genérico + `error.html`; detalle solo en log | `GlobalExceptionHandler` · `SeguridadErroresTest` |
| Logging de seguridad | A09 | Log `SEGURIDAD`: login ok/fallido/bloqueado, logout, acceso denegado/CSRF; correo enmascarado; sin contraseñas | `AuditoriaSeguridad` · `SeguridadAuditoriaTest` |

## Riesgo residual / pendientes
- Registro: el mensaje «correo ya registrado» permite enumerar correos (aceptado; mitigar con verificación por correo).
- Recuperación de contraseña (RF03) aún no implementada.
- El bloqueo de intentos es por usuario y en memoria (se reinicia al reiniciar la app; para producción usar almacén compartido y límite por IP).
- CSP permite `style-src 'unsafe-inline'` (estilos en línea de las plantillas); scripts sí restringidos a `'self'`.
- Perfil `demo` incluye credenciales de ejemplo: **no usar en producción**.
- Ejecutar SpotBugs/Dependency-Check periódicamente y atender CVE nuevas.

## Flujo para el reporte (detectar → priorizar → corregir → re-test → documentar)
1. `git switch -c security/semana14`
2. `scripts/seguridad.sh` (o `.bat`) → evidencias en `reportes_seguridad/`
3. Registrar hallazgos reales de las herramientas en `reportes_seguridad/matriz_hallazgos.md`
4. Un issue/commit/PR por corrección; cerrar un hallazgo solo con re-test verde.
