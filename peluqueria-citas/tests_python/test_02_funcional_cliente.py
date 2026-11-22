# -*- coding: utf-8 -*-
"""
PRUEBAS FUNCIONALES - rol CLIENTE.
Conceptos: caja negra, integracion (controlador + servicio + BD), regla de negocio RN (sin cruces de horario),
pruebas negativas y limpieza de datos (la cita creada se cancela al final).
"""
import re

import pytest

from helpers import (Navegador, buscar_horario, catalogo_reserva, destino, fecha_iso, ids_cancelables,
                     horarios_libres, cita_temporal)

pytestmark = pytest.mark.funcional


def test_inicio_del_cliente_lleva_al_catalogo(cliente):
    r = cliente.get("/inicio")
    assert r.status_code == 302 and destino(r) == "/servicios"


def test_catalogo_muestra_servicios_activos_y_oculta_inactivos(cliente):
    """RF catalogo: solo se listan servicios activos (el 'Alisado permanente' esta inactivo en la demo)."""
    r = cliente.get("/servicios")
    assert r.status_code == 200
    assert "Corte de cabello" in r.text and "Tinte y color" in r.text
    assert "Alisado permanente" not in r.text


def test_asistente_de_reserva_carga_con_estilistas(cliente):
    servicios, estilistas = catalogo_reserva(cliente)
    assert len(servicios) >= 1 and len(estilistas) >= 1


def test_horarios_libres_devuelve_json_con_horas(cliente):
    h = buscar_horario(cliente)
    assert h is not None, "Debe existir al menos un horario libre en los proximos dias"
    r = horarios_libres(cliente, h["estilistaId"], h["fecha"], h["servicioIds"])
    assert r.status_code == 200 and r.headers["Content-Type"].startswith("application/json")
    assert all(re.match(r"^\d{2}:\d{2}", x) for x in r.json())


@pytest.mark.parametrize("params", [
    {"estilista": "abc", "fecha": fecha_iso(3), "servicios": 1},      # tipo invalido
    {"estilista": 1, "fecha": "no-es-fecha", "servicios": 1},         # fecha invalida
    {"estilista": 1, "fecha": fecha_iso(3)},                          # falta 'servicios'
])
def test_horarios_con_parametros_invalidos_responde_400(cliente, params):
    """Prueba negativa: entradas mal formadas producen 400 controlado."""
    assert cliente.get("/reservar/horarios", params=params).status_code == 400


def test_flujo_reserva_cruce_y_cancelacion(cliente, admin):
    """
    Flujo E2E por HTTP: reservar -> aparece en 'Mis citas' -> reservar el MISMO horario es rechazado
    (RN: sin cruces) -> cancelar. La cita temporal se cancela al salir del bloque.
    """
    with cita_temporal(cliente, admin) as (cita_id, h):
        assert cita_id in ids_cancelables(cliente.get("/mis-citas", seguir=True).text)
        duplicada = cliente.post("/reservar", h)
        assert duplicada.status_code == 200
        assert "ya tiene una cita" in duplicada.text
        r = cliente.post(f"/citas/{cita_id}/cancelar", {"motivo": "prueba automatizada"})
        assert r.status_code == 302 and destino(r) == "/mis-citas?cancelada"
        assert cita_id not in ids_cancelables(cliente.get("/mis-citas", seguir=True).text)


@pytest.mark.parametrize("datos,descripcion", [
    ({"estilistaId": 1, "fecha": fecha_iso(3), "hora": "10:00"}, "sin servicios"),
    ({"estilistaId": 1, "servicioIds": [1], "fecha": fecha_iso(-1), "hora": "10:00"}, "fecha pasada"),
    ({"estilistaId": -5, "servicioIds": [1], "fecha": fecha_iso(3), "hora": "10:00"}, "estilista negativo"),
    ({"estilistaId": 1, "servicioIds": list(range(1, 12)), "fecha": fecha_iso(3), "hora": "10:00"}, "mas de 10 servicios"),
    ({"estilistaId": 1, "servicioIds": [1], "fecha": "xx", "hora": "10:00"}, "fecha con formato invalido"),
])
def test_reserva_invalida_vuelve_al_asistente(cliente, datos, descripcion):
    """Validacion de ReservaDto (Bean Validation); el caso se indica en `descripcion`."""
    r = cliente.post("/reservar", datos)
    assert r.status_code == 302 and destino(r) == "/reservar?error", descripcion


def test_mis_citas_y_notificaciones_cargan(cliente):
    assert cliente.get("/mis-citas").status_code == 200
    assert cliente.get("/notificaciones").status_code == 200


def test_guardar_preferencias_de_notificacion(cliente):
    r = cliente.post("/notificaciones/preferencias", {"whatsapp": "true", "correo": "true"})
    assert r.status_code == 302 and destino(r) == "/notificaciones?guardado"


def test_cerrar_sesion_invalida_el_acceso():
    nav = Navegador()
    assert nav.iniciar_sesion("cliente")
    assert nav.get("/servicios").status_code == 200
    r = nav.post("/logout")
    assert r.status_code == 302 and destino(r) == "/login?salir"
    assert destino(nav.get("/servicios")).startswith("/login")
