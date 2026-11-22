# -*- coding: utf-8 -*-
"""
PRUEBAS DE SEGURIDAD - Validacion de entradas, inyeccion SQL, XSS y redirecciones (OWASP A05).
Conceptos: pruebas negativas con cargas maliciosas (payloads), validacion en servidor, salida escapada.
Importante: todas las cargas usan datos/correos unicos para no bloquear cuentas reales de la demo.
"""
from urllib.parse import urlparse

import pytest

from helpers import (BASE_URL, CLAVE_VALIDA, Navegador, aleatorio, cita_temporal, destino, fecha_iso, host_destino)

pytestmark = pytest.mark.seguridad

ERRORES_SQL = ["sqlsyntax", "sqlserverexception", "sqlexception", "hibernate", "jdbc", "syntax error",
               "ora-0", "mysql", "unclosed quotation", "h2 database", "org.springframework"]
PAYLOADS_SQL = ["' OR '1'='1", "' OR 1=1 --", "admin'--", "'; DROP TABLE usuarios; --", "\" OR \"\"=\"",
                "' UNION SELECT NULL,NULL,NULL --", "1; WAITFOR DELAY '0:0:5' --"]
PAYLOADS_XSS = ["<script>alert(1)</script>", "\"><img src=x onerror=alert(1)>", "'><svg/onload=alert(1)>",
                "<iframe src=javascript:alert(1)>"]
RAW_XSS = ["<script>alert(1)</script>", "<img src=x onerror", "<svg/onload", "<iframe src=javascript"]


def _sin_fuga_sql(texto):
    bajo = texto.lower()
    return not any(e in bajo for e in ERRORES_SQL)


# ------------------------------------------------------------ SQL injection
@pytest.mark.parametrize("payload", PAYLOADS_SQL)
def test_sqli_en_login_no_autentica(anonimo, payload):
    """El campo usuario del login no permite inyeccion: nunca se inicia sesion ni hay error 500."""
    r = anonimo.login(f"{payload} {aleatorio()}", payload)
    assert r.status_code == 302
    assert destino(r).startswith("/login") and "/inicio" not in destino(r)


@pytest.mark.parametrize("payload", PAYLOADS_SQL)
def test_sqli_en_busqueda_de_clientes(admin, payload):
    """Consultas parametrizadas: el payload se trata como texto, no devuelve a todos los clientes ni errores SQL."""
    r = admin.get("/admin/clientes", params={"q": payload})
    assert r.status_code == 200
    assert _sin_fuga_sql(r.text)
    assert "valeria.rojas@correo.com" not in r.text


@pytest.mark.parametrize("estilista", ["1 OR 1=1", "1; DROP TABLE cita", "' OR '1'='1"])
def test_sqli_en_parametros_numericos_responde_400(cliente, estilista):
    r = cliente.get("/reservar/horarios", params={"estilista": estilista, "fecha": fecha_iso(3), "servicios": 1})
    assert r.status_code == 400 and _sin_fuga_sql(r.text)


# ------------------------------------------------------------ XSS reflejado
@pytest.mark.parametrize("payload", PAYLOADS_XSS)
def test_xss_reflejado_en_busqueda_se_escapa(admin, payload):
    r = admin.get("/admin/clientes", params={"q": payload})
    assert r.status_code == 200
    assert not any(raw in r.text for raw in RAW_XSS), "El payload aparece sin escapar en la respuesta"


@pytest.mark.parametrize("param", ["error", "bloqueado", "expirada", "registrado", "salir"])
def test_xss_en_parametros_de_login_no_se_refleja(anonimo, param):
    r = anonimo.get("/login", params={param: PAYLOADS_XSS[0]})
    assert r.status_code == 200 and not any(raw in r.text for raw in RAW_XSS)


# ------------------------------------------------------------ XSS almacenado
def test_xss_almacenado_en_nombre_de_servicio_se_escapa(admin, cliente):
    """Un administrador malicioso no puede inyectar script en el catalogo que ven los clientes."""
    from bs4 import BeautifulSoup
    import re
    nombre = f"<script>alert('{aleatorio()}')</script>"
    cat = BeautifulSoup(admin.get("/admin/servicios").text, "html.parser").select_one("select[name=categoriaId] option")["value"]
    admin.post("/admin/servicios", {"nombre": nombre, "descripcion": "xss", "precio": "10", "duracionMin": "30", "categoriaId": cat})
    sid = None
    for fila in BeautifulSoup(admin.get("/admin/servicios").text, "html.parser").find_all("tr"):
        m = re.search(r"/admin/servicios/(\d+)/estado", str(fila))
        if m and "alert(" in fila.get_text():
            sid = m.group(1)
    try:
        html = cliente.get("/servicios").text
        assert nombre not in html, "El nombre se renderizo sin escapar (XSS almacenado)"
        assert "&lt;script&gt;" in html
    finally:
        if sid:
            admin.post(f"/admin/servicios/{sid}/estado", {"activo": "false"})


# ------------------------------------------------------------ validacion del registro
def _registro(**cambios):
    datos = {"nombres": "Prueba", "apellidos": "Automatica", "email": f"qa.{aleatorio(8)}@pruebas.test",
             "telefono": "+51 987 654 321", "password": CLAVE_VALIDA, "confirmPassword": CLAVE_VALIDA,
             "aceptaTerminos": "true"}
    datos.update(cambios)
    if "password" in cambios and "confirmPassword" not in cambios:
        datos["confirmPassword"] = cambios["password"]
    return Navegador().post("/registro", datos)


@pytest.mark.parametrize("cambios,caso", [
    ({"password": "12345678"}, "clave comun / sin mayuscula"),
    ({"password": "password1"}, "clave comun"),
    ({"password": "Abcdefgh"}, "sin numero"),
    ({"password": "abcdefg1"}, "sin mayuscula"),
    ({"password": "ABCDEFG1"}, "sin minuscula"),
    ({"password": "Ab1"}, "demasiado corta"),
    ({"password": "A1" + "b" * 80}, "demasiado larga"),
    ({"confirmPassword": "Distinta123"}, "claves que no coinciden"),
    ({"email": "no-es-un-correo"}, "correo invalido"),
    ({"nombres": "<script>alert(1)</script>"}, "nombre con caracteres peligrosos"),
    ({"apellidos": "Robert'); DROP TABLE x;--"}, "apellido con SQL"),
    ({"nombres": "A" * 200}, "nombre demasiado largo"),
    ({"telefono": "abc"}, "telefono invalido"),
    ({"aceptaTerminos": "false"}, "sin aceptar terminos"),
])
def test_registro_invalido_es_rechazado(cambios, caso):
    r = _registro(**cambios)
    assert r.status_code == 200, f"Se acepto un registro invalido: {caso}"
    assert not any(raw in r.text for raw in RAW_XSS)


def test_registro_rechaza_clave_que_contiene_el_correo():
    local = f"usuario{aleatorio(4)}"
    r = _registro(email=f"{local}@pruebas.test", password=f"{local.capitalize()}9")
    assert r.status_code == 200


# ------------------------------------------------------------ validacion de formularios de administracion
@pytest.mark.parametrize("cambios,caso", [
    ({"precio": "-1"}, "precio negativo"),
    ({"precio": "100000"}, "precio sobre el maximo"),
    ({"precio": "abc"}, "precio no numerico"),
    ({"duracionMin": "4"}, "duracion bajo el minimo"),
    ({"duracionMin": "601"}, "duracion sobre el maximo"),
    ({"nombre": ""}, "nombre vacio"),
    ({"nombre": "N" * 81}, "nombre demasiado largo"),
    ({"categoriaId": ""}, "sin categoria"),
])
def test_servicio_invalido_es_rechazado(admin, cambios, caso):
    from bs4 import BeautifulSoup
    cat = BeautifulSoup(admin.get("/admin/servicios").text, "html.parser").select_one("select[name=categoriaId] option")["value"]
    datos = {"nombre": f"Valido {aleatorio()}", "descripcion": "x", "precio": "20", "duracionMin": "30", "categoriaId": cat}
    datos.update(cambios)
    r = admin.post("/admin/servicios", datos)
    assert r.status_code == 302 and destino(r) == "/admin/servicios?error", caso


def test_estilista_con_clave_debil_es_rechazado(admin):
    """Alta de estilista: una clave debil nunca crea la cuenta (el controlador responde ?error)."""
    r = admin.post("/admin/estilistas", {
        "nombres": "Qa", "apellidos": "Prueba", "email": f"estilista.{aleatorio()}@pruebas.test", "telefono": "987654321",
        "claveInicial": "123", "especialidad": "Corte", "horaInicio": "09:00", "horaFin": "18:00", "dias": "1"})
    assert r.status_code == 302 and destino(r) == "/admin/estilistas?error"


# ------------------------------------------------------------ redireccion abierta (open redirect)
@pytest.mark.parametrize("volver", ["https://evil.example", "//evil.example", "/\\evil.example", "javascript:alert(1)"])
def test_cancelar_no_redirige_a_sitios_externos(cliente, admin, volver):
    """El parametro `volver` solo acepta destinos de una lista blanca interna."""
    with cita_temporal(cliente, admin) as (cita_id, _):
        r = admin.post(f"/citas/{cita_id}/cancelar", {"motivo": "open redirect", "volver": volver})
        assert r.status_code == 302
        assert host_destino(r) in ("", urlparse(BASE_URL).netloc), "Redirige a un host externo"
        assert destino(r) == "/admin/citas"


def test_confirmar_no_redirige_a_sitios_externos(cliente, admin):
    with cita_temporal(cliente, admin) as (cita_id, _):
        r = admin.post(f"/admin/citas/{cita_id}/confirmar", {"volver": "https://evil.example"})
        assert r.status_code == 302 and destino(r) == "/inicio"
        assert "evil.example" not in r.headers.get("Location", "")
