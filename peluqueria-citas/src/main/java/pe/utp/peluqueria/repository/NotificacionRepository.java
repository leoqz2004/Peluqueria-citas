package pe.utp.peluqueria.repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import pe.utp.peluqueria.model.*;

public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {
    List<Notificacion> findByEstadoEnvioAndFechaProgramadaLessThanEqual(EstadoEnvio estado, LocalDateTime hasta);
    void deleteByCitaIdAndTipoAndEstadoEnvio(Long citaId, TipoNotificacion tipo, EstadoEnvio estado);

    // Metricas y mantenimiento
    long countByEstadoEnvio(EstadoEnvio estado);

    long countByEstadoEnvioAndFechaProgramadaBefore(EstadoEnvio estado, LocalDateTime limite);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from Notificacion n where n.estadoEnvio in :estados and n.fechaProgramada < :limite")
    int eliminarAntiguas(@Param("estados") Collection<EstadoEnvio> estados, @Param("limite") LocalDateTime limite);

    @Query("select n from Notificacion n where n.cita.cliente.id = :cliente order by n.fechaProgramada desc")
    List<Notificacion> deCliente(@Param("cliente") Long cliente);
}
