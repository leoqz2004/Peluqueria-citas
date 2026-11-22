package pe.utp.peluqueria.scheduler;

import java.time.LocalDateTime;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.model.EstadoEnvio;
import pe.utp.peluqueria.repository.NotificacionRepository;
import pe.utp.peluqueria.service.NotificacionService;

@Component
public class RecordatorioScheduler {
    private static final Logger LOG = LoggerFactory.getLogger(RecordatorioScheduler.class);
    private final NotificacionRepository repo;
    private final NotificacionService servicio;

    public RecordatorioScheduler(NotificacionRepository repo, NotificacionService servicio) {
        this.repo = repo; this.servicio = servicio;
    }

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void despachar() {
        var pendientes = repo.findByEstadoEnvioAndFechaProgramadaLessThanEqual(EstadoEnvio.PENDIENTE, LocalDateTime.now());
        if (pendientes.isEmpty()) return;
        pendientes.forEach(servicio::enviar);
        LOG.info("RECORDATORIOS procesados={}", pendientes.size());
    }
}
