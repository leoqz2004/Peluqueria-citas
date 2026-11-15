package pe.utp.peluqueria.dto;

import static org.junit.jupiter.api.Assertions.*;

import jakarta.validation.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;

/** Pruebas unitarias de validacion (RF-01 Registro de cliente). */
class RegistroDtoTest {
    static final Validator V = Validation.buildDefaultValidatorFactory().getValidator();

    static RegistroDto valido() {
        RegistroDto d = new RegistroDto();
        d.setNombres("Ana"); d.setApellidos("Diaz"); d.setEmail("ana@correo.com"); d.setTelefono("+51 987 654 321");
        d.setPassword("Clave1234"); d.setConfirmPassword("Clave1234"); d.setAceptaTerminos(true);
        return d;
    }

    static long errores(RegistroDto d, String campo) {
        return V.validate(d).stream().filter(v -> v.getPropertyPath().toString().equals(campo)).count();
    }

    @Test
    void datosValidos_sinErrores() { assertTrue(V.validate(valido()).isEmpty()); }

    @ParameterizedTest @ValueSource(strings = {"", "   "})
    void nombresVacios_seRechazan(String valor) {
        RegistroDto d = valido(); d.setNombres(valor);
        assertTrue(errores(d, "nombres") > 0);
    }

    @ParameterizedTest @ValueSource(strings = {"abc", "a@", "sin-arroba.com"})
    void correoInvalido_seRechaza(String valor) {
        RegistroDto d = valido(); d.setEmail(valor);
        assertTrue(errores(d, "email") > 0);
    }

    @ParameterizedTest @ValueSource(strings = {"123456", "abcdefgh", "9876543210123456789"})
    void telefonoInvalido_seRechaza(String valor) {
        RegistroDto d = valido(); d.setTelefono(valor);
        assertTrue(errores(d, "telefono") > 0);
    }

    @ParameterizedTest @CsvSource({"1234567,false", "12345678,true"})
    void passwordLimiteMinimo8(String clave, boolean esperado) {
        RegistroDto d = valido(); d.setPassword(clave);
        assertEquals(esperado, errores(d, "password") == 0);
    }

    @Test
    void sinAceptarTerminos_seRechaza() {
        RegistroDto d = valido(); d.setAceptaTerminos(false);
        assertTrue(errores(d, "aceptaTerminos") > 0);
    }
}
