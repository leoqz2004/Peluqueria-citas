package pe.utp.peluqueria;

import java.time.*;
import java.util.List;
import pe.utp.peluqueria.dto.ReservaDto;
import pe.utp.peluqueria.service.CitaService;

/** Utilidades para las pruebas con los datos del perfil demo. */
public final class DatosPrueba {
    private DatosPrueba() {}

    public static final String CLIENTE = "valeria.rojas@correo.com";
    public static final String OTRO_CLIENTE = "rosa.sanchez@correo.com";
    public static final String ESTILISTA = "milagros@bellaestilo.pe";

    public static LocalDate fechaConHorario(CitaService s, Long estilista, Long servicio) {
        for (int i = 1; i <= 14; i++) {
            LocalDate f = LocalDate.now().plusDays(i);
            if (!s.horariosLibres(estilista, f, List.of(servicio)).isEmpty()) return f;
        }
        throw new IllegalStateException("Sin horarios libres en 14 dias");
    }

    public static ReservaDto reserva(Long estilista, Long servicio, LocalDate fecha, LocalTime hora) {
        ReservaDto d = new ReservaDto();
        d.setEstilistaId(estilista); d.setServicioIds(List.of(servicio)); d.setFecha(fecha); d.setHora(hora);
        return d;
    }
}
