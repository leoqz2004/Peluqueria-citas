# Bella Estilo · Gestión y Reserva de Citas (APF2)

Aplicación web **Java 24 + Spring Boot 3.5.16** (Spring MVC, Thymeleaf, Spring Data JPA, Spring Security) basada en el informe APF2.
Diseño: pantallas P01–P16 del prototipo (paleta vinotinto, tarjetas, tabs, modales, asistente de 4 pasos).

## Ejecutar la demo (sin instalar MySQL)
Requisitos: JDK 24 (comprobar `java -version` y `javac -version`) y Maven 3.9+.

```bash
mvn spring-boot:run
# abrir http://localhost:8080
```
El perfil por defecto es `demo`: base **H2 en memoria** con datos de ejemplo (se reinicia en cada arranque).

| Rol | Usuario | Clave |
|---|---|---|
| Cliente | `valeria.rojas@correo.com` | `Cliente123!` |
| Recepción (Administrador) | `recepcion@bellaestilo.pe` | `Admin123!` |
| Estilista | `milagros@bellaestilo.pe` (también `rosa@…`, `jimena@…`) | `Estilista123!` |

## Ejecutar con MySQL
1. Ejecutar `database/schema.sql` en MySQL 8 (cambiar las claves de los usuarios de BD).
2. Variables de entorno: `SPRING_PROFILES_ACTIVE=mysql`, `DB_USER`, `DB_PASSWORD`, y opcionalmente `ADMIN_EMAIL`, `ADMIN_PASSWORD` para crear el primer administrador.
3. `mvn spring-boot:run`

## Ejecutar con SQL Server (SSMS 22)
La version adaptada para SQL Server contiene los scripts en `database/SQLServer/` y la
configuracion `application-sqlserver.properties`. Leer **`docs/guias/README_SQLSERVER.md`**
para importar la base desde SSMS 22, cargar datos de prueba opcionales y
conectar Java al motor de SQL Server.

Para iniciar con **Java 24 desde Visual Studio Code**, seguir paso a paso
**`docs/guias/INICIAR_JAVA24_VSCODE.md`** (en Windows basta con `INICIAR_BELLA_ESTILO_SQLSERVER.cmd`).

## Qué está implementado (≈ 50 % del alcance)
| Pantalla | Estado |
|---|---|
| P01 Login · P02 Registro | ✅ (recuperar contraseña RF03: pendiente) |
| P03 Catálogo (cards, filtro y búsqueda) | ✅ |
| P04–P06 Reserva en 4 pasos con horarios libres y sin cruces | ✅ |
| P07 Mis citas (tabs, modal cancelar, reprogramar) | ✅ |
| P08 Notificaciones y preferencias | ✅ (envío real WhatsApp/correo simulado en log) |
| P09 Panel de recepción · P10 Gestión de citas (modales) | ✅ |
| P11 Servicios (crear, editar, activar/desactivar) | ✅ |
| P12 Estilistas y horarios | ◐ alta y consulta; edición de horario pendiente |
| P13 Clientes | ◐ listado y búsqueda; "ver historial" pendiente |
| P14–P15 Reportes | ◐ en pantalla; exportar PDF/Excel y % de ocupación pendientes |
| P16 Agenda del estilista | ✅ |

Reglas de negocio RN01–RN06: validación de cruce con transacción y bloqueo pesimista, duración = suma de servicios, horarios dentro de la jornada, estados y transiciones, notificaciones y recordatorios 24 h / 2 h, sin borrado físico.

## Pruebas
`mvn test` (JUnit 5 + Mockito + MockMvc) · pruebas Python en `tests_python/` (ver `docs/guias/README_TESTING.md` y `docs/guias/README_TESTING_PYTHON.md`).

## Seguridad (Semana 14)
Controles implementados según OWASP Top 10:2025 (detalle en `docs/SEGURIDAD.md`):
CSP y cabeceras defensivas · control de propiedad (IDOR) en confirmar/cancelar/reprogramar · bloqueo temporal tras 5 intentos fallidos ·
política de contraseñas · auditoría de eventos de seguridad (log `SEGURIDAD`, correos enmascarados) · manejador global de errores sin trazas ·
validación reforzada (DTOs) · cookies HttpOnly/SameSite/Secure · secretos por variables de entorno (`.env` ignorado por Git).

```bash
scripts/seguridad/seguridad.sh   # Linux/macOS      (Windows: scripts\seguridad\seguridad.bat)
mvn -Dtest="Seguridad*Test" test     # solo las pruebas de seguridad (re-test)
mvn -Psecurity compile com.github.spotbugs:spotbugs-maven-plugin:4.10.4.1:spotbugs   # SAST (equivalente a Bandit)
mvn -Psecurity org.owasp:dependency-check-maven:10.0.4:check                          # SCA  (equivalente a pip-audit)
```
Evidencias en `reportes_seguridad/` (matriz de hallazgos y reporte). ZAP es opcional y **solo contra localhost**.

## Despliegue, monitoreo y mantenimiento (Semanas 16-18)
| Tema | Qué incluye | Documento |
|---|---|---|
| Despliegue | JAR con Maven, systemd, nginx, Docker, `desplegar.sh/.ps1` con rollback | `docs/operacion/PLAN_DESPLIEGUE.md` |
| Monitoreo | logs JSON con niveles, Actuator, métricas propias, Prometheus + Grafana, alertas | `docs/operacion/PLAN_MONITOREO.md` |
| Mantenimiento | cron jobs, respaldos con retención, restauración, limpieza, verificación de salud | `docs/operacion/PLAN_MANTENIMIENTO.md` |

```bash
curl http://localhost:8080/actuator/health          # {"status":"UP"}
cd deploy && docker compose --env-file ../.env up -d --build      # app + Prometheus + Grafana
scripts/mantenimiento/backup_bd.sh                  # Windows: scripts\mantenimiento\backup_bd.ps1
```

## Estructura del proyecto
```
peluqueria-citas/
├── pom.xml · Dockerfile · .env.example · pytest.ini · requirements.txt
├── INICIAR_BELLA_ESTILO_SQLSERVER.cmd      # arranque con un clic (Windows + SQL Server)
├── src/main/java/pe/utp/peluqueria/
│   ├── controller/ service/ repository/ model/ dto/ exception/   # MVC + capas (DAO via Spring Data)
│   ├── config/ seguridad/                  # SecurityConfig, auditoria, politica de claves
│   ├── monitoreo/                          # metricas de negocio y seguridad, X-Request-Id
│   └── scheduler/                          # recordatorios y mantenimiento nocturno
├── src/main/resources/                     # templates/ (Thymeleaf) · static/ · application*.properties
├── src/test/java/                          # JUnit 5 + Mockito + MockMvc
├── tests_python/                           # pruebas de caja negra (pytest)
├── database/                               # schema.sql (MySQL) y SQLServer/
├── scripts/
│   ├── pruebas/  seguridad/                # ejecucion de pruebas y analisis de seguridad
│   ├── mantenimiento/                      # respaldo, restauracion, logs, salud, cron / tareas programadas
│   └── despliegue/                         # desplegar.sh / desplegar.ps1 (con rollback)
├── deploy/                                 # docker-compose, systemd, nginx
├── monitoreo/                              # Prometheus, alertas y dashboard de Grafana
├── reportes_seguridad/                     # evidencias de pruebas de seguridad
└── docs/
    ├── DOCUMENTACION_TECNICA.md · SEGURIDAD.md
    ├── guias/                              # inicio con VS Code, SQL Server, guias de pruebas
    ├── pruebas/                            # plan e informe de pruebas
    └── operacion/                          # planes de despliegue, monitoreo y mantenimiento
```
