package pe.utp.peluqueria.seguridad;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.CLIENTE;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.mock.web.MockHttpSession;

@SpringBootTest @AutoConfigureMockMvc
class SeguridadLoginTest {
    @Autowired MockMvc mvc;

    @Test
    void sesionCaducada_noProvocaBucleDeRedireccion() throws Exception {
        var primera = mvc.perform(get("/login").with(req -> {
                req.setRequestedSessionId("sesion-vieja");
                req.setRequestedSessionIdValid(false);
                return req;
            }))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/login?expirada"))
            .andReturn();

        var renovada = (MockHttpSession) primera.getRequest().getSession(false);
        assertNotNull(renovada, "Se debe crear una sesion nueva antes de redirigir");
        mvc.perform(get("/login").session(renovada)).andExpect(status().isOk());
    }

    @Test
    void credencialesValidas_ingresan() throws Exception {
        mvc.perform(post("/login").param("username", CLIENTE).param("password", "Cliente123!").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/inicio"));
    }

    @Test
    void usuarioExistenteYNoExistente_recibenLaMismaRespuesta() throws Exception {
        mvc.perform(post("/login").param("username", CLIENTE).param("password", "incorrecta").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?error"));
        mvc.perform(post("/login").param("username", "no.existe.nadie@correo.com").param("password", "incorrecta").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?error"));
    }

    @Test
    void tras5Fallos_elUsuarioSeBloquea() throws Exception {
        String victima = "bloqueo.prueba@correo.com";
        for (int i = 0; i < 5; i++)
            mvc.perform(post("/login").param("username", victima).param("password", "mala" + i).with(csrf()))
                .andExpect(redirectedUrl("/login?error"));
        mvc.perform(post("/login").param("username", victima).param("password", "OtraClave123").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?bloqueado"));
    }

    @Test
    void elBloqueo_esPorUsuario() throws Exception {
        for (int i = 0; i < 5; i++)
            mvc.perform(post("/login").param("username", "otra.victima@correo.com").param("password", "x" + i).with(csrf()));
        mvc.perform(post("/login").param("username", "milagros@bellaestilo.pe").param("password", "Estilista123!").with(csrf()))
            .andExpect(redirectedUrl("/inicio"));
    }
}
