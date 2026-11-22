package pe.utp.peluqueria.monitoreo;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.context.event.EventListener;
import org.springframework.security.authentication.event.AbstractAuthenticationFailureEvent;
import org.springframework.security.authentication.event.AuthenticationSuccessEvent;
import org.springframework.stereotype.Component;

/** Cuenta inicios de sesion correctos y fallidos (misma fuente de eventos que AuditoriaSeguridad). */
@Component
public class MetricasSeguridad {
    private final Counter fallidos;
    private final Counter correctos;

    public MetricasSeguridad(MeterRegistry registro) {
        this.fallidos = Counter.builder("peluqueria.login.fallidos")
            .description("Intentos de inicio de sesion fallidos").register(registro);
        this.correctos = Counter.builder("peluqueria.login.correctos")
            .description("Inicios de sesion correctos").register(registro);
    }

    @EventListener
    public void alFallar(AbstractAuthenticationFailureEvent evento) {
        fallidos.increment();
    }

    @EventListener
    public void alIngresar(AuthenticationSuccessEvent evento) {
        correctos.increment();
    }
}
