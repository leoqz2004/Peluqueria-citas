# -*- coding: utf-8 -*-
"""
Utilidades compartidas por las pruebas Python.

Idea general (caja negra): estas pruebas NO importan codigo Java. Se comportan como un
usuario/cliente HTTP externo contra la aplicacion ya levantada (perfil `demo`, H2 en memoria).
Por eso no tocan la conexion a MySQL / SQL Server ni el codigo de la aplicacion.
"""
import os
import re
import secrets
from contextlib import contextmanager
from datetime import date, timedelta
from urllib.parse import urlparse

import requests
from bs4 import BeautifulSoup

BASE_URL = os.getenv("BASE_URL", "http://localhost:8080").rstrip("/")
TIMEOUT = float(os.getenv("TEST_TIMEOUT", "20"))
CLAVE_VALIDA = "Prueba-Segura9"          # cumple PoliticaPassword (mayus., minus., numero, 8+)

# rol -> (correo, clave, pagina con formulario/CSRF tras iniciar sesion)
_DEMO = {
    "cliente":    ("valeria.rojas@correo.com", "Cliente123!", "/servicios"),
    "cliente2":   ("rosa.sanchez@correo.com", "Cliente123!", "/servicios"),
    "admin":      ("recepcion@bellaestilo.pe", "Admin123!", "/admin/panel"),
    "estilista":  ("milagros@bellaestilo.pe", "Estilista123!", "/agenda"),
    "estilista2": ("rosa@bellaestilo.pe", "Estilista123!", "/agenda"),
}
# Se pueden sobreescribir por variables de entorno: TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD, etc.
USUARIOS = {
    rol: (os.getenv(f"TEST_{rol.upper()}_EMAIL", c[0]), os.getenv(f"TEST_{rol.upper()}_PASSWORD", c[1]), c[2])
    for rol, c in _DEMO.items()
}


# ----------------------------------------------------------------- utilidades de texto
def aleatorio(n=6):
    return secrets.token_hex(n // 2 + 1)[:n]


def fecha_iso(dias=0):
    return (date.today() + timedelta(days=dias)).isoformat()


def extraer_csrf(html):
    tag = BeautifulSoup(html, "html.parser").find("input", attrs={"name": "_csrf"})
    return tag.get("value") if tag else None


def ids_cancelables(html):
    """IDs de citas con boton Cancelar (el modal usa /citas/0/..., se descarta)."""
    return sorted({int(i) for i in re.findall(r"/citas/(\d+)/cancelar", html) if int(i) > 0})


def destino(resp):
    """Ruta (sin host) a la que redirige una respuesta 3xx."""
    u = urlparse(resp.headers.get("Location", ""))
    return u.path + ("?" + u.query if u.query else "")


def host_destino(resp):
    return urlparse(resp.headers.get("Location", "")).netloc


# ----------------------------------------------------------------- navegador HTTP
class Navegador:
    """Sesion HTTP con cookies. No sigue redirecciones por defecto para poder verificarlas."""

    def __init__(self):
        self.s = requests.Session()
        self.s.headers["User-Agent"] = "pytest-bellaestilo/1.0"
        self.pagina_formulario = "/login"      # pagina de la que se toma el token CSRF

    @staticmethod
    def url(ruta):
        return ruta if ruta.startswith("http") else BASE_URL + ruta

    def get(self, ruta, seguir=False, **kw):
        return self.s.get(self.url(ruta), allow_redirects=seguir, timeout=TIMEOUT, **kw)

    def csrf(self):
        r = self.s.get(self.url(self.pagina_formulario), allow_redirects=True, timeout=TIMEOUT)
        return extraer_csrf(r.text)

    def post(self, ruta, datos=None, con_csrf=True, seguir=False, **kw):
        datos = dict(datos or {})
        if con_csrf:
            datos["_csrf"] = self.csrf()
        return self.s.post(self.url(ruta), data=datos, allow_redirects=seguir, timeout=TIMEOUT, **kw)

    def login(self, correo, clave):
        """Devuelve la respuesta del POST /login (302 a /inicio si es correcto)."""
        return self.post("/login", {"username": correo, "password": clave})

    def iniciar_sesion(self, rol):
        correo, clave, base = USUARIOS[rol]
        r = self.login(correo, clave)
        ok = r.status_code == 302 and destino(r).endswith("/inicio")
        if ok:
            self.pagina_formulario = base
        return ok

    def cookie_sesion(self):
        return self.s.cookies.get("JSESSIONID")


# ----------------------------------------------------------------- datos del asistente de reserva
def catalogo_reserva(nav):
    """Lee /reservar y devuelve (servicios_activos {id: nombre}, estilistas [{id, nombre, servicios:set}])."""
    html = nav.get("/reservar", seguir=True).text
    soup = BeautifulSoup(html, "html.parser")
    servicios = {}
    for inp in soup.select("input[name=servicioIds]"):
        etiqueta = inp.find_parent("label")
        servicios[int(inp["value"])] = (etiqueta.find("b").get_text(strip=True) if etiqueta and etiqueta.find("b") else "")
    estilistas = []
    for e in soup.select(".est-card"):
        ids = {int(x) for x in e.get("data-servicios", "").split(",") if x.strip()}
        estilistas.append({"id": int(e["data-id"]), "nombre": e.get("data-nombre", ""), "servicios": ids})
    return servicios, estilistas


def horarios_libres(nav, estilista_id, fecha, servicio_ids):
    r = nav.get("/reservar/horarios", params={"estilista": estilista_id, "fecha": fecha, "servicios": servicio_ids})
    return r


def buscar_horario(nav, desde=3, hasta=25):
    """Busca un estilista/servicio/fecha/hora libres. Devuelve dict o None."""
    servicios, estilistas = catalogo_reserva(nav)
    for dias in range(desde, hasta):
        fecha = fecha_iso(dias)
        for est in estilistas:
            for sid in sorted(est["servicios"] & set(servicios)):
                r = horarios_libres(nav, est["id"], fecha, [sid])
                if r.status_code == 200 and r.json():
                    return {"estilistaId": est["id"], "servicioIds": [sid], "fecha": fecha, "hora": r.json()[0]}
    return None


@contextmanager
def cita_temporal(cliente, admin):
    """
    Crea una cita real (como cliente) y la cancela al terminar (como administrador).
    Deja los datos demo como estaban. Devuelve (id_cita, horario).
    """
    h = buscar_horario(cliente)
    if h is None:
        raise RuntimeError("No hay horarios libres para crear una cita de prueba")
    antes = set(ids_cancelables(cliente.get("/mis-citas", seguir=True).text))
    r = cliente.post("/reservar", h)
    assert r.status_code == 302 and "creada" in destino(r), f"No se pudo crear la cita: {r.status_code} {destino(r)}"
    nuevas = set(ids_cancelables(cliente.get("/mis-citas", seguir=True).text)) - antes
    assert len(nuevas) == 1, "No se pudo identificar la cita recien creada"
    cita_id = nuevas.pop()
    try:
        yield cita_id, h
    finally:
        admin.post(f"/citas/{cita_id}/cancelar", {"motivo": "limpieza de pruebas automatizadas"})


def registrar_usuario(clave=CLAVE_VALIDA):
    """Registra un cliente nuevo (correo unico). Devuelve (correo, respuesta)."""
    correo = f"qa.{aleatorio(8)}@pruebas.test"
    nav = Navegador()
    r = nav.post("/registro", {
        "nombres": "Prueba", "apellidos": "Automatica", "email": correo, "telefono": "+51 987 654 321",
        "password": clave, "confirmPassword": clave, "aceptaTerminos": "true", "recordatorios": "true"})
    return correo, r
