# -*- coding: utf-8 -*-
"""
PRUEBAS DE SEGURIDAD - Configuracion segura, cabeceras, cookies y manejo de errores (OWASP A02, A10).
Conceptos: caja negra, inspeccion de cabeceras HTTP, "fallar de forma segura" (sin trazas ni versiones).
"""
import re

import pytest

from helpers import BASE_URL, Navegador, destino, extraer_csrf

pytestmark = pytest.mark.seguridad

CSP_DIRECTIVAS = ["default-src 'self'", "script-src 'self'", "object-src 'none'", "base-uri 'self'",
                  "form-action 'self'", "frame-ancestors 'none'"]
FUGAS = ["exception", "whitelabel", "stacktrace", "stack trace", "at org.", "at pe.utp", "at java.", "java.lang",
         "jakarta.", "springframework", "tomcat", "hibernate", "caused by"]


def _csp(resp):
    return resp.headers.get("Content-Security-Policy", "")


# ------------------------------------------------------------ cabeceras de seguridad
def test_cabeceras_defensivas_en_login(anonimo):
    h = anonimo.get("/login").headers
    assert h.get("X-Content-Type-Options", "").lower() == "nosniff"
    assert h.get("X-Frame-Options", "").upper() == "DENY"
    assert h.get("Referrer-Policy", "").lower() == "strict-origin-when-cross-origin"
    pp = h.get("Permissions-Policy", "")
    assert all(x in pp for x in ("camera=()", "microphone=()", "geolocation=()"))


@pytest.mark.parametrize("directiva", CSP_DIRECTIVAS)
def test_csp_contiene_directivas_clave(anonimo, directiva):
    assert directiva in _csp(anonimo.get("/login"))


def test_csp_no_permite_scripts_inseguros(anonimo):
    csp = _csp(anonimo.get("/login"))
    script_src = re.search(r"script-src([^;]*)", csp).group(1)
    assert "'unsafe-inline'" not in script_src and "'unsafe-eval'" not in script_src and "*" not in script_src


def test_paginas_autenticadas_no_se_guardan_en_cache(cliente):
    cc = cliente.get("/servicios").headers.get("Cache-Control", "").lower()
    assert "no-store" in cc


@pytest.mark.skipif(not BASE_URL.startswith("https://"), reason="HSTS solo se envia por HTTPS (en http://localhost no aplica)")
def test_hsts_activo_por_https(anonimo):
    assert "max-age=31536000" in anonimo.get("/login").headers.get("Strict-Transport-Security", "")


def test_no_se_revela_tecnologia_del_servidor(anonimo):
    h = anonimo.get("/login").headers
    assert "X-Powered-By" not in h
    assert not re.search(r"\d+\.\d+", h.get("Server", "")), "La cabecera Server revela una version"


def test_metodo_trace_no_esta_habilitado(anonimo):
    assert anonimo.s.request("TRACE", Navegador.url("/login"), allow_redirects=False, timeout=15).status_code != 200


# ------------------------------------------------------------ cookies y sesion
def _set_cookies(resp):
    return [c for c in resp.raw.headers.getlist("Set-Cookie")]


def test_cookie_de_sesion_httponly_y_samesite(anonimo):
    cookies = [c for c in _set_cookies(anonimo.get("/login")) if c.startswith("JSESSIONID")]
    assert cookies, "No se emitio cookie de sesion"
    c = cookies[0].lower()
    assert "httponly" in c and "samesite=lax" in c
    if BASE_URL.startswith("https://"):
        assert "secure" in c


def test_login_renueva_el_id_de_sesion_contra_fijacion(usuario_nuevo):
    """Session fixation: el JSESSIONID debe cambiar al autenticarse."""
    correo, clave = usuario_nuevo
    nav = Navegador()
    nav.get("/login")
    antes = nav.cookie_sesion()
    assert nav.login(correo, clave).status_code == 302
    assert antes and nav.cookie_sesion() and nav.cookie_sesion() != antes


def test_logout_invalida_la_sesion_en_el_servidor(usuario_nuevo):
    """Tras cerrar sesion, reusar la cookie anterior no da acceso."""
    correo, clave = usuario_nuevo
    nav = Navegador()
    assert nav.login(correo, clave).status_code == 302
    nav.pagina_formulario = "/servicios"
    cookie_vieja = nav.cookie_sesion()
    assert nav.post("/logout").status_code == 302
    robado = Navegador()
    robado.s.cookies.set("JSESSIONID", cookie_vieja)
    r = robado.get("/servicios")
    assert r.status_code == 302 and destino(r).startswith("/login")


# ------------------------------------------------------------ errores sin fuga de informacion (A10)
@pytest.mark.parametrize("sesion,ruta,esperado", [
    ("cliente", "/ruta-inexistente-" + "x" * 5, 404),
    ("cliente", "/reservar/horarios?estilista=abc&fecha=x&servicios=1", 400),
    ("cliente", "/citas/99999999/horarios?fecha=2030-01-01", 404),
    ("admin", "/admin/citas?estado=INVALIDO", 400),
    ("estilista", "/agenda?fecha=basura", 400),
    ("cliente", "/admin/panel", 403),
])
def test_errores_son_genericos_y_no_filtran_detalles(request, sesion, ruta, esperado):
    r = request.getfixturevalue(sesion).get(ruta)
    assert r.status_code == esperado
    bajo = r.text.lower()
    assert not [f for f in FUGAS if f in bajo], "La pagina de error expone detalles tecnicos"


def test_metodo_no_permitido_responde_405_generico(cliente):
    r = cliente.s.request("PUT", Navegador.url("/servicios"), data={"_csrf": cliente.csrf()}, timeout=15, allow_redirects=False)
    assert r.status_code in (403, 405)
    assert not [f for f in FUGAS if f in r.text.lower()]


# ------------------------------------------------------------ archivos y rutas sensibles (A02)
RUTAS_SENSIBLES = ["/.env", "/.git/config", "/pom.xml", "/application.properties", "/WEB-INF/web.xml",
                   "/META-INF/MANIFEST.MF", "/src/main/resources/application.properties",
                   "/database/schema.sql", "/database/SQLServer/01_BellaEstilo_Estructura.sql",
                   "/css/%2e%2e/%2e%2e/application.properties", "/static/../application.properties",
                   "/reportes_seguridad/matriz_hallazgos.md", "/README.md"]


@pytest.mark.parametrize("ruta", RUTAS_SENSIBLES)
def test_archivos_sensibles_no_se_sirven(anonimo, admin, ruta):
    assert anonimo.get(ruta).status_code != 200
    assert admin.get(ruta).status_code != 200


def test_no_hay_hashes_ni_secretos_en_pantallas_de_administracion(admin):
    for ruta in ("/admin/clientes", "/admin/estilistas", "/admin/panel", "/admin/citas"):
        texto = admin.get(ruta).text
        assert not re.search(r"\$2[aby]\$\d{2}\$", texto), f"Hash BCrypt expuesto en {ruta}"
        assert "passwordhash" not in texto.lower() and "password_hash" not in texto.lower()


def test_formularios_incluyen_token_csrf(anonimo, cliente, admin):
    assert extraer_csrf(anonimo.get("/login").text)
    assert extraer_csrf(anonimo.get("/registro").text)
    assert extraer_csrf(cliente.get("/notificaciones").text)
    assert extraer_csrf(admin.get("/admin/servicios").text)
