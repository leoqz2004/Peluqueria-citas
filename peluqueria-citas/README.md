# Bella Estilo

## Sistema Web de Gestión y Reserva de Citas para Salones de Belleza

**Proyecto Integrador Final – APF5**

Bella Estilo es una aplicación web orientada a la gestión integral de salones de belleza. Permite administrar clientes, servicios, estilistas, horarios y reservas de citas mediante una interfaz intuitiva, con controles de seguridad, validaciones de negocio y herramientas de monitoreo.

El sistema ha sido desarrollado utilizando tecnologías del ecosistema Java y Spring, aplicando una arquitectura por capas y buenas prácticas de desarrollo de software.

---

## 1. Información general

| Característica | Descripción |
|---|---|
| Nombre del proyecto | Bella Estilo |
| Tipo de sistema | Aplicación web de gestión y reservas |
| Contexto | Proyecto Integrador Final – APF5 |
| Backend | Java 24 + Spring Boot 3.5.16 |
| Framework web | Spring MVC |
| Motor de plantillas | Thymeleaf |
| Persistencia | Spring Data JPA |
| Seguridad | Spring Security |
| Bases de datos | H2, MySQL y SQL Server |
| Pruebas | JUnit 5, Mockito, MockMvc y Pytest |
| Construcción | Maven |
| Monitoreo | Spring Actuator, Prometheus y Grafana |

## 2. Objetivo del proyecto

Desarrollar una plataforma web que centralice los procesos operativos de un salón de belleza, facilitando la administración de servicios, personal, clientes y citas.

El sistema busca mejorar la organización de las reservas, reducir errores en la programación de horarios, fortalecer la seguridad de la información y proporcionar herramientas para el seguimiento de las operaciones.

## 3. Arquitectura y tecnologías

El proyecto utiliza una arquitectura organizada por responsabilidades, separando las capas de presentación, control, lógica de negocio y acceso a datos.

**Tecnologías principales:**

- **Java 24:** lenguaje de programación.
- **Spring Boot 3.5.16:** plataforma principal de desarrollo.
- **Spring MVC:** gestión de solicitudes y controladores.
- **Thymeleaf:** generación de interfaces web.
- **Spring Data JPA:** persistencia y acceso a datos.
- **Spring Security:** autenticación y autorización.
- **Maven:** gestión de dependencias y construcción.
- **MySQL / SQL Server:** motores de base de datos.
- **H2:** base de datos en memoria para demostraciones y pruebas.

## 4. Módulos y funcionalidades implementadas

El sistema contempla los siguientes módulos funcionales:

| Módulo | Funcionalidades | Estado |
|---|---|---|
| Autenticación | Inicio de sesión, registro y control de acceso | Implementado |
| Catálogo | Visualización, búsqueda y filtrado de servicios | Implementado |
| Reservas | Selección de servicios, horarios y confirmación de citas | Implementado |
| Gestión de citas | Consulta, cancelación y reprogramación | Implementado |
| Notificaciones | Notificaciones y preferencias de usuario | Implementado |
| Administración | Panel de recepción y gestión de operaciones | Implementado |
| Servicios | Registro, edición y activación de servicios | Implementado |
| Estilistas | Registro, consulta y gestión de horarios | Parcial |
| Clientes | Listado y búsqueda de clientes | Parcial |
| Reportes | Visualización de información y estadísticas | Parcial |
| Agenda | Consulta de agenda del estilista | Implementado |

**Diseño de interfaz:** el sistema contempla las pantallas P01–P16 del prototipo, con una identidad visual basada en una paleta vinotinto, tarjetas informativas, pestañas, ventanas modales y un asistente de reserva de cuatro pasos.

### Reglas de negocio

Se incorporan reglas para mantener la integridad de las operaciones:

- Validación de disponibilidad y prevención de cruces de horarios.
- Cálculo de duración de las citas según los servicios seleccionados.
- Restricción de reservas dentro de la jornada laboral.
- Control de estados y transiciones de las citas.
- Gestión de notificaciones y recordatorios.
- Conservación de registros mediante la restricción del borrado físico.

## 5. Seguridad de la aplicación

El proyecto incorpora controles de seguridad orientados a proteger la información y las operaciones del sistema, tomando como referencia las recomendaciones de OWASP Top 10:2025.

Entre los mecanismos implementados se encuentran:

- Protección CSRF.
- Políticas de seguridad para contraseñas.
- Control de intentos fallidos de autenticación.
- Bloqueo temporal después de cinco intentos fallidos.
- Validación de datos mediante DTOs.
- Control de propiedad de recursos para prevenir accesos no autorizados (IDOR).
- Cabeceras HTTP de seguridad, incluyendo CSP y HSTS.
- Auditoría de eventos relacionados con la seguridad.
- Manejo centralizado de excepciones.
- Protección de cookies y configuración de sesiones.
- Gestión de credenciales mediante variables de entorno.

La documentación detallada se encuentra en:

`docs/SEGURIDAD.md`

## 6. Pruebas y aseguramiento de calidad

El proyecto incluye pruebas automatizadas para verificar el comportamiento funcional, las reglas de negocio y los controles de seguridad.

**Pruebas Java:**

- JUnit 5.
- Mockito.
- MockMvc.
- Pruebas de integración y persistencia.
- Pruebas de autenticación y autorización.
- Pruebas de validación y reglas de negocio.

**Pruebas Python:**

- Pytest.
- Pruebas funcionales de caja negra.
- Verificación de controles de acceso.
- Validación de entradas.
- Pruebas de configuración y autenticación.
- Pruebas de navegación automatizada.

**Ejecutar las pruebas Java:**

```bash
mvn test
```

**Ejecutar las pruebas Python:**

```bash
python -m pytest tests_python/ -v
```

Guías de ejecución:

- `docs/guias/README_TESTING.md`
- `docs/guias/README_TESTING_PYTHON.md`

## 7. Monitoreo, despliegue y mantenimiento

Se incorporan componentes para facilitar la operación y supervisión del sistema.

| Área | Componentes y capacidades |
|---|---|
| Despliegue | Maven, JAR, Docker, Nginx y systemd |
| Monitoreo | Spring Actuator, métricas propias y logs |
| Visualización | Prometheus y Grafana |
| Mantenimiento | Respaldos, restauración, limpieza de logs y verificación de salud |

Documentación relacionada:

- `docs/operacion/PLAN_DESPLIEGUE.md`
- `docs/operacion/PLAN_MONITOREO.md`
- `docs/operacion/PLAN_MANTENIMIENTO.md`

## 8. Requisitos previos

Para ejecutar el proyecto se requiere:

- JDK 24.
- Maven 3.9 o superior.
- Git.
- MySQL 8 o SQL Server, según el perfil seleccionado.
- Python 3 para ejecutar las pruebas automatizadas correspondientes.

Verificar las versiones instaladas:

```bash
java -version
javac -version
mvn -version
python --version
```

## 9. Instalación y ejecución

### 9.1. Clonar el repositorio

```bash
git clone https://github.com/leoqz2004/Peluqueria-citas.git
cd Peluqueria-citas
```

Para utilizar la versión mejorada publicada:

```bash
git checkout version-mejorada-bellaestilo
cd peluqueria-citas
```

### 9.2. Ejecutar en modo demostración

El perfil `demo` utiliza H2 en memoria y datos de ejemplo, por lo que no requiere instalar MySQL.

Ejecutar:

```bash
mvn spring-boot:run
```

Abrir en el navegador:

[http://localhost:8080](http://localhost:8080)

La información almacenada en H2 se reinicia al volver a iniciar la aplicación.

### 9.3. Ejecutar con MySQL

1. Instalar y configurar MySQL 8.
2. Ejecutar el script `database/schema.sql`.
3. Configurar las variables de entorno necesarias.
4. Iniciar la aplicación con el perfil MySQL.

Variables principales:

```properties
SPRING_PROFILES_ACTIVE=mysql
DB_USER=usuario
DB_PASSWORD=contraseña
```

Ejecución:

```bash
mvn spring-boot:run
```

### 9.4. Ejecutar con SQL Server

El proyecto incluye scripts de estructura y datos de ejemplo para SQL Server.

Los archivos se encuentran en:

`database/SQLServer/`

Para configurar el motor, importar la base de datos y conectar la aplicación, consultar:

`docs/guias/README_SQLSERVER.md`

En Windows también se dispone del siguiente archivo de inicio:

`INICIAR_BELLA_ESTILO_SQLSERVER.cmd`

Para configurar Java 24 desde Visual Studio Code, consultar:

`docs/guias/INICIAR_JAVA24_VSCODE.md`

## 10. Credenciales de demostración

Para las pruebas del perfil de demostración se contemplan las siguientes cuentas:

| Rol | Usuario | Contraseña |
|---|---|---|
| Cliente | valeria.rojas@correo.com | Cliente123! |
| Recepción / Administrador | recepcion@bellaestilo.pe | Admin123! |
| Estilista | milagros@bellaestilo.pe | Estilista123! |

Las credenciales anteriores son exclusivamente de demostración. No deben utilizarse en un entorno productivo. Se recomienda cambiarlas y utilizar contraseñas seguras.

## 11. Estructura del proyecto

```text
peluqueria-citas/
│
├── pom.xml
├── Dockerfile
├── .env.example
├── pytest.ini
├── requirements.txt
├── INICIAR_BELLA_ESTILO_SQLSERVER.cmd
│
├── src/
│   ├── main/
│   │   ├── java/pe/utp/peluqueria/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   ├── model/
│   │   │   ├── dto/
│   │   │   ├── exception/
│   │   │   ├── config/
│   │   │   ├── seguridad/
│   │   │   ├── monitoreo/
│   │   │   └── scheduler/
│   │   │
│   │   └── resources/
│   │       ├── templates/
│   │       ├── static/
│   │       └── application*.properties
│   │
│   └── test/
│       └── java/
│
├── tests_python/
│
├── database/
│   ├── schema.sql
│   └── SQLServer/
│
├── scripts/
│   ├── pruebas/
│   ├── seguridad/
│   ├── mantenimiento/
│   └── despliegue/
│
├── deploy/
│
├── monitoreo/
│
├── reportes_seguridad/
│
└── docs/
    ├── DOCUMENTACION_TECNICA.md
    ├── SEGURIDAD.md
    ├── guias/
    ├── pruebas/
    └── operacion/
```

## 12. Documentación y evidencias

El repositorio contiene documentación técnica, guías de instalación, planes de pruebas, informes de seguridad y documentos operativos.

Se recomienda consultar la carpeta `docs/` para conocer los procedimientos de instalación, configuración, validación y mantenimiento.

Las evidencias de seguridad se encuentran en:

`reportes_seguridad/`

## 13. Estado y alcance del proyecto

Bella Estilo integra funcionalidades de gestión, reservas, seguridad, pruebas automatizadas y monitoreo en una misma plataforma.

En el marco del **Proyecto Integrador Final – APF5**, se presenta el sistema como una solución integral que reúne los componentes funcionales y técnicos desarrollados para la gestión de citas en salones de belleza.

El proyecto contempla tanto los requerimientos funcionales como aspectos técnicos relacionados con la integridad de datos, la protección de accesos, la calidad del software y la operación del sistema.

Las funcionalidades identificadas como parciales mantienen su estado documentado para facilitar futuras mejoras y ampliaciones.

---

**Bella Estilo – Proyecto Integrador Final APF5**

Sistema web para la gestión y reserva de citas en salones de belleza.