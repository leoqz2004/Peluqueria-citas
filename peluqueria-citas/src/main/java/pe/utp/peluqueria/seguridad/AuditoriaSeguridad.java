package pe.utp.peluqueria.seguridad;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.security.authentication.event.AbstractAuthenticationFailureEvent;
import org.springframework.security.authentication.event.AuthenticationSuccessEvent;
import org.springframework.stereotype.Component;

@Component
public class AuditoriaSeguridad {
    public static final Logger LOG = LoggerFactory.getLogger("SEGURIDAD");
    private final LoginAttemptService intentos;
    public AuditoriaSeguridad(LoginAttemptService intentos) { this.intentos = intentos; }

    @EventListener
    public void alFallar(AbstractAuthenticationFailureEvent ev) {
        String u = ev.getAuthentication().getName();
        intentos.fallo(u);
        LOG.warn("LOGIN_FALLIDO usuario={} motivo={}", enmascarar(u), ev.getException().getClass().getSimpleName());
    }

    @EventListener
    public void alIngresar(AuthenticationSuccessEvent ev) {
        String u = ev.getAuthentication().getName();
        intentos.exito(u);
        LOG.info("LOGIN_OK usuario={}", enmascarar(u));
    }

    public static String enmascarar(String correo) {
        if (correo == null || correo.isBlank()) return "(vacio)";
        String limpio = correo.replaceAll("[\\r\\n\\t]", "_");
        if (limpio.length() > 120) limpio = limpio.substring(0, 120);
        int at = limpio.indexOf('@');
        return at > 0 ? limpio.charAt(0) + "***" + limpio.substring(at) : limpio.charAt(0) + "***";
    }

    public static String limpiar(String texto) {
        return texto == null ? "" : texto.replaceAll("[\\r\\n\\t]", "_");
    }
}
