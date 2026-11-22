# -*- coding: utf-8 -*-
"""
PRUEBAS FUNCIONALES - roles ADMINISTRADOR (recepcion) y ESTILISTA.
Conceptos: caja negra, CRUD de servicios, filtros, reportes, regresion de reglas por rol.
"""
import re

import pytest
from bs4 import BeautifulSoup

from helpers import aleatorio, destino, fecha_iso

pytestmark = pytest.mark.funcional


def _categoria_id(admin):
    soup = BeautifulSoup(admin.get("/admin/servicios").text, "html.parser")
    return soup.select_one("select[name=categoriaId] option")["value"]


def _id_servicio_por_nombre(admin, nombre):
    soup = BeautifulSoup(admin.get("/admin/servicios").text, "html.parser")
    for fila in soup.find_all("tr"):
        if nombre in fila.get_text():
            m = re.search(r"/admin/servicios/(\d+)/estado", str(fila))
            if m:
                return int(m.group(1))
    return None


# ------------------------------------------------------------------ administrador
@pytest.mark.parametrize("ruta", ["/admin/panel", "/admin/citas", "/admin/servicios", "/admin/estilistas",
                                  "/admin/clientes", "/admin/reportes/citas", "/admin/reportes/servicios"])
def test_admin_pantallas_principales_cargan(admin, ruta):
    assert admin.get(ruta).status_code == 200


def test_admin_inicio_lleva_al_panel(admin):
    assert destino(admin.get("/inicio")) == "/admin/panel"


def test_admin_filtro_de_citas_por_estado(admin):
    assert admin.get("/admin/citas?estado=PENDIENTE").status_code == 200
    assert admin.get("/admin/citas?estado=NO_EXISTE").status_code == 400


def test_admin_busqueda_de_clientes(admin):
    con = admin.get("/admin/clientes", params={"q": "valeria"})
    sin = admin.get("/admin/clientes", params={"q": "zzzz-no-existe-" + aleatorio()})
    assert "valeria.rojas@correo.com" in con.text
    assert "valeria.rojas@correo.com" not in sin.text


def test_admin_reportes_con_rango_de_fechas(admin):
    r = admin.get("/admin/reportes/citas", params={"desde": fecha_iso(-30), "hasta": fecha_iso(30)})
    assert r.status_code == 200
    assert admin.get("/admin/reportes/citas", params={"desde": "no-es-fecha"}).status_code == 400


def test_admin_crea_servicio_se_lista_y_al_desactivar_el_cliente_no_lo_ve(admin, cliente):
    """CRUD + regla: un servicio inactivo no aparece en el catalogo del cliente."""
    nombre = f"Servicio QA {aleatorio()}"
    r = admin.post("/admin/servicios", {"nombre": nombre, "descripcion": "creado por pruebas", "precio": "45.50",
                                        "duracionMin": "45", "categoriaId": _categoria_id(admin)})
    assert r.status_code == 302 and destino(r) == "/admin/servicios?guardado"
    assert nombre in admin.get("/admin/servicios").text
    assert nombre in cliente.get("/servicios").text            # nace activo
    sid = _id_servicio_por_nombre(admin, nombre)
    assert sid is not None
    try:
        r2 = admin.post(f"/admin/servicios/{sid}/estado", {"activo": "false"})
        assert r2.status_code == 302
        assert nombre not in cliente.get("/servicios").text     # ya inactivo
    finally:
        admin.post(f"/admin/servicios/{sid}/estado", {"activo": "false"})


# ------------------------------------------------------------------ estilista
def test_estilista_inicio_y_agenda(estilista):
    assert destino(estilista.get("/inicio")) == "/agenda"
    assert estilista.get("/agenda").status_code == 200
    assert estilista.get("/agenda", params={"fecha": "2020-01-01"}).status_code == 200


def test_estilista_agenda_con_fecha_invalida_responde_400(estilista):
    assert estilista.get("/agenda", params={"fecha": "basura"}).status_code == 400


def test_estilista_confirma_su_propia_cita_pendiente(estilista):
    """Si hay una cita PENDIENTE propia hoy (datos demo), la puede confirmar y vuelve a su agenda."""
    html = estilista.get("/agenda").text
    ids = re.findall(r"/admin/citas/(\d+)/confirmar", html)
    if not ids:
        pytest.skip("No hay citas pendientes propias hoy (ya confirmadas en una ejecucion anterior).")
    r = estilista.post(f"/admin/citas/{ids[0]}/confirmar", {"volver": "/agenda"})
    assert r.status_code == 302 and destino(r) == "/agenda"
