# -*- coding: utf-8 -*-
"""
PRUEBAS DE SEGURIDAD - Autenticacion (OWASP A07).
Conceptos: mensajes genericos (anti enumeracion), bloqueo por intentos (fuerza bruta), aislamiento entre usuarios.
Las pruebas de bloqueo usan cuentas DESCARTABLES: nunca se bloquean los usuarios de la demo.
"""
import pytest

from helpers import CLAVE_VALIDA, Navegador, aleatorio, destino, registrar_usuario

pytestmark = pytest.mark.seguridad

MAX_INTENTOS = 5     # app.seguridad.max-intentos


def test_mensaje_generico_usuario_inexistente_y_clave_incorrecta(anonimo):
    """Anti enumeracion de usuarios: ambos casos responden exactamente igual."""
    a = anonimo.login(f"no.existe.{aleatorio()}@pruebas.test", "Cualquiera1")
    b = Navegador().login("carla.medina@correo.com", "ClaveIncorrecta1")      # usuario real, clave mala (1 solo fallo)
    assert (a.status_code, destino(a)) == (b.status_code, destino(b)) == (302, "/login?error")
    texto = anonimo.get("/login?error").text
    assert "Correo o contraseña incorrectos" in texto
    assert "no existe" not in texto.lower() and "usuario no" not in texto.lower()


def test_bloqueo_tras_5_intentos_fallidos_aun_con_clave_correcta():
    """Fuerza bruta: al 6.º intento la cuenta queda bloqueada, incluso con la clave correcta."""
    correo, r = registrar_usuario()
    assert r.status_code == 302
    nav = Navegador()
    for i in range(MAX_INTENTOS):
        resp = nav.login(correo, f"Incorrecta{i}A")
        assert destino(resp) == "/login?error", f"Intento {i + 1} debia ser un fallo normal"
    bloqueado = nav.login(correo, CLAVE_VALIDA)           # clave CORRECTA
    assert bloqueado.status_code == 302 and destino(bloqueado) == "/login?bloqueado"
    assert "Demasiados intentos" in nav.get("/login?bloqueado").text


def test_el_bloqueo_de_una_cuenta_no_afecta_a_las_demas():
    correo, _ = registrar_usuario()
    atacante = Navegador()
    for i in range(MAX_INTENTOS):
        atacante.login(correo, f"Mala{i}Clave")
    assert destino(Navegador().login(correo, CLAVE_VALIDA)) == "/login?bloqueado"
    otro = Navegador()
    assert otro.iniciar_sesion("cliente"), "Otro usuario debe poder iniciar sesion con normalidad"


def test_login_exitoso_reinicia_el_contador_de_fallos(usuario_nuevo):
    correo, clave = usuario_nuevo
    nav = Navegador()
    for i in range(MAX_INTENTOS - 1):
        nav.login(correo, f"Mala{i}Clave")
    assert destino(nav.login(correo, clave)).endswith("/inicio")          # exito: contador a cero
    for i in range(MAX_INTENTOS - 1):
        assert destino(Navegador().login(correo, f"Otra{i}Mala")) == "/login?error"


def test_las_claves_no_se_devuelven_en_ninguna_respuesta_de_login(anonimo):
    clave = "ClaveSecreta123"
    r = anonimo.s.post(Navegador.url("/login"), data={"username": f"x.{aleatorio()}@pruebas.test", "password": clave,
                                                      "_csrf": anonimo.csrf()}, allow_redirects=True, timeout=15)
    assert clave not in r.text


# ------------------------------------------------------------ observaciones conocidas (riesgo residual documentado en docs/SEGURIDAD.md)
@pytest.mark.observacion
@pytest.mark.xfail(reason="OBS-02 (bajo, aceptado): el registro revela si un correo ya existe (enumeracion). "
                          "Mitigar con verificacion por correo o mensaje neutro.", strict=False)
def test_obs02_registro_no_revela_si_un_correo_existe():
    correo, _ = registrar_usuario()
    r = Navegador().post("/registro", {"nombres": "Otra", "apellidos": "Persona", "email": correo, "telefono": "+51 987 654 321",
                                      "password": CLAVE_VALIDA, "confirmPassword": CLAVE_VALIDA, "aceptaTerminos": "true"})
    assert r.status_code == 302, "Para no revelar la existencia del correo la respuesta deberia ser identica a un registro nuevo"
