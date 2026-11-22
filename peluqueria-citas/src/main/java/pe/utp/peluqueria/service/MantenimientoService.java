package pe.utp.peluqueria.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.LocalDateTime;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.model.EstadoEnvio;
import pe.utp.peluqueria.repository.NotificacionRepository;

/** Tareas de mantenimiento de la base de datos de la aplicacion (invocadas por MantenimientoScheduler). */
@Service
public class MantenimientoService {
    private static final Logger LOG = LoggerFactory.getLogger("MANTENIMIENTO");
    private static final long MINUTOS_TOLERANCIA_PENDIENTES = 30;

    private final NotificacionRepository notificaciones;
    private final Counter eliminadas;

    public MantenimientoService(NotificacionRepository notificaciones, MeterRegistry registro) {
        this.notificaciones = notificaciones;
        this.eliminadas = Counter.builder("peluqueria.mantenimiento.notificaciones.eliminadas")
            .description("Notificaciones antiguas eliminadas por la limpieza programada").register(registro);
    }

    /** Borra notificaciones ENVIADA o FALLIDA programadas hace mas de {@code diasRetencion} dias. */
    @Transactional
    public int limpiarNotificaciones(int diasRetencion) {
        if (diasRetencion < 1) throw new IllegalArgumentException("La retencion minima es 1 dia");
        LocalDateTime limite = LocalDateTime.now().minusDays(diasRetencion);
        int n = notificaciones.eliminarAntiguas(List.of(EstadoEnvio.ENVIADA, EstadoEnvio.FALLIDA), limite);
        eliminadas.increment(n);
        LOG.info("LIMPIEZA_NOTIFICACIONES eliminadas={} retencion_dias={}", n, diasRetencion);
        return n;
    }

    /** Avisa (WARN) si hay recordatorios pendientes que ya debieron enviarse: senal de que el despachador fallo. */
    @Transactional(readOnly = true)
    public long revisarPendientesVencidos() {
        long n = notificaciones.countByEstadoEnvioAndFechaProgramadaBefore(
            EstadoEnvio.PENDIENTE, LocalDateTime.now().minusMinutes(MINUTOS_TOLERANCIA_PENDIENTES));
        if (n > 0) LOG.warn("PENDIENTES_VENCIDOS cantidad={} tolerancia_min={}", n, MINUTOS_TOLERANCIA_PENDIENTES);
        else LOG.info("PENDIENTES_VENCIDOS cantidad=0");
        return n;
    }
}
