package pe.utp.peluqueria.seguridad;

import java.util.Locale;
import java.util.Optional;
import java.util.Set;

/** A07: politica minima de contrasenas (longitud, complejidad, no derivada del correo, no comun). */
public final class PoliticaPassword {
    private static final Set<String> COMUNES = Set.of("12345678", "123456789", "1234567890", "password", "password1",
        "qwerty123", "abc12345", "admin123", "contrasena1", "iloveyou1", "bellaestilo1");
    private PoliticaPassword() {}

    /** @return mensaje de error, o vacio si la contrasena cumple la politica. */
    public static Optional<String> validar(String clave, String email) {
        if (clave == null || clave.length() < 8) return Optional.of("Mínimo 8 caracteres");
        if (clave.length() > 60) return Optional.of("Máximo 60 caracteres");
        if (!clave.chars().anyMatch(Character::isLowerCase)) return Optional.of("Debe incluir una minúscula");
        if (!clave.chars().anyMatch(Character::isUpperCase)) return Optional.of("Debe incluir una mayúscula");
        if (!clave.chars().anyMatch(Character::isDigit)) return Optional.of("Debe incluir un número");
        String bajo = clave.toLowerCase(Locale.ROOT);
        if (COMUNES.contains(bajo)) return Optional.of("Contraseña demasiado común");
        if (email != null && email.contains("@")) {
            String local = email.substring(0, email.indexOf('@')).toLowerCase(Locale.ROOT);
            if (local.length() >= 4 && bajo.contains(local)) return Optional.of("No uses tu correo dentro de la contraseña");
        }
        return Optional.empty();
    }
}
