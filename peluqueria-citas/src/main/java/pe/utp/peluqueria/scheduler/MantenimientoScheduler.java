package pe.utp.peluqueria.scheduler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import pe.utp.peluqueria.service.MantenimientoService;

/** Cron job interno: limpieza nocturna (03:30 hora de Lima por defecto, configurable en application.properties). */
@Component
@ConditionalOnProperty(name = "app.mantenimiento.habilitado", havingValue = "true", matchIfMissing = true)
public class MantenimientoScheduler {
    private static final Logger LOG = LoggerFactory.getLogger("MANTENIMIENTO");

    private final MantenimientoService servicio;
    private final int diasRetencion;

    public MantenimientoScheduler(MantenimientoService servicio,
                                  @Value("${app.mantenimiento.retencion-notificaciones-dias:90}") int diasRetencion) {
        this.servicio = servicio;
        this.diasRetencion = diasRetencion;
    }

    @Scheduled(cron = "${app.mantenimiento.cron:0 30 3 * * *}", zone = "America/Lima")
    public void mantenimientoNocturno() {
        LOG.info("MANTENIMIENTO_NOCTURNO inicio");
        try {
            servicio.limpiarNotificaciones(diasRetencion);
            servicio.revisarPendientesVencidos();
            LOG.info("MANTENIMIENTO_NOCTURNO fin estado=OK");
        } catch (RuntimeException ex) {
            LOG.error("MANTENIMIENTO_NOCTURNO fin estado=ERROR", ex);
        }
    }
}
