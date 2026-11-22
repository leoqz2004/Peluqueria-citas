package pe.utp.peluqueria.monitoreo;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.binder.MeterBinder;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.function.LongSupplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import pe.utp.peluqueria.model.EstadoCita;
import pe.utp.peluqueria.model.EstadoEnvio;
import pe.utp.peluqueria.repository.CitaRepository;
import pe.utp.peluqueria.repository.NotificacionRepository;

/**
 * Metricas propias del negocio, expuestas en /actuator/prometheus.
 * Son medidores (gauges) que ejecutan un COUNT liviano cuando Prometheus consulta;
 * no modifican los servicios existentes.
 */
@Component
public class MetricasNegocio implements MeterBinder {
    private static final Logger LOG = LoggerFactory.getLogger(MetricasNegocio.class);
    private static final ZoneId LIMA = ZoneId.of("America/Lima");

    private final CitaRepository citas;
    private final NotificacionRepository notificaciones;

    public MetricasNegocio(CitaRepository citas, NotificacionRepository notificaciones) {
        this.citas = citas;
        this.notificaciones = notificaciones;
    }

    @Override
    public void bindTo(MeterRegistry registry) {
        for (EstadoCita estado : EstadoCita.values()) {
            Gauge.builder("peluqueria.citas.por.estado", () -> valor(() -> citas.countByEstado(estado)))
                .description("Cantidad de citas por estado")
                .tag("estado", estado.name())
                .register(registry);
        }
        Gauge.builder("peluqueria.citas.hoy", () -> valor(() -> citas.countByFecha(LocalDate.now(LIMA))))
            .description("Citas programadas para hoy (hora de Lima)")
            .register(registry);
        for (EstadoEnvio estado : EstadoEnvio.values()) {
            Gauge.builder("peluqueria.notificaciones.por.estado", () -> valor(() -> notificaciones.countByEstadoEnvio(estado)))
                .description("Notificaciones por estado de envio")
                .tag("estado", estado.name())
                .register(registry);
        }
    }

    /** Si la BD no responde devuelve NaN (la metrica se omite) en vez de romper el endpoint. */
    private Double valor(LongSupplier consulta) {
        try {
            return (double) consulta.getAsLong();
        } catch (RuntimeException ex) {
            LOG.warn("No se pudo leer una metrica de negocio: {}", ex.getClass().getSimpleName());
            return Double.NaN;
        }
    }
}
