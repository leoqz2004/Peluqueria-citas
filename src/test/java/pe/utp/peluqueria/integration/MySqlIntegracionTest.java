package pe.utp.peluqueria.integration;

import static org.junit.jupiter.api.Assertions.assertFalse;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import pe.utp.peluqueria.repository.ServicioRepository;

/**
 * Integracion con MySQL real. Equivale a TEST_DB_ENABLED del laboratorio: se omite (SKIPPED) salvo que
 * TEST_DB_ENABLED=1 y existan DB_USER / DB_PASSWORD con database/schema.sql ya ejecutado.
 */
@SpringBootTest @ActiveProfiles("mysql")
@EnabledIfEnvironmentVariable(named = "TEST_DB_ENABLED", matches = "1")
class MySqlIntegracionTest {
    @Autowired ServicioRepository servicios;

    @Test
    void listarServicios_desdeMySql() { assertFalse(servicios.findAll().isEmpty()); }
}
