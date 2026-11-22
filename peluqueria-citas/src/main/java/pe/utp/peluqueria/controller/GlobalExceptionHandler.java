package pe.utp.peluqueria.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.TypeMismatchException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.ui.Model;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.*;
import pe.utp.peluqueria.exception.*;
import pe.utp.peluqueria.seguridad.AuditoriaSeguridad;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger LOG = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler({CruceHorarioException.class, ReglaNegocioException.class})
    public String reglaNegocio(RuntimeException ex, Model model) {
        model.addAttribute("mensaje", ex.getMessage());
        return "error-negocio";
    }
    @ExceptionHandler(RecursoNoEncontradoException.class)
    @ResponseStatus(org.springframework.http.HttpStatus.NOT_FOUND)
    public String noEncontrado(RecursoNoEncontradoException ex, Model model) {
        model.addAttribute("mensaje", ex.getMessage());
        return "error-negocio";
    }
    @ExceptionHandler(AccessDeniedException.class)
    @ResponseStatus(org.springframework.http.HttpStatus.FORBIDDEN)
    public String prohibido(Model model) {
        model.addAttribute("mensaje", "No tienes permiso para esta operacion");
        return "error-negocio";
    }

    @ExceptionHandler(Exception.class)
    public String inesperado(Exception ex, HttpServletRequest req, HttpServletResponse res, Model model) {
        int status = 500;
        if (ex instanceof ErrorResponse er) status = er.getStatusCode().value();
        else if (ex instanceof TypeMismatchException || ex instanceof ConstraintViolationException) status = 400;
        String ruta = AuditoriaSeguridad.limpiar(req.getRequestURI());
        if (status >= 500) LOG.error("Error interno {} {}", req.getMethod(), ruta, ex);
        else LOG.warn("Solicitud rechazada ({}) {} {}: {}", status, req.getMethod(), ruta, ex.getClass().getSimpleName());
        res.setStatus(status);
        model.addAttribute("mensaje", status >= 500
            ? "Ocurrió un error inesperado. Intenta nuevamente más tarde."
            : status == 404 ? "El recurso solicitado no existe." : "La solicitud no es válida.");
        return "error-negocio";
    }
}
