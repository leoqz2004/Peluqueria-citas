package pe.utp.peluqueria.controller;

import static org.hamcrest.Matchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.*;

import java.time.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.repository.*;
import pe.utp.peluqueria.service.CitaService;

/** Pruebas funcionales HTTP con MockMvc sobre la app completa (perfil demo, H2). */
@SpringBootTest @AutoConfigureMockMvc @Transactional
class FuncionalWebTest {
    @Autowired MockMvc mvc;
    @Autowired UsuarioRepository usuarios;
    @Autowired ServicioRepository servicios;
    @Autowired CitaService citaService;

    RequestPostProcessor cliente() { return user(CLIENTE).roles("CLIENTE"); }
    Long idUsuario(String email) { return usuarios.findByEmail(email).orElseThrow().getId(); }
    Long idServicio(String nombre) { return servicios.findAll().stream().filter(s -> s.getNombre().equals(nombre)).findFirst().orElseThrow().getId(); }

    @Test
    void login_esPublico() throws Exception {
        mvc.perform(get("/login")).andExpect(status().isOk()).andExpect(view().name("login"));
    }

    @Test
    void servicios_sinSesion_redirigeALogin() throws Exception {
        mvc.perform(get("/servicios")).andExpect(status().is3xxRedirection()).andExpect(redirectedUrlPattern("**/login"));
    }

    @Test
    void servicios_cliente_muestraSoloActivos() throws Exception {                 // RN07
        mvc.perform(get("/servicios").with(cliente()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("Corte de cabello")))
            .andExpect(content().string(not(containsString("Alisado permanente"))));
    }

    @Test
    void adminCitas_comoCliente_estaProhibido() throws Exception {
        mvc.perform(get("/admin/citas").with(cliente())).andExpect(status().isForbidden());
    }

    @Test
    void registro_sinCsrf_estaProhibido() throws Exception {
        mvc.perform(post("/registro")).andExpect(status().isForbidden());
    }

    @Test
    void registro_valido_redirigeALogin() throws Exception {
        mvc.perform(post("/registro").with(csrf())
                .param("nombres", "Nuevo").param("apellidos", "Cliente").param("email", "nuevo.cliente@correo.com")
                .param("telefono", "987654321").param("password", "Clave1234").param("confirmPassword", "Clave1234")
                .param("aceptaTerminos", "true"))
            .andExpect(redirectedUrl("/login?registrado"));
    }

    @Test
    void registro_passwordsDistintas_vuelveAlFormulario() throws Exception {
        mvc.perform(post("/registro").with(csrf())
                .param("nombres", "Nuevo").param("apellidos", "Cliente").param("email", "otro@correo.com")
                .param("telefono", "987654321").param("password", "Clave1234").param("confirmPassword", "Distinta1")
                .param("aceptaTerminos", "true"))
            .andExpect(status().isOk()).andExpect(view().name("registro"));
    }

    @Test
    void registro_correoYaRegistrado_vuelveAlFormulario() throws Exception {
        mvc.perform(post("/registro").with(csrf())
                .param("nombres", "Valeria").param("apellidos", "Rojas").param("email", CLIENTE.toUpperCase())
                .param("telefono", "987654321").param("password", "Clave1234").param("confirmPassword", "Clave1234")
                .param("aceptaTerminos", "true"))
            .andExpect(status().isOk()).andExpect(view().name("registro"));
    }

    @Test
    void horariosLibres_devuelveJson() throws Exception {
        Long est = idUsuario(ESTILISTA), serv = idServicio("Corte de cabello");
        LocalDate f = fechaConHorario(citaService, est, serv);
        mvc.perform(get("/reservar/horarios").with(cliente())
                .param("estilista", est.toString()).param("fecha", f.toString()).param("servicios", serv.toString()))
            .andExpect(status().isOk()).andExpect(jsonPath("$").isArray()).andExpect(jsonPath("$[0]").exists());
    }

    @Test
    void reservar_valido_redirigeAMisCitas_yMismoHorarioEsRechazado() throws Exception {   // RN01
        Long est = idUsuario(ESTILISTA), serv = idServicio("Corte de cabello");
        LocalDate f = fechaConHorario(citaService, est, serv);
        var req = post("/reservar").with(cliente()).with(csrf())
            .param("estilistaId", est.toString()).param("servicioIds", serv.toString())
            .param("fecha", f.toString()).param("hora", "10:00");
        mvc.perform(req).andExpect(redirectedUrl("/mis-citas?creada"));
        mvc.perform(req).andExpect(status().isOk()).andExpect(view().name("error-negocio"))
            .andExpect(model().attribute("mensaje", containsString("ya tiene una cita")));
    }

    @Test
    void reservar_sinServicios_vuelveAlAsistente() throws Exception {
        mvc.perform(post("/reservar").with(cliente()).with(csrf())
                .param("estilistaId", "1").param("fecha", LocalDate.now().plusDays(1).toString()).param("hora", "10:00"))
            .andExpect(redirectedUrl("/reservar?error"));
    }

    @Test
    void cancelar_citaDeOtroCliente_estaProhibido() throws Exception {
        Long idCita = citaService.historial(idUsuario(OTRO_CLIENTE)).get(0).getId();
        mvc.perform(post("/citas/" + idCita + "/cancelar").with(cliente()).with(csrf()))
            .andExpect(status().isForbidden());
    }
}
