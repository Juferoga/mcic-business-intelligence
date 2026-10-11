#!/usr/bin/env python3
"""Genera portal/index.html (un solo archivo, sin dependencias externas) a partir de la base y la bitácora.
Ejecutar después de limpieza.py y graficos.py:  python3 pipeline/portal.py"""
import csv
import json
import re
import sqlite3
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PORTAL = RAIZ / "portal"
PORTAL.mkdir(exist_ok=True)

con = sqlite3.connect(RAIZ / "salida" / "novaretail.db")
res = json.loads((RAIZ / "salida" / "resultados.json").read_text(encoding="utf-8"))
bit = list(csv.DictReader(open(RAIZ / "salida" / "bitacora_calidad.csv", encoding="utf-8")))

# --- Consultas: separar el archivo por "-- Qn" y ejecutar cada una -------------
sql = (RAIZ / "sql" / "20_consultas.sql").read_text(encoding="utf-8")
bloques = re.split(r"\n(?=-- Q\d ·)", sql)[1:]
consultas = []
for b in bloques:
    titulo = b.splitlines()[0][3:].strip("- ").strip()
    titulo = re.sub(r"\s*-{3,}\s*$", "", titulo)
    cur = con.execute(re.sub(r"^--.*\n", "", b, flags=re.M))
    cols = [d[0] for d in cur.description]
    consultas.append({"titulo": titulo, "sql": b.strip(), "cols": cols, "filas": cur.fetchall()})

calidad = (RAIZ / "sql" / "30_calidad_y_conceptos.sql").read_text(encoding="utf-8")

datos = {
    "res": res,
    "bitacora": bit,
    "consultas": consultas,
    "calidad_sql": calidad,
    "auditoria": [dict(zip(("id", "motivo"), r)) for r in con.execute(
        "SELECT id_venta, motivo_rechazo FROM auditoria_rechazados")],
}
blob = json.dumps(datos, ensure_ascii=False).replace("</", "<\\/")

plantilla = (Path(__file__).parent / "portal_plantilla.html").read_text(encoding="utf-8")
(PORTAL / "index.html").write_text(plantilla.replace("/*__DATOS__*/null", blob), encoding="utf-8")
print("portal/index.html", round(len(blob) / 1024), "KB de datos embebidos")
