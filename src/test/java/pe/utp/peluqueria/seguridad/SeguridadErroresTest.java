package pe.utp.peluqueria.seguridad;

import static org.hamcrest.Matchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static pe.utp.peluqueria.DatosPrueba.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

/** A10 / A02: fallar de forma segura, sin trazas, SQL, rutas ni nombres de clases en la respuesta. */
@SpringBootTest @AutoConfigureMockMvc
class SeguridadErroresTest {
    @Autowired MockMvc mvc;

    static ResultMatcher sinDetallesTecnicos() {
        return content().string(allOf(not(containsString("Exception")), not(containsString("org.springframework")),
            not(containsString("java.lang")), not(containsString("pe.utp.peluqueria")), not(containsString("Whitelabel")),
            not(containsString("stackTrace")), not(containsString("hibernate"))));
    }

    @Test
    void parametroConTipoInvalido_devuelve400SinDetalles() throws Exception {
        mvc.perform(get("/reservar/horarios").param("estilista", "abc").param("fecha", "2030-01-01").param("servicios", "1")
                .with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isBadRequest()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void fechaInvalida_devuelve400SinDetalles() throws Exception {
        mvc.perform(get("/reservar/horarios").param("estilista", "1").param("fecha", "no-es-fecha").param("servicios", "1")
                .with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isBadRequest()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void parametroFaltante_devuelve400SinDetalles() throws Exception {
        mvc.perform(get("/reservar/horarios").with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isBadRequest()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void rutaInexistente_devuelve404SinDetalles() throws Exception {
        mvc.perform(get("/no-existe-esta-ruta").with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isNotFound()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void metodoNoPermitido_devuelve405SinDetalles() throws Exception {
        mvc.perform(delete("/mis-citas").with(user(CLIENTE).roles("CLIENTE")).with(csrf()))
            .andExpect(status().isMethodNotAllowed()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void citaInexistente_devuelve404SinDetalles() throws Exception {
        mvc.perform(post("/citas/99999999/cancelar").with(user(CLIENTE).roles("CLIENTE")).with(csrf()))
            .andExpect(status().isNotFound()).andExpect(sinDetallesTecnicos());
    }

    @Test
    void demasiadosServicios_seRechazaConMensajeControlado() throws Exception {
        mvc.perform(get("/reservar/horarios").param("estilista", "1").param("fecha", "2030-01-01")
                .param("servicios", "1,2,3,4,5,6,7,8,9,10,11").with(user(CLIENTE).roles("CLIENTE")))
            .andExpect(status().isOk()).andExpect(view().name("error-negocio"));
    }
}
