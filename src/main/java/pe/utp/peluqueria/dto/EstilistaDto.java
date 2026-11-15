package pe.utp.peluqueria.dto;

import jakarta.validation.constraints.*;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import org.springframework.format.annotation.DateTimeFormat;

/** A05: validacion del alta de estilista (antes eran parametros sueltos sin validar). */
public class EstilistaDto {
    @NotBlank @Size(max = 80) @Pattern(regexp = "^[\\p{L} .'-]+$", message = "Caracteres no permitidos") private String nombres;
    @NotBlank @Size(max = 80) @Pattern(regexp = "^[\\p{L} .'-]+$", message = "Caracteres no permitidos") private String apellidos;
    @NotBlank @Email @Size(max = 120) private String email;
    @NotBlank @Pattern(regexp = "\\+?[0-9 ]{7,18}", message = "Teléfono inválido") private String telefono;
    @NotBlank @Size(min = 8, max = 60) private String claveInicial;
    @NotBlank @Size(max = 80) private String especialidad;
    @NotEmpty @Size(max = 30) private List<@NotNull @Positive Long> servicioIds;
    @NotEmpty @Size(max = 7) private Set<@Min(1) @Max(7) Integer> dias;
    @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) private LocalTime horaInicio;
    @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) private LocalTime horaFin;

    public String getNombres() { return nombres; }
    public void setNombres(String v) { this.nombres = v; }
    public String getApellidos() { return apellidos; }
    public void setApellidos(String v) { this.apellidos = v; }
    public String getEmail() { return email; }
    public void setEmail(String v) { this.email = v; }
    public String getTelefono() { return telefono; }
    public void setTelefono(String v) { this.telefono = v; }
    public String getClaveInicial() { return claveInicial; }
    public void setClaveInicial(String v) { this.claveInicial = v; }
    public String getEspecialidad() { return especialidad; }
    public void setEspecialidad(String v) { this.especialidad = v; }
    public List<Long> getServicioIds() { return servicioIds; }
    public void setServicioIds(List<Long> v) { this.servicioIds = v; }
    public Set<Integer> getDias() { return dias; }
    public void setDias(Set<Integer> v) { this.dias = v; }
    public LocalTime getHoraInicio() { return horaInicio; }
    public void setHoraInicio(LocalTime v) { this.horaInicio = v; }
    public LocalTime getHoraFin() { return horaFin; }
    public void setHoraFin(LocalTime v) { this.horaFin = v; }
}
