package pe.utp.peluqueria.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.LocalDateTime;
import java.util.Collection;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import pe.utp.peluqueria.model.EstadoEnvio;
import pe.utp.peluqueria.repository.NotificacionRepository;

class MantenimientoServiceTest {
    NotificacionRepository repo = mock(NotificacionRepository.class);
    SimpleMeterRegistry registro = new SimpleMeterRegistry();
    MantenimientoService service = new MantenimientoService(repo, registro);

    @Test
    @SuppressWarnings("unchecked")
    void limpiar_eliminaSoloEnviadasYFallidas_yCuenta() {
        when(repo.eliminarAntiguas(anyCollection(), any(LocalDateTime.class))).thenReturn(5);

        int n = service.limpiarNotificaciones(90);

        assertEquals(5, n);
        ArgumentCaptor<Collection<EstadoEnvio>> estados = ArgumentCaptor.forClass(Collection.class);
        verify(repo).eliminarAntiguas(estados.capture(), any(LocalDateTime.class));
        assertTrue(estados.getValue().containsAll(java.util.List.of(EstadoEnvio.ENVIADA, EstadoEnvio.FALLIDA)));
        assertFalse(estados.getValue().contains(EstadoEnvio.PENDIENTE));
        assertEquals(5.0, registro.get("peluqueria.mantenimiento.notificaciones.eliminadas").counter().count());
    }

    @Test
    void limpiar_conRetencionInvalida_seRechaza() {
        assertThrows(IllegalArgumentException.class, () -> service.limpiarNotificaciones(0));
        verifyNoInteractions(repo);
    }

    @Test
    void revisarPendientes_devuelveLaCantidadVencida() {
        when(repo.countByEstadoEnvioAndFechaProgramadaBefore(eq(EstadoEnvio.PENDIENTE), any(LocalDateTime.class))).thenReturn(4L);
        assertEquals(4L, service.revisarPendientesVencidos());
    }
}
