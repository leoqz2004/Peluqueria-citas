# -*- coding: utf-8 -*-
"""
Configuracion comun de pytest.

- Verifica que la aplicacion este levantada (o la levanta con START_APP=1 usando Maven).
- Define las sesiones por rol (cliente, administrador, estilista) como fixtures.
- Genera un resumen de la ejecucion al final.
"""
import os
import shutil
import signal
import subprocess
import sys
import time

import pytest
import requests

sys.path.insert(0, os.path.dirname(__file__))
from helpers import BASE_URL, Navegador, registrar_usuario, CLAVE_VALIDA  # noqa: E402

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
_proceso = {"p": None}


def _app_responde():
    try:
        return requests.get(BASE_URL + "/login", timeout=5, allow_redirects=False).status_code == 200
    except requests.RequestException:
        return False


def _detener_app():
    p = _proceso["p"]
    if not p:
        return
    try:
        if os.name == "nt":
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)], capture_output=True)
        else:
            os.killpg(os.getpgid(p.pid), signal.SIGTERM)
    except Exception:
        pass


@pytest.fixture(scope="session", autouse=True)
def aplicacion_en_ejecucion():
    """Comprueba (o inicia con START_APP=1) la aplicacion Spring Boot en BASE_URL."""
    if not _app_responde():
        if os.getenv("START_APP") == "1":
            if not shutil.which("mvn"):
                pytest.exit("START_APP=1 requiere Maven (mvn) en el PATH.", returncode=2)
            log = open(os.path.join(RAIZ, "app_pruebas.log"), "w", encoding="utf-8")
            kw = {"shell": True} if os.name == "nt" else {"start_new_session": True}
            _proceso["p"] = subprocess.Popen("mvn -q spring-boot:run" if os.name == "nt" else ["mvn", "-q", "spring-boot:run"],
                                             cwd=RAIZ, stdout=log, stderr=subprocess.STDOUT, **kw)
            limite = time.time() + 240
            while time.time() < limite and not _app_responde():
                if _proceso["p"].poll() is not None:
                    break
                time.sleep(3)
        if not _app_responde():
            _detener_app()
            pytest.exit(
                f"La aplicacion no responde en {BASE_URL}. Inicie la app con `mvn spring-boot:run` "
                "(perfil demo) en otra terminal, o ejecute con START_APP=1.", returncode=2)
    yield
    _detener_app()


def _sesion(rol):
    nav = Navegador()
    if not nav.iniciar_sesion(rol):
        pytest.skip(f"No se pudo iniciar sesion como '{rol}'. Se requiere el perfil demo "
                    f"(o definir TEST_{rol.upper()}_EMAIL / TEST_{rol.upper()}_PASSWORD).")
    return nav


@pytest.fixture
def anonimo():
    """Navegador sin sesion (nuevo en cada prueba para no compartir cookies)."""
    return Navegador()


@pytest.fixture(scope="session")
def cliente():
    return _sesion("cliente")


@pytest.fixture(scope="session")
def cliente2():
    return _sesion("cliente2")


@pytest.fixture(scope="session")
def admin():
    return _sesion("admin")


@pytest.fixture(scope="session")
def estilista():
    return _sesion("estilista")


@pytest.fixture(scope="session")
def estilista2():
    return _sesion("estilista2")


@pytest.fixture
def usuario_nuevo():
    """Cliente recien registrado (aislado): (correo, clave). Sirve para pruebas que alteran el estado de login."""
    correo, r = registrar_usuario()
    assert r.status_code == 302, "No se pudo registrar el usuario de prueba"
    return correo, CLAVE_VALIDA


def pytest_terminal_summary(terminalreporter):
    t = terminalreporter
    total = sum(len(v) for k, v in t.stats.items() if k in ("passed", "failed", "skipped", "error", "xfailed", "xpassed"))
    t.write_line(f"Resumen Bella Estilo: {total} pruebas | OK={len(t.stats.get('passed', []))} "
                 f"FALLOS={len(t.stats.get('failed', []))} OMITIDAS={len(t.stats.get('skipped', []))} "
                 f"OBSERVACIONES(xfail)={len(t.stats.get('xfailed', []))}")
