package pe.utp.peluqueria.seguridad;

import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class LoginAttemptService {
    private static final int MAX_ENTRADAS = 10_000;
    private record Estado(int fallos, Instant bloqueadoHasta) {}
    private final ConcurrentHashMap<String, Estado> intentos = new ConcurrentHashMap<>();
    private final int maxIntentos;
    private final Duration bloqueo;

    public LoginAttemptService(@Value("${app.seguridad.max-intentos:5}") int maxIntentos,
                               @Value("${app.seguridad.bloqueo-minutos:15}") int bloqueoMinutos) {
        this.maxIntentos = maxIntentos; this.bloqueo = Duration.ofMinutes(bloqueoMinutos);
    }

    private static String clave(String usuario) { return usuario == null ? "" : usuario.trim().toLowerCase(Locale.ROOT); }

    public void fallo(String usuario) {
        if (intentos.size() > MAX_ENTRADAS) purgar();
        intentos.merge(clave(usuario), new Estado(1, null), (a, b) -> {
            int n = a.fallos() + 1;
            return new Estado(n, n >= maxIntentos ? Instant.now().plus(bloqueo) : a.bloqueadoHasta());
        });
    }

    public void exito(String usuario) { intentos.remove(clave(usuario)); }

    public boolean estaBloqueado(String usuario) {
        Estado e = intentos.get(clave(usuario));
        if (e == null || e.bloqueadoHasta() == null) return false;
        if (Instant.now().isAfter(e.bloqueadoHasta())) { intentos.remove(clave(usuario)); return false; }
        return true;
    }

    private void purgar() {
        Instant ahora = Instant.now();
        intentos.entrySet().removeIf(en -> en.getValue().bloqueadoHasta() == null || ahora.isAfter(en.getValue().bloqueadoHasta()));
    }
}
