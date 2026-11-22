package pe.utp.peluqueria.monitoreo;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Asigna un identificador a cada peticion (MDC "requestId" + cabecera X-Request-Id) para
 * correlacionar las lineas del log JSON. Siempre se genera en el servidor: no se acepta el
 * valor del cliente, para evitar inyeccion de datos en los logs.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {
    public static final String CABECERA = "X-Request-Id";
    public static final String CLAVE_MDC = "requestId";

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String id = UUID.randomUUID().toString().substring(0, 8);
        MDC.put(CLAVE_MDC, id);
        res.setHeader(CABECERA, id);
        try {
            chain.doFilter(req, res);
        } finally {
            MDC.remove(CLAVE_MDC);
        }
    }
}
