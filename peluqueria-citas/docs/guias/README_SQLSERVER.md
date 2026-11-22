# Bella Estilo: instalar la base de datos en SQL Server (SSMS 22)

Este paquete adapta el proyecto a **Java 24 y Spring Boot 3.5.16**
y agrega compatibilidad con Microsoft SQL Server. **No ejecutar** el archivo
original `database/schema.sql` en SQL Server: ese archivo usa sintaxis MySQL.

## 1. Crear la base de datos

**Elige UNA de estas dos opciones. No ejecutes ambas en la misma base:**

- **Opción A (instalación nueva con tus datos y citas reales):** ejecutar
  `database/SQLServer/03_BellaEstilo_BaseDatos_Completa_Para_Companero.sql`
  en una instancia SQL Server que **todavía no tenga** `peluqueria_citas`.
  Crea las 13 tablas y conserva los datos de la exportación, incluidas 14 citas.
  No ejecutar los scripts `01` ni `02` después. Ver
  `IMPORTAR_BASE_DATOS_COMPANERO.md` para los pasos completos.
- **Opción B (instalación de demostración):** ejecutar `01` y después,
  opcionalmente, `02`, como se explica a continuación.

El archivo `BellaEstilo_BaseDatos_Completa_Original.sql` es una copia **sin
modificar** de la exportación de SSMS; se incluye para conservarla, pero no es
el recomendado para otra PC: contiene rutas físicas del equipo de origen,
opciones de SQL Server 2025 y una referencia al inicio de sesión `app_citas`.

1. Abrir **SQL Server Management Studio 22** y conectarse a una instancia de
   **Motor de base de datos** (por ejemplo `localhost` o `localhost\SQLEXPRESS`).
   SSMS por sí solo no instala ni ejecuta el motor SQL Server.
2. Ir a **Archivo > Abrir > Archivo** y seleccionar
   `database/SQLServer/01_BellaEstilo_Estructura.sql`.
3. Pulsar **Ejecutar** (F5). Debe crearse la base `peluqueria_citas` con
   13 tablas, roles, sede, categorías y servicios.
4. **Opcional para una demo local solamente:** abrir y ejecutar
   `database/SQLServer/02_BellaEstilo_Datos_Demo.sql`. Agrega usuarios,
   estilistas, horarios, citas y contraseñas de ejemplo que son públicas.
   **Nunca ejecutar este paso en una base de producción.**
5. Refrescar **Bases de datos** en el Explorador de objetos de SSMS.

Los scripts `01` y `02` son incrementales y no borran tablas. Antes de
ejecutarlos sobre una base ya utilizada, realizar una copia de seguridad.
**El script `03` no es incremental: usarlo solo en una instalación nueva.**

## 2. Dar acceso a la aplicación Java

La aplicación usa un usuario SQL Server y contraseña por variables de entorno.
Para un equipo de desarrollo, el administrador del motor puede crear una cuenta
de acceso específica `app_citas` desde **Seguridad > Inicios de sesión > Nuevo
inicio de sesión**, con **Autenticación de SQL Server**, una contraseña propia,
asignación a la base `peluqueria_citas` y los roles `db_datareader` y
`db_datawriter`. No usar una cuenta `sa` para la aplicación.

Si solo está habilitada **Autenticación de Windows**, primero es necesario
configurar la autenticación SQL Server o adaptar el proyecto a autenticación
integrada de Windows. Estas instrucciones asumen autenticación SQL Server.

## 3. Conectar Spring Boot en Windows PowerShell

Abrir PowerShell dentro de la carpeta `peluqueria-citas` y ejecutar,
reemplazando los valores de ejemplo por los de tu instancia:

```powershell
$env:SPRING_PROFILES_ACTIVE="sqlserver"
$env:DB_USER="app_citas"
$cred = Get-Credential -UserName "app_citas" -Message "Clave de SQL Server"
$env:DB_PASSWORD = $cred.GetNetworkCredential().Password
$env:DB_URL="jdbc:sqlserver://localhost:1433;databaseName=peluqueria_citas;encrypt=true;trustServerCertificate=true;sendTimeAsDatetime=false"
$env:COOKIE_SECURE="false"
mvn spring-boot:run
```

Abrir `http://localhost:8080`. Se necesitan **JDK 24** y **Maven 3.9+**.
Comprobar en VS Code con `java -version`, `javac -version` y `mvn -version`.
Si coexisten varios JDK, configurar el JDK 24 como `JAVA_HOME` y el primero
en el `PATH` de la terminal donde se ejecuta Maven.

Si tu servidor se llama `localhost\SQLEXPRESS` y no usa TCP 1433,
modificar `DB_URL` para usar el nombre de instancia (y revisar que TCP/IP
esté habilitado en SQL Server Configuration Manager):

```powershell
$env:DB_URL="jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=peluqueria_citas;encrypt=true;trustServerCertificate=true;sendTimeAsDatetime=false"
```

En Windows, si se dispone de SQL Server Express con usuario `app_citas`, es
mas facil abrir `INICIAR_BELLA_ESTILO_SQLSERVER.cmd`: configura las variables,
solicita la clave de forma segura y arranca Maven. No requiere escribir estos
comandos en cada inicio. Para este instalador se ha comprobado la conexion a
`SQLEXPRESS` y el registro real de una cita en `dbo.cita`.

`trustServerCertificate=true` es solo para **desarrollo local** con certificado
de prueba. En producción, configurar un certificado válido y usar
`trustServerCertificate=false` (con `encrypt=true`).

## 4. Usuarios de prueba (solo si ejecutaste el script opcional)

| Rol | Correo | Contraseña de DEMO |
|---|---|---|
| Administrador | `recepcion@bellaestilo.pe` | `Admin123!` |
| Estilista | `milagros@bellaestilo.pe` | `Estilista123!` |
| Cliente | `valeria.rojas@correo.com` | `Cliente123!` |

Hay también estilistas `rosa@bellaestilo.pe` y `jimena@bellaestilo.pe`.
Todas estas contraseñas son conocidas; **no usar los usuarios de prueba en
producción**. Para una instalación real, ejecutar solo la estructura y crear
el administrador desde variables de entorno `ADMIN_EMAIL` y `ADMIN_PASSWORD`
(mínimo 12 caracteres, mayúsculas, minúsculas y números).

## 5. Consultas para comprobar la base en SSMS

```sql
USE peluqueria_citas;
SELECT name FROM sys.tables ORDER BY name;
SELECT nombre, precio, duracion_min FROM dbo.servicio;
SELECT COUNT(*) AS total_usuarios FROM dbo.usuario;
SELECT COUNT(*) AS total_citas FROM dbo.cita;
```

**Nota:** el 21/11/2026 se comprobo en el equipo de desarrollo la conexion a
SQL Server Express 17.0 y el registro de una cita real. El controlador JDBC
envia las horas como `TIME` (`sendTimeAsDatetime=false`) para poder comparar
`hora_inicio` y `hora_fin` en SQL Server. Los scripts conservan los datos
existentes; no borrar la base de datos ni ejecutar de nuevo los datos demo.
