package pe.utp.peluqueria.seguridad;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** A07 / A04: politica de contrasenas y almacenamiento con hash. */
class SeguridadPasswordTest {
    @ParameterizedTest
    @ValueSource(strings = {"Clave1234", "Estilista456", "Abcdefg1", "MiClaveSegura9"})
    void passwordsValidas_seAceptan(String clave) {
        assertTrue(PoliticaPassword.validar(clave, "ana@correo.com").isEmpty());
    }

    @ParameterizedTest
    @CsvSource({"Ab1,Mínimo 8 caracteres", "abcdefg1,Debe incluir una mayúscula", "ABCDEFG1,Debe incluir una minúscula",
        "Abcdefgh,Debe incluir un número", "Password1,Contraseña demasiado común"})
    void passwordsInvalidas_seRechazanConMensaje(String clave, String mensaje) {
        assertEquals(mensaje, PoliticaPassword.validar(clave, "ana@correo.com").orElseThrow());
    }

    @Test
    void passwordNulaOMuyLarga_seRechaza() {
        assertTrue(PoliticaPassword.validar(null, "a@a.com").isPresent());
        assertTrue(PoliticaPassword.validar("Aa1" + "x".repeat(70), "a@a.com").isPresent());
    }

    @Test
    void passwordQueContieneElCorreo_seRechaza() {
        assertTrue(PoliticaPassword.validar("Juanperez123", "juanperez@correo.com").isPresent());
    }

    @Test
    void hashBcrypt_noGuardaTextoPlanoYEsSalado() {
        BCryptPasswordEncoder enc = new BCryptPasswordEncoder();
        String h1 = enc.encode("Clave1234"), h2 = enc.encode("Clave1234");
        assertNotEquals("Clave1234", h1);
        assertNotEquals(h1, h2);                         // salt distinto
        assertTrue(h1.startsWith("$2"));
        assertTrue(enc.matches("Clave1234", h1));
    }

    @Test
    void limiteDeIntentos_bloqueaYSeReinicia() {
        LoginAttemptService s = new LoginAttemptService(3, 1);
        for (int i = 0; i < 2; i++) s.fallo("A@x.com");
        assertFalse(s.estaBloqueado("a@x.com"));
        s.fallo("a@x.com");
        assertTrue(s.estaBloqueado("a@x.com"));          // sin distinguir mayusculas
        s.exito("a@x.com");
        assertFalse(s.estaBloqueado("a@x.com"));
    }
}
