package pe.utp.peluqueria.seguridad;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class SeguridadAuditoriaTest {
    @Test
    void correo_seEnmascara() {
        assertEquals("j***@correo.com", AuditoriaSeguridad.enmascarar("juan.perez@correo.com"));
        assertEquals("(vacio)", AuditoriaSeguridad.enmascarar(null));
        assertEquals("(vacio)", AuditoriaSeguridad.enmascarar("  "));
    }

    @Test
    void saltosDeLinea_seNeutralizan() {
        String r = AuditoriaSeguridad.enmascarar("a\nLOGIN_OK usuario=admin@x.com");
        assertFalse(r.contains("\n"));
        assertFalse(AuditoriaSeguridad.limpiar("ruta\r\nFALSO").contains("\n"));
    }

    @Test
    void textoMuyLargo_seTrunca() {
        assertTrue(AuditoriaSeguridad.enmascarar("a".repeat(500) + "@x.com").length() <= 125);
    }
}
