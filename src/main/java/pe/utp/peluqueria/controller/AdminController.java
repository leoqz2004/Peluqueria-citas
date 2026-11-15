package pe.utp.peluqueria.controller;

import jakarta.validation.Valid;
import java.security.Principal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import pe.utp.peluqueria.dto.EstilistaDto;
import pe.utp.peluqueria.dto.ServicioDto;
import pe.utp.peluqueria.seguridad.PoliticaPassword;
import pe.utp.peluqueria.model.Cita;
import pe.utp.peluqueria.model.EstadoCita;
import pe.utp.peluqueria.repository.CitaRepository;
import pe.utp.peluqueria.service.*;

/** Paneles del administrador / recepción (P09–P13). */
@Controller
@RequestMapping("/admin")
public class AdminController {
    private static final Set<String> DESTINOS = Set.of("/admin/citas", "/admin/panel", "/agenda", "/inicio");
    private final CitaRepository citaRepo;
    private final CitaService citas;
    private final CatalogoService catalogo;
    private final ClienteAdminService clientes;
    private final UsuarioService usuarios;

    public AdminController(CitaRepository citaRepo, CitaService citas, CatalogoService catalogo, ClienteAdminService clientes,
                           UsuarioService usuarios) {
        this.citaRepo = citaRepo; this.citas = citas; this.catalogo = catalogo; this.clientes = clientes; this.usuarios = usuarios;
    }

    /** P09: panel de recepción. */
    @GetMapping("/panel")
    public String panel(Model m) {
        LocalDate hoy = LocalDate.now();
        List<Cita> deHoy = citaRepo.entreFechas(hoy, hoy);
        m.addAttribute("hoy", hoy);
        m.addAttribute("citas", deHoy);
        m.addAttribute("total", deHoy.size());
        m.addAttribute("pendientes", deHoy.stream().filter(c -> c.getEstado() == EstadoCita.PENDIENTE).count());
        m.addAttribute("atendidas", deHoy.stream().filter(c -> c.getEstado() == EstadoCita.ATENDIDA).count());
        m.addAttribute("canceladas", deHoy.stream().filter(c -> c.getEstado() == EstadoCita.CANCELADA).count());
        return "admin/panel";
    }

    /** P10: gestión de citas con filtro por estado. */
    @GetMapping("/citas")
    public String citas(@RequestParam(required = false) EstadoCita estado, Model m) {
        LocalDate hoy = LocalDate.now();
        List<Cita> todas = citaRepo.entreFechas(hoy.minusDays(30), hoy.plusDays(90));
        m.addAttribute("citas", estado == null ? todas : todas.stream().filter(c -> c.getEstado() == estado).toList());
        m.addAttribute("estado", estado);
        for (EstadoCita e : EstadoCita.values())
            m.addAttribute("n" + e.name(), todas.stream().filter(c -> c.getEstado() == e).count());
        m.addAttribute("nTODAS", todas.size());
        return "admin/citas";
    }

    @PostMapping("/citas/{id}/confirmar")
    public String confirmar(@PathVariable Long id, @RequestParam(defaultValue = "/inicio") String volver, Principal p) {
        citas.confirmar(id, usuarios.porEmail(p.getName()));
        return "redirect:" + (DESTINOS.contains(volver) ? volver : "/inicio");
    }

    /** P11: mantenimiento de servicios. */
    @GetMapping("/servicios")
    public String servicios(Model m) {
        m.addAttribute("servicios", catalogo.todosLosServicios());
        m.addAttribute("categorias", catalogo.categorias());
        return "admin/servicios";
    }

    @PostMapping("/servicios")
    public String crearServicio(@Valid @ModelAttribute ServicioDto dto, BindingResult br) {
        if (br.hasErrors()) return "redirect:/admin/servicios?error";
        catalogo.crearServicio(dto);
        return "redirect:/admin/servicios?guardado";
    }

    @PostMapping("/servicios/{id}")
    public String editarServicio(@PathVariable Long id, @Valid @ModelAttribute ServicioDto dto, BindingResult br) {
        if (br.hasErrors()) return "redirect:/admin/servicios?error";
        catalogo.actualizarServicio(id, dto);
        return "redirect:/admin/servicios?guardado";
    }

    @PostMapping("/servicios/{id}/estado")
    public String estadoServicio(@PathVariable Long id, @RequestParam boolean activo) {
        catalogo.cambiarEstadoServicio(id, activo);
        return "redirect:/admin/servicios";
    }

    /** P12: estilistas y horarios. */
    @GetMapping("/estilistas")
    public String estilistas(@RequestParam(required = false) Long id, Model m) {
        var lista = catalogo.estilistasActivos();
        var elegido = lista.stream().filter(e -> e.getId().equals(id)).findFirst().orElse(lista.isEmpty() ? null : lista.get(0));
        m.addAttribute("estilistas", lista);
        m.addAttribute("elegido", elegido);
        m.addAttribute("horarios", elegido == null ? List.of() : catalogo.horariosDe(elegido.getId()));
        m.addAttribute("servicios", catalogo.catalogoActivo());
        return "admin/estilistas";
    }

    @PostMapping("/estilistas")
    public String crearEstilista(@Valid @ModelAttribute EstilistaDto dto, BindingResult br) {
        if (br.hasErrors() || PoliticaPassword.validar(dto.getClaveInicial(), dto.getEmail()).isPresent())
            return "redirect:/admin/estilistas?error";
        if (!dto.getHoraFin().isAfter(dto.getHoraInicio())) return "redirect:/admin/estilistas?error";
        catalogo.crearEstilista(dto.getNombres().trim(), dto.getApellidos().trim(), dto.getEmail().trim(), dto.getTelefono().trim(),
            dto.getClaveInicial(), dto.getEspecialidad().trim(), dto.getServicioIds(), dto.getDias(), dto.getHoraInicio(), dto.getHoraFin());
        return "redirect:/admin/estilistas";
    }

    /** P13: clientes. */
    @GetMapping("/clientes")
    public String clientes(@RequestParam(required = false) String q, Model m) {
        String busqueda = q == null ? "" : q.trim();
        if (busqueda.length() > 80) busqueda = busqueda.substring(0, 80);          // A05: tope de longitud
        m.addAttribute("clientes", clientes.listar(busqueda));
        m.addAttribute("q", busqueda);
        return "admin/clientes";
    }
}
