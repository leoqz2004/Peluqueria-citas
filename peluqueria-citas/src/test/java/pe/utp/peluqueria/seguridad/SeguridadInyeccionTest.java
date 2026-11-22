package pe.utp.peluqueria.seguridad;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pe.utp.peluqueria.model.Cliente;
import pe.utp.peluqueria.repository.ClienteRepository;
import pe.utp.peluqueria.repository.RolRepository;
import pe.utp.peluqueria.repository.UsuarioRepository;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class SeguridadInyeccionTest {
    static final String ADMIN = "recepcion@bellaestilo.pe";
    @Autowired MockMvc mvc;
    @Autowired ClienteRepository clientes;
    @Autowired UsuarioRepository usuarios;
    @Autowired RolRepository roles;

    @ParameterizedTest
    @ValueSource(strings = {"' OR '1'='1", "' OR 1=1 --", "x'; DROP TABLE usuario; --", "%' UNION SELECT * FROM usuario --"})
    void busquedaDeClientes_conPayloadSql_noDevuelveTodo(String payload) throws Exception {
        assertTrue(clientes.buscar(payload).isEmpty());
        mvc.perform(get("/admin/clientes").param("q", payload).with(user(ADMIN).roles("ADMINISTRADOR")))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("valeria.rojas@correo.com"))));
        assertTrue(usuarios.count() > 0, "la tabla usuario debe seguir existiendo");
    }

    @Test
    void busquedaDeClientes_valida_siFunciona() throws Exception {
        mvc.perform(get("/admin/clientes").param("q", "valeria").with(user(ADMIN).roles("ADMINISTRADOR")))
            .andExpect(status().isOk()).andExpect(content().string(containsString("valeria.rojas@correo.com")));
    }

    @Test
    void busqueda_reflejadaEnElFormulario_seEscapa() throws Exception {
        mvc.perform(get("/admin/clientes").param("q", "<script>alert(1)</script>").with(user(ADMIN).roles("ADMINISTRADOR")))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("<script>alert(1)</script>"))));
    }

    @Test
    void datosAlmacenadosConHtml_seMuestranEscapados() throws Exception {
        Cliente c = new Cliente();
        c.setRol(roles.findByNombre("CLIENTE").orElseThrow());
        c.setNombres("<b>Negrita</b>"); c.setApellidos("Prueba"); c.setEmail("xss.prueba@correo.com");
        c.setTelefono("987654321"); c.setPasswordHash("hash");
        clientes.save(c);
        mvc.perform(get("/admin/clientes").with(user(ADMIN).roles("ADMINISTRADOR")))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("<b>Negrita</b>"))))
            .andExpect(content().string(containsString("&lt;b&gt;Negrita&lt;/b&gt;")));
    }
}
