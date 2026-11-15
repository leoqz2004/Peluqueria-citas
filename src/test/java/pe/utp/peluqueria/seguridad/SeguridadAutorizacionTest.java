package pe.utp.peluqueria.seguridad;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.*;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.model.Cita;
import pe.utp.peluqueria.model.EstadoCita;
import pe.utp.peluqueria.repository.UsuarioRepository;
import pe.utp.peluqueria.service.CitaService;

/** A01: control de acceso en el servidor. El acceso denegado tambien es un resultado correcto. */
@SpringBootTest @AutoConfigureMockMvc @Transactional
class SeguridadAutorizacionTest {
    static final String ADMIN = "recepcion@bellaestilo.pe";
    static final String OTRA_ESTILISTA = "rosa@bellaestilo.pe";
    @Autowired MockMvc mvc;
    @Autowired UsuarioRepository usuarios;
    @Autowired CitaService citaService;

    @ParameterizedTest
    @ValueSource(strings = {"/admin/panel", "/admin/citas", "/admin/servicios", "/admin/estilistas", "/admin/clientes",
        "/admin/reportes/citas", "/admin/reportes/servicios", "/agenda", "/mis-citas", "/reservar", "/notificaciones", "/servicios"})
    void rutasProtegidas_sinSesion_redirigenALogin(String ruta) throws Exception {
        mvc.perform(get(ruta)).andExpect(status().is3xxRedirection()).andExpect(redirectedUrlPattern("**/login"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"/admin/panel", "/admin/citas", "/admin/servicios", "/admin/estilistas", "/admin/clientes",
        "/admin/reportes/citas", "/agenda"})
    void cliente_noAccedeAZonasDeOtrosRoles(String ruta) throws Exception {
        mvc.perform(get(ruta).with(user(CLIENTE).roles("CLIENTE"))).andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"/admin/panel", "/admin/clientes", "/reservar", "/mis-citas", "/notificaciones"})
    void estilista_noAccedeAAdminNiAClientes(String ruta) throws Exception {
        mvc.perform(get(ruta).with(user(ESTILISTA).roles("ESTILISTA"))).andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"/agenda", "/reservar", "/mis-citas"})
    void administrador_noAccedeARutasDeEstilistaNiCliente(String ruta) throws Exception {
        mvc.perform(get(ruta).with(user(ADMIN).roles("ADMINISTRADOR"))).andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"/h2-console", "/actuator/health", "/actuator/env"})
    void consolasYEndpointsExtra_estanBloqueados(String ruta) throws Exception {
        mvc.perform(get(ruta).with(user(ADMIN).roles("ADMINISTRADOR"))).andExpect(status().isForbidden());
    }

    @Test   // SEG-01: IDOR - una estilista no puede confirmar citas de otra
    void estilista_noConfirmaCitaDeOtraEstilista() throws Exception {
        Cita ajena = citaPendienteDe(ESTILISTA);
        mvc.perform(post("/admin/citas/" + ajena.getId() + "/confirmar").with(user(OTRA_ESTILISTA).roles("ESTILISTA")).with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    void estilista_siConfirmaSuPropiaCita() throws Exception {
        Cita propia = citaPendienteDe(ESTILISTA);
        mvc.perform(post("/admin/citas/" + propia.getId() + "/confirmar").with(user(ESTILISTA).roles("ESTILISTA")).with(csrf()))
            .andExpect(status().is3xxRedirection());
    }

    @Test   // IDOR en cancelacion: un cliente no cancela citas de otro cliente
    void cliente_noCancelaCitaDeOtroCliente() throws Exception {
        Long idCita = citaService.historial(usuarios.findByEmail(OTRO_CLIENTE).orElseThrow().getId()).get(0).getId();
        mvc.perform(post("/citas/" + idCita + "/cancelar").with(user(CLIENTE).roles("CLIENTE")).with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test   // IDOR en horarios de reprogramacion
    void cliente_noConsultaHorariosDeCitaAjena() throws Exception {
        Long idCita = citaService.historial(usuarios.findByEmail(OTRO_CLIENTE).orElseThrow().getId()).get(0).getId();
        mvc.perform(get("/citas/" + idCita + "/horarios").param("fecha", LocalDate.now().plusDays(1).toString())
                .with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isForbidden());
    }

    @Test   // un estilista solo marca resultado en su propia cita
    void estilista_noMarcaAtendidaCitaAjena() throws Exception {
        Cita ajena = citaPendienteOConfirmadaDe(ESTILISTA);
        mvc.perform(post("/agenda/" + ajena.getId() + "/atendida").param("resultado", "ATENDIDA")
                .with(user(OTRA_ESTILISTA).roles("ESTILISTA")).with(csrf()))
            .andExpect(status().isForbidden());
    }

    private Cita citaPendienteDe(String emailEstilista) {
        Long id = usuarios.findByEmail(emailEstilista).orElseThrow().getId();
        return citaService.agenda(id, LocalDate.now()).stream().filter(c -> c.getEstado() == EstadoCita.PENDIENTE).findFirst().orElseThrow();
    }

    private Cita citaPendienteOConfirmadaDe(String emailEstilista) {
        Long id = usuarios.findByEmail(emailEstilista).orElseThrow().getId();
        return citaService.agenda(id, LocalDate.now()).stream()
            .filter(c -> c.getEstado() == EstadoCita.PENDIENTE || c.getEstado() == EstadoCita.CONFIRMADA).findFirst().orElseThrow();
    }
}
