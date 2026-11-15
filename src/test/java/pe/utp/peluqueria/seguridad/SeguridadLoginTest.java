package pe.utp.peluqueria.seguridad;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.CLIENTE;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

/** A07: autenticacion. Mensaje generico, limite de intentos y sesion nueva al autenticar (SEG-03). */
@SpringBootTest @AutoConfigureMockMvc
class SeguridadLoginTest {
    @Autowired MockMvc mvc;

    @Test
    void credencialesValidas_ingresan() throws Exception {
        mvc.perform(post("/login").param("username", CLIENTE).param("password", "Cliente123!").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/inicio"));
    }

    @Test   // la respuesta no revela si el usuario existe
    void usuarioExistenteYNoExistente_recibenLaMismaRespuesta() throws Exception {
        mvc.perform(post("/login").param("username", CLIENTE).param("password", "incorrecta").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?error"));
        mvc.perform(post("/login").param("username", "no.existe.nadie@correo.com").param("password", "incorrecta").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?error"));
    }

    @Test   // fuerza bruta: tras 5 fallos el usuario queda bloqueado temporalmente, aun con la clave correcta
    void tras5Fallos_elUsuarioSeBloquea() throws Exception {
        String victima = "bloqueo.prueba@correo.com";
        for (int i = 0; i < 5; i++)
            mvc.perform(post("/login").param("username", victima).param("password", "mala" + i).with(csrf()))
                .andExpect(redirectedUrl("/login?error"));
        mvc.perform(post("/login").param("username", victima).param("password", "OtraClave123").with(csrf()))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/login?bloqueado"));
    }

    @Test   // el bloqueo de un usuario no afecta a los demas
    void elBloqueo_esPorUsuario() throws Exception {
        for (int i = 0; i < 5; i++)
            mvc.perform(post("/login").param("username", "otra.victima@correo.com").param("password", "x" + i).with(csrf()));
        mvc.perform(post("/login").param("username", "milagros@bellaestilo.pe").param("password", "Estilista123!").with(csrf()))
            .andExpect(redirectedUrl("/inicio"));
    }
}
