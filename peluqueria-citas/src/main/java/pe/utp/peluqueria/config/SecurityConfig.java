
package pe.utp.peluqueria.config;

import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.authorization.AuthorizationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandlerImpl;
import org.springframework.security.web.access.intercept.RequestAuthorizationContext;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.security.web.session.SimpleRedirectInvalidSessionStrategy;
import org.springframework.security.web.util.matcher.IpAddressMatcher;

import jakarta.servlet.http.HttpServletResponse;
import pe.utp.peluqueria.seguridad.AuditoriaSeguridad;
import pe.utp.peluqueria.seguridad.LoginAttemptService;
import pe.utp.peluqueria.seguridad.LoginThrottleFilter;

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
            LoginAttemptService intentos,
            @Value("${app.monitoreo.ips-permitidas:127.0.0.1/32,::1/128}") String ipsMonitoreo) throws Exception {

        // /actuator/prometheus y /actuator/metrics: redes de confianza (CIDR) o rol ADMINISTRADOR.
        List<IpAddressMatcher> redesConfianza = Arrays.stream(ipsMonitoreo.split(","))
            .map(String::trim).filter(r -> !r.isEmpty()).map(IpAddressMatcher::new).toList();
        AuthorizationManager<RequestAuthorizationContext> soloMonitoreo = (autenticacion, ctx) -> {
            boolean redOk = redesConfianza.stream().anyMatch(m -> m.matches(ctx.getRequest()));
            Authentication a = autenticacion.get();
            boolean admin = a != null && a.isAuthenticated() && a.getAuthorities().stream()
                .anyMatch(g -> "ROLE_ADMINISTRADOR".equals(g.getAuthority()));
            return new AuthorizationDecision(redOk || admin);
        };

        var sesionExpirada = new SimpleRedirectInvalidSessionStrategy("/login?expirada");

        http
            .authorizeHttpRequests(a -> a
                // Monitoreo: health publico (solo estado, sin detalles); metricas restringidas.
                .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                .requestMatchers("/actuator/prometheus", "/actuator/metrics", "/actuator/metrics/**")
                    .access(soloMonitoreo)

                // Todo lo demas (h2-console, env, beans, heapdump, info...) sigue denegado.
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

            .formLogin(f -> f
                .loginPage("/login")
                .defaultSuccessUrl("/inicio", true)
                .failureUrl("/login?error")
                .permitAll()
            )

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

            .sessionManagement(s -> s
                .sessionFixation(fix -> fix.migrateSession())
                .invalidSessionStrategy((req, res) -> {
                    if ("GET".equalsIgnoreCase(req.getMethod())
                            || "HEAD".equalsIgnoreCase(req.getMethod())) {
                        sesionExpirada.onInvalidSessionDetected(req, res);
                    } else {
                        res.sendError(HttpServletResponse.SC_FORBIDDEN);
                    }
                })
            )


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

                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000)
                )

                .permissionsPolicy(p -> p.policy(
                    "camera=(), microphone=(), geolocation=(), payment=()"
                ))
            )

            .addFilterBefore(
                new LoginThrottleFilter(intentos),
                UsernamePasswordAuthenticationFilter.class
            );

        return http.build();
    }
}
