# -*- coding: utf-8 -*-
"""
Convierte reportes_pruebas/junit.xml en un resumen Markdown (evidencia para el anexo "Informes de Pruebas").
Uso:  python tests_python/resumen_resultados.py
"""
import os
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from datetime import datetime

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
XML = os.path.join(RAIZ, "reportes_pruebas", "junit.xml")
SALIDA = os.path.join(RAIZ, "reportes_pruebas", "resumen_pruebas.md")

CONTROL = {
    "test_01_funcional_publico": ("Funcional", "Zona publica, registro y login"),
    "test_02_funcional_cliente": ("Funcional", "Catalogo, reserva, cruces, cancelacion, preferencias"),
    "test_03_funcional_admin_estilista": ("Funcional", "Panel, servicios, clientes, reportes, agenda"),
    "test_04_seguridad_acceso": ("Seguridad A01 / CSRF", "Control de acceso por rol, IDOR, CSRF"),
    "test_05_seguridad_entradas": ("Seguridad A05", "SQL injection, XSS, validacion, open redirect"),
    "test_06_seguridad_configuracion": ("Seguridad A02 / A10", "Cabeceras, cookies, errores, archivos sensibles"),
    "test_07_seguridad_autenticacion": ("Seguridad A07", "Mensajes genericos, bloqueo por intentos"),
    "test_08_e2e_navegador": ("E2E (Playwright)", "Interfaz, filtros, asistente de reserva, CSP"),
}


def main():
    if not os.path.exists(XML):
        sys.exit(f"No existe {XML}. Ejecute antes: pytest --junitxml=reportes_pruebas/junit.xml")
    suites = ET.parse(XML).getroot()
    casos = suites.iter("testcase")
    por_archivo = defaultdict(lambda: {"ok": 0, "fallo": 0, "omitida": 0, "obs": 0})
    fallos, obs = [], []
    for c in casos:
        archivo = c.get("classname", "").split(".")[-1] if c.get("classname") else "?"
        d = por_archivo[archivo]
        fallo = c.find("failure") if c.find("failure") is not None else c.find("error")
        omitida = c.find("skipped")
        if fallo is not None:
            d["fallo"] += 1
            fallos.append((archivo, c.get("name"), (fallo.get("message") or "")[:200].replace("\n", " ")))
        elif omitida is not None:
            if "xfail" in (omitida.get("type") or "").lower() or "xfail" in (omitida.get("message") or "").lower():
                d["obs"] += 1
                obs.append((archivo, c.get("name"), (omitida.get("message") or "")[:200]))
            else:
                d["omitida"] += 1
        else:
            d["ok"] += 1
    tot = {k: sum(v[k] for v in por_archivo.values()) for k in ("ok", "fallo", "omitida", "obs")}
    total = sum(tot.values())
    lineas = [f"# Resumen de ejecucion de pruebas Python\n", f"Generado: {datetime.now():%Y-%m-%d %H:%M}\n",
              f"**Total:** {total} | **OK:** {tot['ok']} | **Fallos:** {tot['fallo']} | "
              f"**Omitidas:** {tot['omitida']} | **Observaciones (xfail):** {tot['obs']}\n",
              "| Archivo | Tipo | Alcance | OK | Fallos | Omitidas | Obs. |", "|---|---|---|---|---|---|---|"]
    for arch in sorted(por_archivo):
        t, a = CONTROL.get(arch, ("-", "-"))
        d = por_archivo[arch]
        lineas.append(f"| `{arch}` | {t} | {a} | {d['ok']} | {d['fallo']} | {d['omitida']} | {d['obs']} |")
    if fallos:
        lineas += ["\n## Fallos (posibles vulnerabilidades o defectos a registrar)\n", "| Archivo | Prueba | Detalle |", "|---|---|---|"]
        lineas += [f"| `{a}` | `{n}` | {m} |" for a, n, m in fallos]
    if obs:
        lineas += ["\n## Observaciones conocidas (xfail)\n", "| Archivo | Prueba | Motivo |", "|---|---|---|"]
        lineas += [f"| `{a}` | `{n}` | {m} |" for a, n, m in obs]
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write("\n".join(lineas) + "\n")
    print(f"Resumen escrito en {SALIDA}")
    print("\n".join(lineas[:4]))


if __name__ == "__main__":
    main()
