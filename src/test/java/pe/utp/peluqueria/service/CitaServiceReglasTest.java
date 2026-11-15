package pe.utp.peluqueria.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.security.access.AccessDeniedException;
import pe.utp.peluqueria.dto.ReservaDto;
import pe.utp.peluqueria.exception.*;
import pe.utp.peluqueria.model.*;
import pe.utp.peluqueria.repository.*;

/** Pruebas de servicio (Mockito como repositorio falso). Complementa CitaServiceTest. RF-03/RF-04, RN01-RN05. */
class CitaServiceReglasTest {
    CitaRepository citas = mock(CitaRepository.class);
    ClienteRepository clientes = mock(ClienteRepository.class);
    EstilistaRepository estilistas = mock(EstilistaRepository.class);
    ServicioRepository servicios = mock(ServicioRepository.class);
    HorarioEstilistaRepository horarios = mock(HorarioEstilistaRepository.class);
    NotificacionService notif = mock(NotificacionService.class);
    CitaService service = new CitaService(citas, clientes, estilistas, servicios, horarios, notif, 30);

    Estilista estilista; Servicio corte, lavado; Cliente cliente; LocalDate lunes;

    static void setId(Object o, Long id) throws Exception {
        Class<?> c = o.getClass();
        while (c != Object.class) {
            try { Field f = c.getDeclaredField("id"); f.setAccessible(true); f.set(o, id); return; }
            catch (NoSuchFieldException e) { c = c.getSuperclass(); }
        }
    }

    @BeforeEach
    void preparar() throws Exception {
        corte = new Servicio(); setId(corte, 1L); corte.setNombre("Corte"); corte.setPrecio(new BigDecimal("35")); corte.setDuracionMin(40);
        lavado = new Servicio(); setId(lavado, 2L); lavado.setNombre("Lavado"); lavado.setPrecio(new BigDecimal("25")); lavado.setDuracionMin(30);
        estilista = new Estilista(); setId(estilista, 10L); estilista.setNombres("Ana"); estilista.setApellidos("Diaz");
        estilista.setSede(new Sede()); estilista.getServicios().add(corte); estilista.getServicios().add(lavado);
        cliente = new Cliente(); setId(cliente, 5L);
        lunes = LocalDate.now().plusDays(1);
        while (lunes.getDayOfWeek() != DayOfWeek.MONDAY) lunes = lunes.plusDays(1);
        when(clientes.findById(5L)).thenReturn(Optional.of(cliente));
        when(estilistas.findById(10L)).thenReturn(Optional.of(estilista));
        when(servicios.findAllById(any())).thenAnswer(i -> {
            List<Servicio> r = new ArrayList<>();
            for (Long id : (Iterable<Long>) i.getArgument(0)) { if (id == 1L) r.add(corte); else if (id == 2L) r.add(lavado); }
            return r;
        });
        when(horarios.findByEstilistaIdAndDiaSemanaOrderByHoraInicio(eq(10L), anyInt()))
            .thenReturn(List.of(new HorarioEstilista(estilista, 1, LocalTime.of(9, 0), LocalTime.of(18, 0))));
        when(citas.buscarCrucesConBloqueo(any(), any(), any(), any(), any())).thenReturn(List.of());
    }

    ReservaDto reserva(LocalDate fecha, LocalTime hora, Long... ids) {
        ReservaDto d = new ReservaDto();
        d.setEstilistaId(10L); d.setServicioIds(List.of(ids)); d.setFecha(fecha); d.setHora(hora);
        return d;
    }

    Cita cita(EstadoCita estado) throws Exception {
        Cita c = new Cita(); setId(c, 1L); c.setCliente(cliente); c.setEstilista(estilista); c.setEstado(estado);
        c.setFecha(lunes); c.setHoraInicio(LocalTime.of(10, 0)); c.setHoraFin(LocalTime.of(10, 40));
        when(citas.findById(1L)).thenReturn(Optional.of(c));
        return c;
    }

    Usuario actor(Long id, String rol) throws Exception {
        Usuario u = new Usuario(); setId(u, id); Rol r = new Rol(); r.setNombre(rol); u.setRol(r); return u;
    }

    // ---- RF-03 Reservar cita ----
    @Test
    void crearCita_variosServicios_sumaDuracionYTotal() {                       // RN02
        Cita c = service.crearCita(5L, reserva(lunes, LocalTime.of(10, 0), 1L, 2L));
        assertEquals(LocalTime.of(11, 10), c.getHoraFin());
        assertEquals(0, new BigDecimal("60").compareTo(c.getTotal()));
    }

    @Test
    void crearCita_terminaExactoEnElCierre_esValida() {                         // limite RN03
        Cita c = service.crearCita(5L, reserva(lunes, LocalTime.of(17, 20), 1L));
        assertEquals(LocalTime.of(18, 0), c.getHoraFin());
    }

    @Test
    void crearCita_fechaPasada_seRechaza() {
        assertThrows(ReglaNegocioException.class, () -> service.crearCita(5L, reserva(LocalDate.now().minusDays(1), LocalTime.of(10, 0), 1L)));
        verify(citas, never()).save(any());
    }

    @Test
    void crearCita_servicioInactivo_seRechaza() {                               // RN07
        corte.setActivo(false);
        assertThrows(ReglaNegocioException.class, () -> service.crearCita(5L, reserva(lunes, LocalTime.of(10, 0), 1L)));
    }

    @Test
    void crearCita_estilistaNoOfreceServicio_seRechaza() {
        estilista.getServicios().remove(lavado);
        assertThrows(ReglaNegocioException.class, () -> service.crearCita(5L, reserva(lunes, LocalTime.of(10, 0), 2L)));
    }

    @Test
    void crearCita_servicioInexistente_lanzaNoEncontrado() {
        assertThrows(RecursoNoEncontradoException.class, () -> service.crearCita(5L, reserva(lunes, LocalTime.of(10, 0), 1L, 99L)));
    }

    @Test
    void horariosLibres_sinServicios_devuelveVacio() {
        assertTrue(service.horariosLibres(10L, lunes, List.of()).isEmpty());
    }

    // ---- RF-04 Estados de la cita (RN04, RN05) ----
    @Test
    void confirmar_pendiente_pasaAConfirmadaYNotifica() throws Exception {
        Cita c = cita(EstadoCita.PENDIENTE);
        service.confirmar(1L);
        assertEquals(EstadoCita.CONFIRMADA, c.getEstado());
        verify(notif).registrar(c, TipoNotificacion.CONFIRMACION);
        verify(notif).programarRecordatorios(c);
    }

    @ParameterizedTest @EnumSource(value = EstadoCita.class, names = {"ATENDIDA", "CANCELADA", "AUSENTE"})
    void confirmar_estadoFinal_seRechaza(EstadoCita estado) throws Exception {
        cita(estado);
        assertThrows(ReglaNegocioException.class, () -> service.confirmar(1L));
        verifyNoInteractions(notif);
    }

    @Test
    void cancelar_citaPropia_cambiaEstadoYNotifica() throws Exception {
        Cita c = cita(EstadoCita.PENDIENTE);
        service.cancelar(1L, "Imprevisto", actor(5L, "CLIENTE"));
        assertEquals(EstadoCita.CANCELADA, c.getEstado());
        assertEquals("Imprevisto", c.getMotivoCancelacion());
        verify(notif).anularRecordatoriosPendientes(c);
        verify(notif).registrar(c, TipoNotificacion.CANCELACION);
    }

    @Test
    void cancelar_citaAjena_seDeniega() throws Exception {
        Cita c = cita(EstadoCita.PENDIENTE);
        assertThrows(AccessDeniedException.class, () -> service.cancelar(1L, "x", actor(6L, "CLIENTE")));
        assertEquals(EstadoCita.PENDIENTE, c.getEstado());
    }

    @Test
    void marcarResultado_pendienteDirectoAAtendida_seRechaza() throws Exception {
        cita(EstadoCita.PENDIENTE);
        assertThrows(ReglaNegocioException.class, () -> service.marcarResultado(1L, EstadoCita.ATENDIDA, actor(10L, "ESTILISTA")));
    }

    @Test
    void marcarResultado_valorInvalido_seRechaza() throws Exception {
        cita(EstadoCita.CONFIRMADA);
        assertThrows(ReglaNegocioException.class, () -> service.marcarResultado(1L, EstadoCita.CANCELADA, actor(10L, "ESTILISTA")));
    }

    @Test
    void reprogramar_citaAtendida_seRechaza() throws Exception {
        cita(EstadoCita.ATENDIDA);
        assertThrows(ReglaNegocioException.class, () -> service.reprogramar(1L, lunes, LocalTime.of(11, 0), actor(5L, "CLIENTE")));
    }
}
