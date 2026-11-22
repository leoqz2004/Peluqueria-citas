package pe.utp.peluqueria.seguridad;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.actuate.observability.AutoConfigureObservability;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

/** Semana 17: el monitoreo se expone sin abrir la superficie de ataque. */
@SpringBootTest @AutoConfigureMockMvc @AutoConfigureObservability
class SeguridadMonitoreoTest {
    @Autowired MockMvc mvc;

    /** Simula una peticion que llega desde fuera de las redes de confianza. */
    static RequestPostProcessor desdeInternet() {
        return request -> { request.setRemoteAddr("203.0.113.9"); return request; };
    }

    @Test
    void health_esPublico_yNoRevelaDetalles() throws Exception {
        mvc.perform(get("/actuator/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("UP"))
            .andExpect(jsonPath("$.components").doesNotExist());
    }

    @Test
    void prometheus_desdeInternetSinSesion_noSePermite() throws Exception {
        mvc.perform(get("/actuator/prometheus").with(desdeInternet()))
            .andExpect(status().is3xxRedirection());
    }

    @Test
    void prometheus_desdeInternetComoCliente_estaProhibido() throws Exception {
        mvc.perform(get("/actuator/prometheus").with(desdeInternet()).with(user("valeria@x.com").roles("CLIENTE")))
            .andExpect(status().isForbidden());
    }

    @Test
    void prometheus_desdeRedDeConfianza_exponeMetricasDeNegocio() throws Exception {
        mvc.perform(get("/actuator/prometheus"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("peluqueria_citas_por_estado")))
            .andExpect(content().string(containsString("peluqueria_login_fallidos")));
    }

    @Test
    void prometheus_comoAdministrador_seAccedeAunqueSeaDesdeInternet() throws Exception {
        mvc.perform(get("/actuator/prometheus").with(desdeInternet()).with(user("recepcion@bellaestilo.pe").roles("ADMINISTRADOR")))
            .andExpect(status().isOk());
    }

    @Test
    void cadaRespuesta_incluyeIdentificadorDePeticion() throws Exception {
        mvc.perform(get("/actuator/health")).andExpect(header().exists("X-Request-Id"));
    }
}
