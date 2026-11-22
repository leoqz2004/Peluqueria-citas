package pe.utp.peluqueria.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.time.LocalTime;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import pe.utp.peluqueria.exception.*;
import pe.utp.peluqueria.model.Servicio;
import pe.utp.peluqueria.repository.*;

class CatalogoServiceTest {
    ServicioRepository servicios = mock(ServicioRepository.class);
    EstilistaRepository estilistas = mock(EstilistaRepository.class);
    UsuarioRepository usuarios = mock(UsuarioRepository.class);
    CatalogoService service = new CatalogoService(servicios, mock(CategoriaServicioRepository.class), estilistas,
        mock(SedeRepository.class), mock(RolRepository.class), usuarios, mock(HorarioEstilistaRepository.class), new BCryptPasswordEncoder());

    @Test
    void catalogoActivo_devuelveLoQueEntregaElRepositorio() {
        Servicio s = new Servicio();
        when(servicios.findByActivoTrueOrderByCategoriaNombreAscNombreAsc()).thenReturn(List.of(s));
        assertEquals(List.of(s), service.catalogoActivo());
    }

    @Test
    void cambiarEstadoServicio_desactiva() {
        Servicio s = new Servicio();
        when(servicios.findById(1L)).thenReturn(Optional.of(s));
        service.cambiarEstadoServicio(1L, false);
        assertFalse(s.isActivo());
    }

    @Test
    void cambiarEstadoServicio_inexistente_lanzaNoEncontrado() {
        when(servicios.findById(9L)).thenReturn(Optional.empty());
        assertThrows(RecursoNoEncontradoException.class, () -> service.cambiarEstadoServicio(9L, true));
    }

    @Test
    void crearEstilista_correoDuplicado_seRechaza() {
        when(usuarios.existsByEmail("a@b.com")).thenReturn(true);
        assertThrows(ReglaNegocioException.class, () ->
            service.crearEstilista("A", "B", "a@b.com", "987", "Clave123!", "x", List.of(), Set.of(1), LocalTime.of(9, 0), LocalTime.of(18, 0)));
    }

    @ParameterizedTest @CsvSource({"10:00,09:00", "10:00,10:00"})
    void crearEstilista_horaFinNoMayorQueInicio_seRechaza(String ini, String fin) {
        assertThrows(ReglaNegocioException.class, () ->
            service.crearEstilista("A", "B", "a@b.com", "987", "Clave123!", "x", List.of(), Set.of(1), LocalTime.parse(ini), LocalTime.parse(fin)));
        verify(estilistas, never()).save(any());
    }
}
