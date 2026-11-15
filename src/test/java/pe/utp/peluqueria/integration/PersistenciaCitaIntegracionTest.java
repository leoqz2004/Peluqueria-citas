package pe.utp.peluqueria.integration;

import static org.junit.jupiter.api.Assertions.*;
import static pe.utp.peluqueria.DatosPrueba.*;

import java.time.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.exception.CruceHorarioException;
import pe.utp.peluqueria.model.*;
import pe.utp.peluqueria.repository.*;
import pe.utp.peluqueria.service.CitaService;

/** Integracion Service + JPA + base real (H2 en memoria, perfil demo). Cada test se revierte (@Transactional). */
@SpringBootTest @Transactional
class PersistenciaCitaIntegracionTest {
    @Autowired CitaService citaService;
    @Autowired UsuarioRepository usuarios;
    @Autowired ServicioRepository servicios;

    Long est, serv, cli; LocalDate fecha;

    void datos() {
        est = usuarios.findByEmail(ESTILISTA).orElseThrow().getId();
        cli = usuarios.findByEmail(CLIENTE).orElseThrow().getId();
        serv = servicios.findAll().stream().filter(s -> s.getNombre().equals("Corte de cabello")).findFirst().orElseThrow().getId();
        fecha = fechaConHorario(citaService, est, serv);
    }

    @Test
    void crearCita_sePersisteYApareceEnElHistorial() {
        datos();
        Cita c = citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 0)));
        assertNotNull(c.getId());
        assertEquals(LocalTime.of(10, 40), c.getHoraFin());
        assertTrue(citaService.historial(cli).stream().anyMatch(h -> h.getId().equals(c.getId())));
    }

    @Test
    void cruceDeHorario_seDetectaEnBaseDeDatos_yHorarioContiguoEsValido() {
        datos();
        citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 0)));
        assertThrows(CruceHorarioException.class, () -> citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 30))));
        assertNotNull(citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 40))).getId());   // limite: empieza donde termina la otra
    }

    @Test
    void cancelar_liberaElHorario() {
        datos();
        Cita c = citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 0)));
        citaService.cancelar(c.getId(), "Prueba", usuarios.findByEmail(CLIENTE).orElseThrow());
        assertNotNull(citaService.crearCita(cli, reserva(est, serv, fecha, LocalTime.of(10, 0))).getId());
    }
}
