# -*- coding: utf-8 -*-
"""
PRUEBAS E2E (extremo a extremo) con navegador real (Playwright para Python).
Concepto: se prueba la interfaz tal como la usa una persona, incluido el JavaScript del sitio
(filtros del catalogo y asistente de reserva de 4 pasos) y la politica CSP.

Ejecutar visible durante la sustentacion:  set E2E_HEADED=1  (Windows)  /  E2E_HEADED=1 (Linux/macOS)
Requiere:  pip install playwright   y   playwright install chromium
"""
import os

import pytest

from helpers import BASE_URL, USUARIOS, aleatorio

playwright_sync = pytest.importorskip("playwright.sync_api", reason="Instale playwright para las pruebas E2E")
expect = playwright_sync.expect

pytestmark = pytest.mark.e2e


@pytest.fixture(scope="module")
def navegador():
    with playwright_sync.sync_playwright() as p:
        try:
            b = p.chromium.launch(headless=os.getenv("E2E_HEADED") != "1", slow_mo=300 if os.getenv("E2E_HEADED") == "1" else 0)
        except Exception as ex:                                          # navegador no instalado
            pytest.skip(f"Chromium no disponible (ejecute `playwright install chromium`): {ex}")
        yield b
        b.close()


@pytest.fixture
def pagina(navegador):
    ctx = navegador.new_context(base_url=BASE_URL, locale="es-PE")
    pg = ctx.new_page()
    pg.set_default_timeout(10000)
    yield pg
    ctx.close()


def _login(pg, rol):
    correo, clave, _ = USUARIOS[rol]
    pg.goto("/login")
    pg.fill("#username", correo)
    pg.fill("#password", clave)
    pg.click("button.btn")


def test_login_incorrecto_muestra_mensaje(pagina):
    pagina.goto("/login")
    pagina.fill("#username", f"nadie.{aleatorio()}@pruebas.test")
    pagina.fill("#password", "Incorrecta1")
    pagina.click("button.btn")
    expect(pagina.locator(".errmsg")).to_contain_text("Correo o contraseña incorrectos")


def test_login_cliente_lleva_al_catalogo(pagina):
    _login(pagina, "cliente")
    expect(pagina).to_have_url(f"{BASE_URL}/servicios")
    expect(pagina.locator("h1")).to_have_text("Catálogo de servicios")


def test_catalogo_filtra_por_categoria_y_busqueda(pagina):
    _login(pagina, "cliente")
    pagina.wait_for_url("**/servicios")
    todas = pagina.locator(".svc-card:visible").count()
    pagina.click("button[data-filtro='Corte']")
    visibles = pagina.locator(".svc-card:visible")
    assert 0 < visibles.count() <= todas
    for i in range(visibles.count()):
        assert visibles.nth(i).get_attribute("data-cat") == "Corte"
    pagina.click("button[data-filtro='Todos']")
    pagina.fill("#buscar-servicio", "tinte")
    expect(pagina.locator(".svc-card:visible")).to_have_count(1)
    expect(pagina.locator(".svc-card:visible h3")).to_contain_text("Tinte")


def test_asistente_de_reserva_llega_hasta_la_confirmacion(pagina):
    """Recorre los 4 pasos (servicio -> estilista -> horario -> confirmar) SIN guardar la cita."""
    _login(pagina, "cliente")
    pagina.wait_for_url("**/servicios")
    pagina.locator(".svc-card a.btn").first.click()
    expect(pagina.locator("#wizard")).to_be_visible()
    expect(pagina.locator("input[name=servicioIds]:checked")).to_have_count(1)
    pagina.locator(".paso-panel[data-paso='1'] .btn-sig").click()
    pagina.locator(".est-card:not(.hidden)").first.click()
    pagina.locator(".paso-panel[data-paso='2'] .btn-sig").click()
    elegido = False
    for i in range(14):                                                  # primer dia con horarios libres
        pagina.locator("#dias button.dia").nth(i).click()
        try:
            pagina.locator("#slots .slot").first.wait_for(timeout=2500)
            pagina.locator("#slots .slot").first.click()
            elegido = True
            break
        except Exception:
            continue
    assert elegido, "No se encontro ningun dia con horarios libres en 14 dias"
    pagina.locator(".paso-panel[data-paso='3'] .btn-sig").click()
    expect(pagina.locator("#conf-total")).to_contain_text("S/")
    expect(pagina.locator("#conf-servicios")).not_to_be_empty()


def test_csp_no_genera_violaciones_en_las_pantallas_principales(pagina):
    """Si la CSP bloqueara algun recurso o script propio, el navegador lo registra en consola."""
    violaciones = []
    pagina.on("console", lambda m: violaciones.append(m.text) if "Content Security Policy" in m.text or "Refused to" in m.text else None)
    pagina.goto("/login")
    _login(pagina, "cliente")
    pagina.wait_for_url("**/servicios")
    pagina.goto("/reservar")
    pagina.goto("/mis-citas")
    assert not violaciones, f"Violaciones CSP: {violaciones}"


def test_cliente_en_zona_admin_ve_acceso_denegado(pagina):
    _login(pagina, "cliente")
    pagina.wait_for_url("**/servicios")
    resp = pagina.goto("/admin/panel")
    assert resp.status == 403
    expect(pagina.locator("body")).to_contain_text("No tienes permiso")


def test_cerrar_sesion_muestra_mensaje(pagina):
    _login(pagina, "cliente")
    pagina.wait_for_url("**/servicios")
    pagina.click("header.topnav button.link")
    expect(pagina).to_have_url(f"{BASE_URL}/login?salir")
    expect(pagina.locator(".okmsg")).to_contain_text("Sesión cerrada")


def test_administrador_ve_el_panel_y_su_menu(pagina):
    _login(pagina, "admin")
    expect(pagina).to_have_url(f"{BASE_URL}/admin/panel")
    expect(pagina.locator("aside.sidebar a.item", has_text="Citas")).to_be_visible()
