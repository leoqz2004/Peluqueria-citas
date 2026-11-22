# Bella Estilo: pasar proyecto y base SQL Server a otro compañero

El ZIP contiene tanto la aplicación Java 24 como una copia de la base de datos
`peluqueria_citas`. No es necesario que tu compañero exporte nuevamente la
base desde tu computadora.

## En la computadora de tu compañero

1. Descomprimir `BellaEstilo_Proyecto_SQLServer.zip`.
2. Tener instalado el **motor de Microsoft SQL Server** (preferiblemente
   SQL Server 2025 Express) y abrir **SQL Server Management Studio 22**.
   SSMS es una herramienta de administración, no es el motor de datos.
3. Conectarse al servidor desde SSMS usando **Autenticación de Windows** con
   una cuenta administradora.
4. En el Explorador de objetos, comprobar que **NO exista** una base llamada
   `peluqueria_citas`. **Si ya existe, no ejecutar el archivo:** podría
   intentar duplicar objetos y registros. Pedir ayuda antes de continuar.
5. Ir a **Archivo > Abrir > Archivo** y elegir
   `peluqueria-citas/database/SQLServer/03_BellaEstilo_BaseDatos_Completa_Para_Companero.sql`.
6. Pulsar **Ejecutar (F5)** y comprobar en **Mensajes** que terminó sin
   errores. Actualizar **Bases de datos** en el Explorador de objetos.
7. Abrir una **Nueva consulta** y ejecutar:

   ```sql
   USE peluqueria_citas;
   SELECT COUNT(*) AS tablas FROM sys.tables;
   SELECT COUNT(*) AS citas FROM dbo.cita;
   SELECT COUNT(*) AS usuarios FROM dbo.usuario;
   ```

   En esta exportación se esperan **13 tablas, 14 citas y 8 usuarios**.

## Conectar la aplicación Java

8. En SSMS, el administrador debe crear un inicio de sesión SQL Server
   llamado `app_citas`, con **contraseña nueva del compañero**, y asignarlo
   a la base `peluqueria_citas` con los roles `db_datareader` y
   `db_datawriter` (**Seguridad > Inicios de sesión > Nuevo inicio de sesión**).
   El script completo no copia el inicio de sesión del servidor ni su clave.
9. Abrir `peluqueria-citas` en **VS Code**, con Java 24 y Maven instalados.
10. Leer `README_SQLSERVER.md` para configurar la conexión, o en Windows
    ejecutar `INICIAR_BELLA_ESTILO_SQLSERVER.cmd` desde la carpeta raíz del
    proyecto, indicar la contraseña de su propia cuenta `app_citas` y abrir
    `http://localhost:8080`.

## Archivos SQL incluidos

| Archivo | Uso |
|---|---|
| `03_BellaEstilo_BaseDatos_Completa_Para_Companero.sql` | **Recomendado para el compañero**: base nueva con la estructura y todos los datos exportados. |
| `BellaEstilo_BaseDatos_Completa_Original.sql` | Copia exacta del archivo recibido; contiene rutas del disco del PC original y opciones específicas de su servidor. |
| `01_BellaEstilo_Estructura.sql` | Alternativa: instalación vacía de citas, con estructura y catálogo inicial. |
| `02_BellaEstilo_Datos_Demo.sql` | Alternativa: agregar datos de demostración después de `01`. |

**Importante:** la exportación es una fotografía de los datos al momento de
crear el archivo. Si ambos usan bases SQL Server separadas, las nuevas citas
de uno **no aparecerán automáticamente** en la computadora del otro. Para
trabajar sobre los mismos registros en tiempo real, ambos deben conectar su
aplicación a **un único servidor SQL Server compartido**, con acceso a la red
configurado de forma segura.

El archivo contiene nombres, correos, teléfonos y hashes de contraseñas de
los usuarios exportados. Compártelo solo con un compañero de confianza y no
publiques el ZIP en un repositorio público. Las cuentas de prueba del proyecto
tienen contraseñas conocidas y solo deben usarse en desarrollo.
