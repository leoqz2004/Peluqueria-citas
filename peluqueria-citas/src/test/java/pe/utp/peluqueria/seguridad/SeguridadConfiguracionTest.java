package pe.utp.peluqueria.seguridad;

import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.nio.file.*;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

class SeguridadConfiguracionTest {
    static final Path RAIZ = Path.of(".");
    static final Pattern SECRETO_EN_CODIGO = Pattern.compile("(?i)(password|passwd|secret|api[_-]?key|token)\\w*\\s*=\\s*\"[^\"]{4,}\"");

    static String leer(String ruta) throws IOException { return Files.readString(RAIZ.resolve(ruta)); }

    static List<Path> archivos(String carpeta, String extension) throws IOException {
        try (Stream<Path> s = Files.walk(RAIZ.resolve(carpeta))) {
            return s.filter(p -> p.toString().endsWith(extension)).toList();
        }
    }

    @Test
    void propiedades_noExponenErroresNiConsolas() throws IOException {
        String p = leer("src/main/resources/application.properties");
        assertTrue(p.contains("server.error.include-stacktrace=never"));
        assertTrue(p.contains("server.error.include-message=never"));
        assertTrue(p.contains("spring.h2.console.enabled=false"));
        assertTrue(p.contains("server.servlet.session.cookie.http-only=true"));
        assertTrue(p.contains("server.servlet.session.cookie.same-site=lax"));
        assertTrue(p.contains("server.servlet.session.timeout="));
        assertFalse(p.contains("show-sql=true"));
    }

    @Test
    void mysql_usaVariablesDeEntornoYCookieSegura() throws IOException {
        String p = leer("src/main/resources/application-mysql.properties");
        assertTrue(p.contains("spring.datasource.password=${DB_PASSWORD}"));
        assertTrue(p.contains("spring.datasource.username=${DB_USER}"));
        assertTrue(p.contains("useSSL=true"));
        assertTrue(p.contains("cookie.secure=${COOKIE_SECURE:true}"));
    }

    @Test
    void sqlserver_enviaValoresDeHoraComoTime() throws IOException {
        String p = leer("src/main/resources/application-sqlserver.properties");
        assertTrue(p.contains("spring.datasource.hikari.data-source-properties.sendTimeAsDatetime=false"));
        assertTrue(p.contains("sendTimeAsDatetime=false"));
        assertTrue(p.contains("spring.datasource.password=${DB_PASSWORD}"));
    }

    @Test
    void gitignore_excluyeSecretos() throws IOException {
        String g = leer(".gitignore");
        assertTrue(g.lines().anyMatch(l -> l.trim().equals(".env")));
        assertTrue(Files.exists(RAIZ.resolve(".env.example")));
        assertFalse(Files.exists(RAIZ.resolve(".env")), ".env real no debe estar dentro del proyecto entregado");
    }

    @Test
    void codigoFuente_sinSecretosEmbebidos() throws IOException {
        for (Path f : archivos("src/main/java", ".java")) {
            if (f.getFileName().toString().equals("DemoDataSeeder.java")) continue;
            assertFalse(SECRETO_EN_CODIGO.matcher(Files.readString(f)).find(), "Posible secreto embebido en " + f);
        }
    }

    @Test
    void codigoFuente_sinSqlConcatenadoNiNativoSinParametros() throws IOException {
        for (Path f : archivos("src/main/java", ".java")) {
            String c = Files.readString(f);
            assertFalse(c.contains("createNativeQuery("), "SQL nativo en " + f);
            assertFalse(c.contains("createStatement("), "Statement sin parametros en " + f);
            assertFalse(c.contains("nativeQuery = true"), "Consulta nativa en " + f);
            assertFalse(Pattern.compile("(?i)\"\\s*(select|update|delete|insert)[^\"]*\"\\s*\\+").matcher(c).find(), "SQL concatenado en " + f);
        }
    }

    @Test
    void plantillas_noUsanSalidaSinEscape() throws IOException {
        for (Path f : archivos("src/main/resources/templates", ".html")) {
            String c = Files.readString(f);
            assertFalse(c.contains("th:utext"), "th:utext (sin escape) en " + f);
            assertFalse(c.contains("href=\"javascript:"), "javascript: en " + f + " (bloqueado por CSP)");
            assertFalse(Pattern.compile("\\son(click|load|error|mouseover)=").matcher(c).find(), "manejador inline en " + f);
        }
    }

    @Test
    void formulariosPost_usanThAction_paraIncluirTokenCsrf() throws IOException {
        for (Path f : archivos("src/main/resources/templates", ".html")) {
            for (String linea : Files.readAllLines(f))
                if (linea.contains("method=\"post\"")) assertTrue(linea.contains("th:action"), "Formulario POST sin th:action (sin CSRF) en " + f + ": " + linea.strip());
        }
    }
}
