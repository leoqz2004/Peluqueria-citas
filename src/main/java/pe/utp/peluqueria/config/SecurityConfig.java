
package pe.utp.peluqueria.config;

import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandlerImpl;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;

import jakarta.servlet.http.HttpServletResponse;
import pe.utp.peluqueria.seguridad.AuditoriaSeguridad;
import pe.utp.peluqueria.seguridad.LoginAttemptService;
import pe.utp.peluqueria.seguridad.LoginThrottleFilter;

/** Configuracion de seguridad web (OWASP A01, A02, A05, A07, A09). */
@Configuration
public class SecurityConfig {

    static final String CSP = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
        + "img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; "
        + "base-uri 'self'; form-action 'self'; frame-ancestors 'none'";

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SecurityFilterChain filtros(
            HttpSecurity http,
            LoginAttemptService intentos) throws Exception {

        http
            .authorizeHttpRequests(a -> a
                // A02: bloquear consolas y endpoints de administracion
                .requestMatchers("/h2-console/**", "/actuator/**").denyAll()

                .requestMatchers(
                    "/login", "/registro", "/css/**",
                    "/js/**", "/img/**", "/error"
                ).permitAll()

                .requestMatchers("/admin/citas/*/confirmar")
                    .hasAnyRole("ADMINISTRADOR", "ESTILISTA")

                .requestMatchers("/admin/**")
                    .hasRole("ADMINISTRADOR")

                .requestMatchers("/agenda/**")
                    .hasRole("ESTILISTA")

                .requestMatchers("/citas/**")
                    .hasAnyRole("CLIENTE", "ADMINISTRADOR")

                .requestMatchers(
                    "/reservar/**", "/mis-citas",
                    "/servicios", "/notificaciones/**"
                ).hasRole("CLIENTE")

                .anyRequest().authenticated()
            )

            // A07: autenticacion
            .formLogin(f -> f
                .loginPage("/login")
                .defaultSuccessUrl("/inicio", true)
                .failureUrl("/login?error")
                .permitAll()
            )

            // A07 y A09: cierre de sesion y auditoria
            .logout(l -> l
                .logoutSuccessUrl("/login?salir")
                .invalidateHttpSession(true)
                .clearAuthentication(true)
                .deleteCookies("JSESSIONID")
                .addLogoutHandler((req, res, auth) -> {
                    if (auth != null) {
                        AuditoriaSeguridad.LOG.info(
                            "LOGOUT usuario={}",
                            AuditoriaSeguridad.enmascarar(auth.getName())
                        );
                    }
                })
            )

            // A07: gestion de sesiones
                    
        .sessionManagement(s -> s
            .sessionFixation(fix -> fix.migrateSession())
            .invalidSessionStrategy((req, res) -> {
                if ("GET".equalsIgnoreCase(req.getMethod())
                        || "HEAD".equalsIgnoreCase(req.getMethod())) {
                    res.sendRedirect(req.getContextPath() + "/login?expirada");
                } else {
                    res.sendError(HttpServletResponse.SC_FORBIDDEN);
                }
            })
        )


            // A09: registro de accesos denegados y errores CSRF
            .exceptionHandling(e -> e.accessDeniedHandler((req, res, ex) -> {
                AuditoriaSeguridad.LOG.warn(
                    "ACCESO_DENEGADO metodo={} ruta={} usuario={} motivo={}",
                    req.getMethod(),
                    AuditoriaSeguridad.limpiar(req.getRequestURI()),
                    req.getUserPrincipal() == null
                        ? "anonimo"
                        : AuditoriaSeguridad.enmascarar(
                            req.getUserPrincipal().getName()
                        ),
                    ex.getClass().getSimpleName()
                );

                new AccessDeniedHandlerImpl().handle(req, res, ex);
            }))

            // A02: cabeceras HTTP de seguridad
            .headers(h -> h

                .frameOptions(
                    HeadersConfigurer.FrameOptionsConfig::deny
                )

                .contentTypeOptions(c -> { })

                .contentSecurityPolicy(c ->
                    c.policyDirectives(CSP)
                )

                .referrerPolicy(r -> r.policy(
                    ReferrerPolicyHeaderWriter.ReferrerPolicy
                        .STRICT_ORIGIN_WHEN_CROSS_ORIGIN
                ))

                // HSTS debe configurarse antes de permissionsPolicy
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000)
                )

                .permissionsPolicy(p -> p.policy(
                    "camera=(), microphone=(), geolocation=(), payment=()"
                ))
            )

            // A07: proteccion contra intentos repetidos de login
            .addFilterBefore(
                new LoginThrottleFilter(intentos),
                UsernamePasswordAuthenticationFilter.class
            );

        // CSRF permanece activo por defecto.
        // Las operaciones que modifican datos deben utilizar POST.
        return http.build();
    }
}
