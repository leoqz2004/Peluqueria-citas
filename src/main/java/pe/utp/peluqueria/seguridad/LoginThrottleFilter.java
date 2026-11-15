
package pe.utp.peluqueria.seguridad;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.web.filter.OncePerRequestFilter;

/** A07: bloquea temporalmente los intentos de inicio de sesión repetidos. */
public class LoginThrottleFilter extends OncePerRequestFilter {

    private final LoginAttemptService intentos;

    public LoginThrottleFilter(LoginAttemptService intentos) {
        this.intentos = intentos;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest req,
            HttpServletResponse res,
            FilterChain chain
    ) throws ServletException, IOException {

        String ruta = req.getRequestURI();
        String contexto = req.getContextPath();

        if (contexto != null && !contexto.isEmpty()
                && ruta.startsWith(contexto)) {
            ruta = ruta.substring(contexto.length());
        }

        if ("POST".equalsIgnoreCase(req.getMethod())
                && "/login".equals(ruta)
                && intentos.estaBloqueado(req.getParameter("username"))) {

            AuditoriaSeguridad.LOG.warn(
                "LOGIN_BLOQUEADO usuario={} ip={}",
                AuditoriaSeguridad.enmascarar(req.getParameter("username")),
                req.getRemoteAddr()
            );

            res.sendRedirect(req.getContextPath() + "/login?bloqueado");
            return;
        }

        chain.doFilter(req, res);
    }
}
