# Matriz de hallazgos — Semana 14

Riesgo = Probabilidad (1-5) × Impacto (1-5). Bajo 1-5 · Medio 6-11 · Alto 12-19 · Crítico 20-25.

| ID | Hallazgo | OWASP | P×I | Nivel | Evidencia inicial | Corrección | Re-test | Estado |
|---|---|---|---|---|---|---|---|---|
| SEG-01 | Un estilista podía confirmar citas de otro estilista (sin verificar propiedad) | A01 | 3×4=12 | Alto | `AdminController.confirmar` → `CitaService.confirmar(id)` sin actor | `confirmar(id, actor)` con control de propiedad | `SeguridadAutorizacionTest#estilista_noConfirmaCitaDeOtraEstilista` | Corregido (confirmar con `mvn test`) |
| SEG-02 | Faltaban cabeceras defensivas (CSP, Referrer-Policy, Permissions-Policy, HSTS) | A02 | 4×2=8 | Medio | `SecurityConfig` solo definía X-Frame-Options | Cabeceras en `SecurityConfig` | `SeguridadCabecerasTest` | Corregido (confirmar con `mvn test`) |
| SEG-03 | Sin límite de intentos de login y contraseña solo de 8 caracteres | A07 | 4×3=12 | Alto | Revisión de `SecurityConfig`/`RegistroDto` | `LoginAttemptService`, `LoginThrottleFilter`, `PoliticaPassword` | `SeguridadLoginTest`, `SeguridadPasswordTest` | Corregido (confirmar con `mvn test`) |
| SEG-04 | Sin registro de eventos de seguridad | A09 | 3×3=9 | Medio | No existía log de login/accesos denegados | `AuditoriaSeguridad` + handler de acceso denegado | `SeguridadAuditoriaTest` | Corregido (confirmar con `mvn test`) |
| SEG-05 | Sin manejo genérico de excepciones (400/404/405/500 con páginas por defecto) | A10/A02 | 3×3=9 | Medio | `GlobalExceptionHandler` solo cubría 4 excepciones | Handler genérico + `error.html` + propiedades `server.error.*` | `SeguridadErroresTest` | Corregido (confirmar con `mvn test`) |
| SEG-06 | Cookie de sesión sin SameSite/Secure y sin timeout explícito | A02/A07 | 3×2=6 | Medio | `application.properties` | `same-site`, `secure` (por entorno), `timeout=30m`, logout invalida sesión | `SeguridadConfiguracionTest` | Corregido (confirmar con `mvn test`) |
| SEG-07 | Validación incompleta (alta de estilista sin `@Valid`, nombres sin formato, listas/longitudes sin tope) | A05 | 3×2=6 | Medio | `AdminController.crearEstilista` con `@RequestParam` sueltos | `EstilistaDto`, `@Pattern`, `@Size`, topes de longitud | `SeguridadValidacionTest` | Corregido (confirmar con `mvn test`) |
| SEG-08 | Sin análisis estático ni auditoría de dependencias automatizados | A03 | 2×2=4 | Bajo | `pom.xml` sin herramientas | Perfil `security` (SpotBugs+FindSecBugs, Dependency-Check) + scripts | Ejecutar `scripts/seguridad.*` | Mitigado (adjuntar reportes) |
| SEG-09 | Sin `.gitignore`/`.env.example`; credenciales de demo en código | A02 | 2×2=4 | Bajo | `DemoDataSeeder`, README | `.gitignore`, `.env.example`, admin inicial exige clave robusta; demo solo en perfil `demo` | `SeguridadConfiguracionTest` | Corregido / riesgo aceptado en demo |

> Los hallazgos de SpotBugs/FindSecBugs y Dependency-Check deben agregarse aquí con sus salidas reales tras ejecutar `scripts/seguridad.*`.
