# Evidencias de pruebas

Capturas y reportes que respaldan el informe de pruebas de seguridad (Semana 14).
No se incluyen contraseñas, tokens ni datos reales.

| Archivo | Qué muestra | Cómo se genera |
|---|---|---|
| `jacoco_resumen.png` | Reporte de cobertura JaCoCo actualizado | `mvn clean test` y abrir `target/site/jacoco/index.html` |

## Nota sobre la prueba omitida
`MySqlIntegracionTest` solo se ejecuta con `TEST_DB_ENABLED=1` y el perfil `mysql`.
Sin esa variable Maven la reporta como omitida (no es un fallo).
