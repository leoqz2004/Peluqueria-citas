# -*- coding: utf-8 -*-
"""
PRUEBAS FUNCIONALES - zona publica (sin sesion).
Concepto de testing: caja negra, pruebas de humo (smoke) y de regresion.
"""
import pytest
from bs4 import BeautifulSoup

from helpers import BASE_URL, destino, registrar_usuario, Navegador, CLAVE_VALIDA, aleatorio

pytestmark = pytest.mark.funcional


def test_login_responde_y_tiene_formulario(anonimo):
    """Smoke: /login carga y trae usuario, clave y token CSRF."""
    r = anonimo.get("/login")
    assert r.status_code == 200
    soup = BeautifulSoup(r.text, "html.parser")
    assert soup.find("input", {"name": "username"}) and soup.find("input", {"name": "password"})
    assert soup.find("input", {"name": "_csrf"})


def test_registro_pagina_responde(anonimo):
    r = anonimo.get("/registro")
    assert r.status_code == 200 and "Crear cuenta" in r.text


@pytest.mark.parametrize("ruta,tipo", [("/css/app.css", "css"), ("/js/app.js", "javascript")])
def test_recursos_estaticos_publicos(anonimo, ruta, tipo):
    """Los recursos estaticos se sirven sin sesion (necesarios para la pantalla de login)."""
    r = anonimo.get(ruta)
    assert r.status_code == 200 and tipo in r.headers.get("Content-Type", "")


@pytest.mark.parametrize("ruta", ["/", "/servicios", "/reservar", "/mis-citas", "/notificaciones",
                                  "/admin/panel", "/admin/citas", "/agenda", "/ruta-que-no-existe"])
def test_rutas_privadas_sin_sesion_redirigen_a_login(anonimo, ruta):
    """Regresion de control de acceso basico: sin sesion todo redirige a /login."""
    r = anonimo.get(ruta)
    assert r.status_code == 302
    assert destino(r).startswith("/login")


def test_registro_valido_y_primer_login():
    """Flujo completo: registrarse -> iniciar sesion -> llegar al catalogo."""
    correo, r = registrar_usuario()
    assert r.status_code == 302 and destino(r) == "/login?registrado"
    nav = Navegador()
    resp = nav.login(correo, CLAVE_VALIDA)
    assert resp.status_code == 302 and destino(resp).endswith("/inicio")
    inicio = nav.get("/inicio")
    assert inicio.status_code == 302 and destino(inicio) == "/servicios"


def test_registro_correo_duplicado_no_crea_segunda_cuenta():
    correo, r = registrar_usuario()
    assert r.status_code == 302
    nav = Navegador()
    r2 = nav.post("/registro", {
        "nombres": "Otra", "apellidos": "Persona", "email": correo, "telefono": "+51 987 654 321",
        "password": CLAVE_VALIDA, "confirmPassword": CLAVE_VALIDA, "aceptaTerminos": "true"})
    assert r2.status_code == 200, "Debe volver al formulario con error, no redirigir"


def test_login_con_clave_incorrecta_vuelve_con_error(anonimo):
    r = anonimo.login(f"nadie.{aleatorio()}@pruebas.test", "Cualquier1")
    assert r.status_code == 302 and destino(r) == "/login?error"
    pagina = anonimo.get("/login?error")
    assert "Correo o contraseña incorrectos" in pagina.text
