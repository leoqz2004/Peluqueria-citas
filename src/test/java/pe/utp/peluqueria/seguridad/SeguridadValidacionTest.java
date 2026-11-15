package pe.utp.peluqueria.seguridad;

import static org.junit.jupiter.api.Assertions.*;
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
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.repository.UsuarioRepository;

/** A05: validacion negativa de entradas (tipo, longitud, formato, contexto). */
@SpringBootTest @AutoConfigureMockMvc @Transactional
class SeguridadValidacionTest {
    static final String ADMIN = "recepcion@bellaestilo.pe";
    @Autowired MockMvc mvc;
    @Autowired UsuarioRepository usuarios;

    MockHttpServletRequestBuilder registro(String nombres, String email, String clave) {
        return post("/registro").with(csrf()).param("nombres", nombres).param("apellidos", "Prueba").param("email", email)
            .param("telefono", "987654321").param("password", clave).param("confirmPassword", clave).param("aceptaTerminos", "true");
    }

    @ParameterizedTest
    @ValueSource(strings = {"12345678", "password", "abcdefgh", "ABCDEFGH1", "clave1234", "SinNumeros"})
    void registro_conPasswordDebil_seRechaza(String clave) throws Exception {
        mvc.perform(registro("Ana", "debil.test@correo.com", clave))
            .andExpect(status().isOk()).andExpect(view().name("registro")).andExpect(model().attributeHasFieldErrors("registro", "password"));
        assertFalse(usuarios.existsByEmail("debil.test@correo.com"));
    }

    @Test
    void registro_passwordConElCorreo_seRechaza() throws Exception {
        mvc.perform(registro("Ana", "nuevo.cliente@correo.com", "Nuevo.cliente1"))
            .andExpect(model().attributeHasFieldErrors("registro", "password"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"<script>alert(1)</script>", "Ana<img src=x>", "'; DROP TABLE usuario;--", "Ana123"})
    void registro_nombresConCaracteresPeligrosos_seRechazan(String nombre) throws Exception {
        mvc.perform(registro(nombre, "peligro.test@correo.com", "Clave1234"))
            .andExpect(status().isOk()).andExpect(model().attributeHasFieldErrors("registro", "nombres"));
        assertFalse(usuarios.existsByEmail("peligro.test@correo.com"));
    }

    @Test
    void registro_valido_siSeCrea() throws Exception {
        mvc.perform(registro("María José", "valido.test@correo.com", "Clave1234"))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?registrado"));
    }

    @Test
    void reserva_conFechaPasada_seRechaza() throws Exception {
        mvc.perform(post("/reservar").with(user(CLIENTE).roles("CLIENTE")).with(csrf())
                .param("estilistaId", "1").param("servicioIds", "1").param("fecha", LocalDate.now().minusDays(3).toString()).param("hora", "10:00"))
            .andExpect(redirectedUrl("/reservar?error"));
    }

    @Test
    void reserva_conIdNegativoOMuchosServicios_seRechaza() throws Exception {
        mvc.perform(post("/reservar").with(user(CLIENTE).roles("CLIENTE")).with(csrf())
                .param("estilistaId", "-1").param("servicioIds", "1").param("fecha", LocalDate.now().plusDays(2).toString()).param("hora", "10:00"))
            .andExpect(redirectedUrl("/reservar?error"));
        mvc.perform(post("/reservar").with(user(CLIENTE).roles("CLIENTE")).with(csrf())
                .param("estilistaId", "1").param("servicioIds", "1,2,3,4,5,6,7,8,9,10,11")
                .param("fecha", LocalDate.now().plusDays(2).toString()).param("hora", "10:00"))
            .andExpect(redirectedUrl("/reservar?error"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"-5", "100000", "abc"})
    void servicio_conPrecioInvalido_redirigeConError(String precio) throws Exception {
        mvc.perform(post("/admin/servicios").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf())
                .param("nombre", "Servicio X").param("precio", precio).param("duracionMin", "30").param("categoriaId", "1"))
            .andExpect(redirectedUrl("/admin/servicios?error"));
    }

    @Test
    void servicio_conDuracionExcesiva_redirigeConError() throws Exception {
        mvc.perform(post("/admin/servicios").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf())
                .param("nombre", "Servicio X").param("precio", "50").param("duracionMin", "9999").param("categoriaId", "1"))
            .andExpect(redirectedUrl("/admin/servicios?error"));
    }

    @Test
    void estilista_conClaveDebil_seRechaza() throws Exception {
        mvc.perform(post("/admin/estilistas").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf())
                .param("nombres", "Ana").param("apellidos", "Lopez").param("email", "ana.lopez@bellaestilo.pe").param("telefono", "987654321")
                .param("claveInicial", "12345678").param("especialidad", "Corte").param("servicioIds", "1").param("dias", "1")
                .param("horaInicio", "09:00").param("horaFin", "18:00"))
            .andExpect(redirectedUrl("/admin/estilistas?error"));
        assertFalse(usuarios.existsByEmail("ana.lopez@bellaestilo.pe"));
    }

    @Test
    void estilista_conHorarioInvertidoODiasInvalidos_seRechaza() throws Exception {
        mvc.perform(post("/admin/estilistas").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf())
                .param("nombres", "Ana").param("apellidos", "Lopez").param("email", "ana2.lopez@bellaestilo.pe").param("telefono", "987654321")
                .param("claveInicial", "Estilista456").param("especialidad", "Corte").param("servicioIds", "1").param("dias", "9")
                .param("horaInicio", "09:00").param("horaFin", "18:00"))
            .andExpect(redirectedUrl("/admin/estilistas?error"));
        mvc.perform(post("/admin/estilistas").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf())
                .param("nombres", "Ana").param("apellidos", "Lopez").param("email", "ana3.lopez@bellaestilo.pe").param("telefono", "987654321")
                .param("claveInicial", "Estilista456").param("especialidad", "Corte").param("servicioIds", "1").param("dias", "1")
                .param("horaInicio", "18:00").param("horaFin", "09:00"))
            .andExpect(redirectedUrl("/admin/estilistas?error"));
    }

    @Test
    void redireccionAbierta_sinListaBlanca_seIgnora() throws Exception {   // open redirect en "volver"
        mvc.perform(post("/admin/citas/1/confirmar").with(user(ADMIN).roles("ADMINISTRADOR")).with(csrf()).param("volver", "https://sitio-malicioso.example"))
            .andExpect(result -> {
                String destino = result.getResponse().getRedirectedUrl();
                assertTrue(destino == null || !destino.contains("sitio-malicioso"), "no debe redirigir a sitios externos");
            });
    }
}
