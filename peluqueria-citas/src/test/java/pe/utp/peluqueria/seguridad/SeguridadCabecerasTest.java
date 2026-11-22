package pe.utp.peluqueria.seguridad;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest @AutoConfigureMockMvc
class SeguridadCabecerasTest {
    @Autowired MockMvc mvc;

    @Test
    void login_incluyeCabecerasDefensivas() throws Exception {
        mvc.perform(get("/login"))
            .andExpect(status().isOk())
            .andExpect(header().string("X-Content-Type-Options", "nosniff"))
            .andExpect(header().string("X-Frame-Options", "DENY"))
            .andExpect(header().string("Referrer-Policy", "strict-origin-when-cross-origin"))
            .andExpect(header().string("Permissions-Policy", containsString("camera=()")))
            .andExpect(header().string("Content-Security-Policy", allOf(
                containsString("default-src 'self'"), containsString("frame-ancestors 'none'"), containsString("object-src 'none'"))));
    }

    @Test
    void https_incluyeHsts() throws Exception {
        mvc.perform(get("/login").secure(true))
            .andExpect(header().string("Strict-Transport-Security", containsString("max-age=31536000")));
    }

    @Test
    void respuestasPrivadas_noSeAlmacenanEnCache() throws Exception {
        mvc.perform(get("/login")).andExpect(header().string("Cache-Control", containsString("no-store")));
    }
}
