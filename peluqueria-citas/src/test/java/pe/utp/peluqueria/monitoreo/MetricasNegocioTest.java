package pe.utp.peluqueria.monitoreo;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import pe.utp.peluqueria.model.EstadoCita;
import pe.utp.peluqueria.model.EstadoEnvio;
import pe.utp.peluqueria.repository.CitaRepository;
import pe.utp.peluqueria.repository.NotificacionRepository;

class MetricasNegocioTest {
    CitaRepository citas = mock(CitaRepository.class);
    NotificacionRepository notificaciones = mock(NotificacionRepository.class);
    SimpleMeterRegistry registro = new SimpleMeterRegistry();

    @Test
    void publicaCitasPorEstado_yNotificaciones() {
        when(citas.countByEstado(EstadoCita.PENDIENTE)).thenReturn(3L);
        when(citas.countByFecha(any(LocalDate.class))).thenReturn(7L);
        when(notificaciones.countByEstadoEnvio(EstadoEnvio.FALLIDA)).thenReturn(2L);

        new MetricasNegocio(citas, notificaciones).bindTo(registro);

        assertEquals(3.0, registro.get("peluqueria.citas.por.estado").tag("estado", "PENDIENTE").gauge().value());
        assertEquals(7.0, registro.get("peluqueria.citas.hoy").gauge().value());
        assertEquals(2.0, registro.get("peluqueria.notificaciones.por.estado").tag("estado", "FALLIDA").gauge().value());
    }

    @Test
    void siLaBaseDeDatosFalla_devuelveNaN_sinLanzarExcepcion() {
        when(citas.countByEstado(EstadoCita.PENDIENTE)).thenThrow(new IllegalStateException("BD caida"));

        new MetricasNegocio(citas, notificaciones).bindTo(registro);

        double valor = registro.get("peluqueria.citas.por.estado").tag("estado", "PENDIENTE").gauge().value();
        assertTrue(Double.isNaN(valor));
    }
}
