# Iniciar Bella Estilo con Java 24 y SQL Server en Visual Studio Code

Esta version utiliza Java 24 y Spring Boot 3.5.16. El ZIP contiene tambien
el controlador JDBC de SQL Server y los scripts para SSMS 22.

## La forma mas facil de iniciar Bella Estilo en Windows

Con SQL Server `SQLEXPRESS`, la base `peluqueria_citas`, el usuario `app_citas`,
JDK 24 y Maven ya instalados:

1. Descomprimir el ZIP en una carpeta nueva y abrir `peluqueria-citas`.
2. Cerrar la ejecucion anterior de la aplicacion, si sigue abierta, con Ctrl+C.
3. Dar doble clic en `INICIAR_BELLA_ESTILO_SQLSERVER.cmd` (dentro de la carpeta).
4. Cuando Windows solicite credenciales, introducir la clave personal del
   inicio de sesion SQL Server `app_citas`. No enviarla por chat.
5. Esperar a `Started PeluqueriaApplication` y abrir
   `http://localhost:8080/login`.

El iniciador usa la instalacion Maven `Downloads\apache-maven-3.10.1\bin\mvn.cmd`
o un `mvn.cmd` disponible en PATH. La clave se solicita al iniciar y no se
guarda en ningun archivo. No volver a ejecutar los scripts de creacion de
base de datos: las reservas existentes permanecen en SQL Server.

Si ya tienes VS Code abierto, puedes ejecutar el iniciador desde su terminal
PowerShell con `cmd /c .\INICIAR_BELLA_ESTILO_SQLSERVER.cmd`.

## Paso A: abrir la carpeta correcta

En Visual Studio Code: Archivo > Abrir carpeta > `peluqueria-citas`.
Confirmar que se ve `pom.xml`.

## Paso B: verificar Java 24 y Maven

Abrir Terminal > Nuevo terminal (PowerShell) y ejecutar:

```powershell
java -version
javac -version
mvn -version
```

Los dos primeros deben indicar Java 24. Maven debe estar disponible; si
PowerShell indica que `mvn` no se reconoce, instalar Apache Maven 3.9 o superior
desde https://maven.apache.org/download.cgi y agregar su directorio `bin` al
`PATH`. Cerrar y volver a abrir VS Code despues de cambiar variables de entorno.

Si Maven muestra Java 17 en lugar de 24, cambiar el `JAVA_HOME` de la terminal
al directorio del JDK 24 antes de iniciar el programa.

## Paso C: verificar que la base de datos exista

En SQL Server Management Studio 22 debe aparecer la base `peluqueria_citas`
con 13 tablas. Se crea ejecutando los archivos de `database/SQLServer/` en
orden. No volver a ejecutar el archivo de datos demo en servidores reales.

## Paso D: preparar el acceso de SQL Server

El proyecto usa autenticacion **SQL Server** con un login habilitado para la
base `peluqueria_citas`. Si solo se conecta con autenticacion Windows, crear
primero un login SQL Server para la aplicacion y asignar permisos de lectura
y escritura sobre `peluqueria_citas` (ver `README_SQLSERVER.md`).

En PowerShell, dentro de `peluqueria-citas`, establecer las variables:

```powershell
$env:SPRING_PROFILES_ACTIVE="sqlserver"
$env:DB_URL="jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=peluqueria_citas;encrypt=true;trustServerCertificate=true;sendTimeAsDatetime=false"
$env:DB_USER="app_citas"
$cred = Get-Credential -UserName "app_citas" -Message "Clave de SQL Server"
$env:DB_PASSWORD = $cred.GetNetworkCredential().Password
$env:COOKIE_SECURE="false"
& "$env:USERPROFILE\Downloads\apache-maven-3.10.1\bin\mvn.cmd" spring-boot:run
```

`trustServerCertificate=true` sirve solo para un certificado de desarrollo
local. No usarlo en un servidor publicado.

## Paso E: probar en el navegador

Una vez que Maven muestre que la aplicacion arranco correctamente, abrir:

http://localhost:8080

Si ejecutaste `02_BellaEstilo_Datos_Demo.sql`, puedes ingresar con la cuenta
de prueba de cliente `valeria.rojas@correo.com` y clave `Cliente123!`.
Esas credenciales no son seguras para produccion.

## Problemas frecuentes

- `mvn: no se reconoce`: Maven no esta instalado o falta configurar `PATH`.
- `release version 24 not supported`: la terminal esta usando un JDK anterior;
  comprobar `javac -version` y `mvn -version`.
- `Login failed for user`: revisar `DB_USER`, `DB_PASSWORD`, autenticacion SQL
  Server y permisos del login sobre la base.
- `The TCP/IP connection to the host failed`: verificar el nombre de instancia,
  que TCP/IP este habilitado y el servicio SQL Server Browser para instancias
  con puertos dinamicos; alternativamente configurar un puerto TCP fijo.
- `The data types time and datetime are incompatible`: la conexion debe
  establecer `sendTimeAsDatetime=false`. Esta version lo configura por defecto.
- `ERR_TOO_MANY_REDIRECTS` tras reiniciar la aplicacion: ahora la estrategia
  de seguridad renueva la sesion vencida antes de redirigir al login. Si el
  navegador conserva datos de una version anterior, borrar solo las cookies
  de `localhost`.

Se ha verificado el inicio y el registro de citas en SQL Server Express 17.0
con JDK 24 en Windows (21/11/2026). Tras sustituir esta version, realizar
una reserva de prueba para comprobar las correcciones permanentes.
