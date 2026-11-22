# -*- coding: utf-8 -*-
"""
PRUEBAS DE SEGURIDAD - Control de acceso (OWASP A01) y CSRF.
Conceptos: autorizacion por rol (minimo privilegio), IDOR (acceso a objetos ajenos), caja negra,
pruebas negativas. Cada falla aqui seria una vulnerabilidad real: se registra como observacion.
"""
import re
from datetime import date

import pytest

from helpers import Navegador, destino, fecha_iso, ids_cancelables

pytestmark = pytest.mark.seguridad

RUTAS_ADMIN = ["/admin/panel", "/admin/citas", "/admin/servicios", "/admin/estilistas",
               "/admin/clientes", "/admin/reportes/citas", "/admin/reportes/servicios"]
RUTAS_CLIENTE = ["/servicios", "/reservar", "/mis-citas", "/notificaciones"]


# ------------------------------------------------------------ matriz ruta x rol
@pytest.mark.parametrize("ruta", RUTAS_ADMIN + ["/agenda"] + RUTAS_CLIENTE)
def test_anonimo_no_accede_a_rutas_privadas(anonimo, ruta):
    r = anonimo.get(ruta)
    assert r.status_code == 302 and destino(r).startswith("/login")


@pytest.mark.parametrize("ruta", RUTAS_ADMIN + ["/agenda"])
def test_cliente_no_accede_a_admin_ni_agenda(cliente, ruta):
    assert cliente.get(ruta).status_code == 403


@pytest.mark.parametrize("ruta", RUTAS_ADMIN + RUTAS_CLIENTE)
def test_estilista_no_accede_a_admin_ni_a_zona_cliente(estilista, ruta):
    assert estilista.get(ruta).status_code == 403


@pytest.mark.parametrize("ruta", ["/agenda", "/servicios", "/reservar", "/mis-citas", "/notificaciones"])
def test_admin_no_accede_a_agenda_ni_a_zona_cliente(admin, ruta):
    assert admin.get(ruta).status_code == 403


def test_cada_rol_si_accede_a_su_zona(cliente, admin, estilista):
    """Contrapeso de las pruebas negativas: el acceso legitimo sigue funcionando."""
    assert cliente.get("/servicios").status_code == 200
    assert admin.get("/admin/panel").status_code == 200
    assert estilista.get("/agenda").status_code == 200


# ------------------------------------------------------------ consolas y endpoints de gestion
@pytest.mark.parametrize("ruta", ["/h2-console", "/h2-console/", "/actuator", "/actuator/info",
                                  "/actuator/env", "/actuator/heapdump", "/actuator/beans"])
def test_consolas_y_actuator_no_expuestos(anonimo, admin, ruta):
    assert anonimo.get(ruta).status_code in (302, 401, 403, 404)
    assert admin.get(ruta).status_code in (403, 404)


def test_health_es_publico_y_no_revela_detalles(anonimo):
    """Semana 17: /actuator/health sirve al monitoreo; solo informa el estado general."""
    r = anonimo.get("/actuator/health")
    assert r.status_code == 200
    assert '"status":"UP"' in r.text.replace(" ", "")
    assert "components" not in r.text and "diskSpace" not in r.text


def test_metricas_para_administrador(admin):
    r = admin.get("/actuator/prometheus")
    assert r.status_code == 200
    assert "peluqueria_citas_por_estado" in r.text


# ------------------------------------------------------------ IDOR (objetos de otros usuarios)
def _cita_futura_de_valeria(cliente):
    ids = ids_cancelables(cliente.get("/mis-citas", seguir=True).text)
    if not ids:
        pytest.skip("El cliente demo no tiene citas futuras modificables.")
    return ids[0]


def test_idor_cliente_no_cancela_cita_ajena(cliente, cliente2):
    cita = _cita_futura_de_valeria(cliente)
    r = cliente2.post(f"/citas/{cita}/cancelar", {"motivo": "intento IDOR"})
    assert r.status_code == 403
    assert cita in ids_cancelables(cliente.get("/mis-citas", seguir=True).text), "La cita ajena fue cancelada"


def test_idor_cliente_no_reprograma_cita_ajena(cliente, cliente2):
    cita = _cita_futura_de_valeria(cliente)
    r = cliente2.post(f"/citas/{cita}/reprogramar", {"fecha": fecha_iso(12), "hora": "10:00"})
    assert r.status_code == 403


def test_idor_cliente_no_ve_horarios_de_cita_ajena(cliente, cliente2):
    cita = _cita_futura_de_valeria(cliente)
    assert cliente2.get(f"/citas/{cita}/horarios", params={"fecha": fecha_iso(12)}).status_code == 403


def _cita_de(nav, fecha, patron):
    ids = re.findall(patron, nav.get("/agenda", params={"fecha": fecha}).text)
    if not ids:
        pytest.skip("No hay cita demo para esa fecha (datos ya modificados).")
    return int(ids[0])


def test_idor_estilista_no_confirma_cita_de_otra_estilista(estilista, estilista2):
    """SEG-01 de la matriz: confirmar exige ser la estilista de la cita (o administrador)."""
    cita_rosa = _cita_de(estilista2, fecha_iso(5), r"/admin/citas/(\d+)/confirmar")
    r = estilista.post(f"/admin/citas/{cita_rosa}/confirmar", {"volver": "/agenda"})
    assert r.status_code == 403


def test_idor_estilista_no_marca_atendida_cita_ajena(estilista, estilista2):
    cita_rosa = _cita_de(estilista2, fecha_iso(0), r"/agenda/(\d+)/atendida")
    r = estilista.post(f"/agenda/{cita_rosa}/atendida", {"resultado": "ATENDIDA"})
    assert r.status_code == 403


# ------------------------------------------------------------ CSRF
@pytest.mark.parametrize("sesion,metodo_ruta", [
    ("anonimo", "/registro"),
    ("anonimo", "/login"),
    ("cliente", "/reservar"),
    ("cliente", "/citas/1/cancelar"),
    ("cliente", "/notificaciones/preferencias"),
    ("cliente", "/logout"),
    ("admin", "/admin/servicios"),
    ("admin", "/admin/servicios/1/estado"),
    ("estilista", "/agenda/1/atendida"),
])
def test_post_sin_token_csrf_es_rechazado(request, sesion, metodo_ruta):
    nav = request.getfixturevalue(sesion)
    r = nav.post(metodo_ruta, {"x": "1"}, con_csrf=False)
    assert r.status_code == 403


def test_post_con_token_csrf_falso_es_rechazado(cliente):
    r = cliente.post("/notificaciones/preferencias", {"correo": "true", "_csrf": "token-falso"}, con_csrf=False)
    assert r.status_code == 403


@pytest.mark.parametrize("sesion,ruta", [
    ("cliente", "/citas/1/cancelar"),
    ("admin", "/admin/servicios/1/estado"),
    ("admin", "/admin/citas/1/confirmar"),
])
def test_acciones_que_cambian_datos_no_se_hacen_por_get(request, sesion, ruta):
    """Las acciones que modifican datos solo aceptan POST (GET devuelve 405/404, nunca 200/302)."""
    r = request.getfixturevalue(sesion).get(ruta)
    assert r.status_code in (404, 405)


# ------------------------------------------------------------ observaciones conocidas (hallazgos documentados)
@pytest.mark.observacion
@pytest.mark.xfail(reason="OBS-01 (bajo): 404 vs 403 permite enumerar IDs de citas existentes. Mitigar respondiendo 404 en ambos casos.",
                   strict=False)
def test_obs01_no_se_puede_enumerar_ids_de_citas(cliente, cliente2):
    cita_existente_ajena = _cita_futura_de_valeria(cliente)
    existe = cliente2.post(f"/citas/{cita_existente_ajena}/cancelar", {"motivo": "x"}).status_code
    no_existe = cliente2.post("/citas/99999999/cancelar", {"motivo": "x"}).status_code
    assert existe == no_existe
