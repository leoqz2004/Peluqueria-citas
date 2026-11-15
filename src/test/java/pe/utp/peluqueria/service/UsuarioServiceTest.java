package pe.utp.peluqueria.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;
import org.junit.jupiter.api.*;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import pe.utp.peluqueria.dto.RegistroDto;
import pe.utp.peluqueria.exception.ReglaNegocioException;
import pe.utp.peluqueria.model.*;
import pe.utp.peluqueria.repository.*;

/** RF-01 Registro de cliente (servicio). */
class UsuarioServiceTest {
    UsuarioRepository usuarios = mock(UsuarioRepository.class);
    ClienteRepository clientes = mock(ClienteRepository.class);
    RolRepository roles = mock(RolRepository.class);
    BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    UsuarioService service = new UsuarioService(usuarios, clientes, roles, encoder);

    @BeforeEach
    void preparar() {
        Rol r = new Rol(); r.setNombre("CLIENTE");
        when(roles.findByNombre("CLIENTE")).thenReturn(Optional.of(r));
        when(clientes.save(any(Cliente.class))).thenAnswer(i -> i.getArgument(0));
    }

    RegistroDto dto(String email) {
        RegistroDto d = new RegistroDto();
        d.setNombres("Ana"); d.setApellidos("Diaz"); d.setEmail(email); d.setTelefono("987654321");
        d.setPassword("Clave1234"); d.setConfirmPassword("Clave1234"); d.setAceptaTerminos(true);
        return d;
    }

    @Test
    void registrar_valido_guardaCorreoEnMinusculaYClaveCifrada() {
        Cliente c = service.registrarCliente(dto("Ana@Correo.com"));
        assertEquals("ana@correo.com", c.getEmail());
        assertNotEquals("Clave1234", c.getPasswordHash());
        assertTrue(encoder.matches("Clave1234", c.getPasswordHash()));
    }

    @Test
    void registrar_correoDuplicado_seRechaza() {
        when(usuarios.existsByEmail("ana@correo.com")).thenReturn(true);
        assertThrows(ReglaNegocioException.class, () -> service.registrarCliente(dto("ana@correo.com")));
        verify(clientes, never()).save(any(Cliente.class));
    }

    @Test
    void registrar_correoDuplicadoConOtraCapitalizacion_seRechaza() {
        when(usuarios.existsByEmail("ana@correo.com")).thenReturn(true);
        assertThrows(ReglaNegocioException.class, () -> service.registrarCliente(dto("ANA@correo.com")));
    }

    @Test
    void login_usuarioInexistente_lanzaExcepcion() {
        when(usuarios.findByEmail("x@x.com")).thenReturn(Optional.empty());
        assertThrows(UsernameNotFoundException.class, () -> service.loadUserByUsername("x@x.com"));
    }

    @Test
    void login_usuarioInactivo_quedaDeshabilitado() {
        Usuario u = new Usuario(); Rol r = new Rol(); r.setNombre("CLIENTE");
        u.setRol(r); u.setEmail("a@a.com"); u.setPasswordHash("h"); u.setActivo(false);
        when(usuarios.findByEmail("a@a.com")).thenReturn(Optional.of(u));
        assertFalse(service.loadUserByUsername("a@a.com").isEnabled());
    }
}
