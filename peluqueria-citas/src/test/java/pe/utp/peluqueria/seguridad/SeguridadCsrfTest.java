package pe.utp.peluqueria.seguridad;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.*;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest @AutoConfigureMockMvc
class SeguridadCsrfTest {
    static final String ADMIN = "recepcion@bellaestilo.pe";
    @Autowired MockMvc mvc;

    @ParameterizedTest
    @ValueSource(strings = {"/registro", "/reservar", "/citas/1/cancelar", "/citas/1/reprogramar", "/notificaciones/preferencias", "/logout"})
    void postSinTokenCsrf_esRechazado_comoCliente(String ruta) throws Exception {
        mvc.perform(post(ruta).with(user(CLIENTE).roles("CLIENTE"))).andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"/admin/servicios", "/admin/servicios/1", "/admin/servicios/1/estado", "/admin/estilistas", "/admin/citas/1/confirmar"})
    void postSinTokenCsrf_esRechazado_comoAdmin(String ruta) throws Exception {
        mvc.perform(post(ruta).with(user(ADMIN).roles("ADMINISTRADOR"))).andExpect(status().isForbidden());
    }

    @Test
    void loginSinTokenCsrf_esRechazado() throws Exception {
        mvc.perform(post("/login").param("username", "a@a.com").param("password", "x")).andExpect(status().isForbidden());
    }

    @Test
    void confirmarPorGet_noEstaPermitido() throws Exception {
        mvc.perform(get("/admin/citas/1/confirmar").with(user(ADMIN).roles("ADMINISTRADOR"))).andExpect(status().isMethodNotAllowed());
    }

    @Test
    void cancelarPorGet_noEstaPermitido() throws Exception {
        mvc.perform(get("/citas/1/cancelar").with(user(CLIENTE).roles("CLIENTE"))).andExpect(status().isMethodNotAllowed());
    }
}
