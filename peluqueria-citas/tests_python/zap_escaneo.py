# -*- coding: utf-8 -*-
"""
OPCIONAL - Escaneo DAST con OWASP ZAP (API REST) SOLO contra localhost.
Requisitos: ZAP en ejecucion (modo daemon) y la app levantada.
  zap.bat -daemon -port 8090 -config api.key=MI_CLAVE        (o zap.sh)
  set ZAP_API_KEY=MI_CLAVE   &   python tests_python/zap_escaneo.py
Limitacion: escanea la parte PUBLICA (login/registro). Para zonas con sesion, configure un contexto autenticado en ZAP.
Salida: reportes_pruebas/zap_informe.html y reportes_pruebas/zap_hallazgos.md
"""
import os
import sys
import time
from urllib.parse import urlparse

import requests

OBJETIVO = os.getenv("BASE_URL", "http://localhost:8080")
ZAP = os.getenv("ZAP_URL", "http://localhost:8090")
CLAVE = os.getenv("ZAP_API_KEY", "")
SALIDA = os.path.join(os.path.dirname(__file__), "..", "reportes_pruebas")


def api(ruta, **params):
    params["apikey"] = CLAVE
    r = requests.get(f"{ZAP}{ruta}", params=params, timeout=60)
    r.raise_for_status()
    return r


def esperar(ruta, **params):
    while int(api(ruta, **params).json()["status"]) < 100:
        time.sleep(3)


def main():
    if urlparse(OBJETIVO).hostname not in ("localhost", "127.0.0.1"):
        sys.exit("Por seguridad y etica, este script solo escanea localhost.")
    os.makedirs(SALIDA, exist_ok=True)
    print("Spider...")
    sid = api("/JSON/spider/action/scan/", url=OBJETIVO).json()["scan"]
    esperar("/JSON/spider/view/status/", scanId=sid)
    print("Escaneo activo...")
    aid = api("/JSON/ascan/action/scan/", url=OBJETIVO).json()["scan"]
    esperar("/JSON/ascan/view/status/", scanId=aid)
    alertas = api("/JSON/core/view/alerts/", baseurl=OBJETIVO).json()["alerts"]
    with open(os.path.join(SALIDA, "zap_informe.html"), "wb") as f:
        f.write(api("/OTHER/core/other/htmlreport/").content)
    orden = {"High": 0, "Medium": 1, "Low": 2, "Informational": 3}
    alertas.sort(key=lambda a: orden.get(a["risk"], 9))
    lineas = ["# Hallazgos OWASP ZAP\n", "| Riesgo | Alerta | URL | Solucion |", "|---|---|---|---|"]
    for a in alertas:
        lineas.append(f"| {a['risk']} | {a['alert']} | {a['url']} | {a.get('solution', '').replace(chr(10), ' ')[:160]} |")
    with open(os.path.join(SALIDA, "zap_hallazgos.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lineas) + "\n")
    print(f"{len(alertas)} alertas. Informes en reportes_pruebas/")


if __name__ == "__main__":
    main()
