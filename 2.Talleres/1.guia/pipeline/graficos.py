#!/usr/bin/env python3
"""Figuras y resultados.json a partir de salida/novaretail.db.
Ejecutar:  uv run --no-project --with matplotlib python pipeline/graficos.py
Las fuentes de Microsoft se leen del manual de marca (no se copian al repositorio)."""
import json
import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.colors import LinearSegmentedColormap

RAIZ = Path(__file__).resolve().parent.parent
FIG = RAIZ / "salida" / "figuras"
FIG.mkdir(parents=True, exist_ok=True)
FUENTES = Path("/Users/juferoga/repos/ud/maestria/mcic/.UniversidadDistrital-manual-marca/fuentes")
familia = "DejaVu Serif"
if (FUENTES / "times.ttf").exists():
    for f in ("times.ttf", "timesbd.ttf"):
        fm.fontManager.addfont(str(FUENTES / f))
    familia = "Times New Roman"
plt.rcParams.update({"font.family": familia, "font.size": 11, "axes.spines.top": False, "axes.spines.right": False,
                     "axes.edgecolor": "#98999A", "axes.labelcolor": "#373435", "text.color": "#373435",
                     "xtick.color": "#373435", "ytick.color": "#373435"})
AZUL, ROJO, SABLE, PLATA, DORADO = "#1291C0", "#ED3237", "#373435", "#98999A", "#B49739"

con = sqlite3.connect(RAIZ / "salida" / "novaretail.db")
q = lambda s: con.execute(s).fetchall()

REG = ["Bogotá", "Medellín", "Cali", "Barranquilla", "Bucaramanga"]
PER = [f"2026-0{m}" for m in range(1, 7)]
MES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun"]

cum = {(p, r): (v, m) for p, r, m, v in q("""
 WITH x AS (SELECT substr(v.fecha,1,7) p, c.region r, SUM(v.importe_neto) n FROM ventas v JOIN clientes c USING(id_cliente) GROUP BY 1,2)
 SELECT m.periodo, m.region, m.meta_ventas, COALESCE(x.n,0) FROM metas m LEFT JOIN x ON x.p=m.periodo AND x.r=m.region""")}

# 1 · mapa de calor de cumplimiento (secuencial de un solo tono)
fig, ax = plt.subplots(figsize=(7.2, 3.4))
cmap = LinearSegmentedColormap.from_list("az", ["#E8F4FA", "#1291C0", "#0B5A78"])
M = [[100 * cum[(p, r)][0] / cum[(p, r)][1] for p in PER] for r in REG]
im = ax.imshow(M, cmap=cmap, vmin=0, vmax=100, aspect="auto")
ax.set_xticks(range(6), MES); ax.set_yticks(range(5), REG)
for i in range(5):
    for j in range(6):
        ax.text(j, i, f"{M[i][j]:.0f}%", ha="center", va="center", fontsize=10,
                color="white" if M[i][j] > 45 else SABLE)
ax.set_xticks([x - .5 for x in range(7)], minor=True); ax.set_yticks([y - .5 for y in range(6)], minor=True)
ax.grid(which="minor", color="white", linewidth=2); ax.tick_params(which="both", length=0)
for s in ax.spines.values(): s.set_visible(False)
ax.set_title("Cumplimiento de meta por mes y región (escala 0–100 %; ninguna celda llega a la meta)", fontsize=10.5, loc="left")
fig.tight_layout(); fig.savefig(FIG / "cumplimiento_heatmap.png", dpi=220); plt.close(fig)

# 2 · ventas netas vs meta por mes (misma unidad, un solo eje)
ven = [sum(cum[(p, r)][0] for r in REG) / 1e6 for p in PER]
met = [sum(cum[(p, r)][1] for r in REG) / 1e6 for p in PER]
fig, ax = plt.subplots(figsize=(7.2, 3.4))
b = ax.bar(MES, ven, width=0.5, color=AZUL, label="Ventas netas")
ax.plot(MES, met, color=SABLE, marker="o", markersize=7, linewidth=2, label="Meta")
for x, v, m in zip(MES, ven, met):
    ax.text(x, v + 4, f"{v:.0f}", ha="center", fontsize=9.5)
    ax.text(x, m + 14, f"{m:.0f}", ha="center", fontsize=9.5, color=SABLE)
ax.set_ylim(0, 390); ax.set_ylabel("Millones COP"); ax.legend(frameon=False, loc="upper center", ncol=2, bbox_to_anchor=(0.5, 1.02))
ax.yaxis.grid(True, color="#E5E5E5", linewidth=.8); ax.set_axisbelow(True)
fig.tight_layout(); fig.savefig(FIG / "ventas_vs_meta.png", dpi=220); plt.close(fig)

# 3 · participación por canal
can = q("SELECT canal, SUM(importe_neto) FROM ventas GROUP BY 1 ORDER BY 2 DESC")
tot = sum(v for _, v in can)
fig, ax = plt.subplots(figsize=(7.2, 2.2))
ax.barh([c for c, _ in can][::-1], [100 * v / tot for _, v in can][::-1], height=0.5, color=AZUL)
for i, (c, v) in enumerate(can[::-1]):
    ax.text(100 * v / tot + 0.6, i, f"{100*v/tot:.1f} %  ({v/1e6:.1f} M)", va="center", fontsize=10)
ax.set_xlim(0, 50); ax.set_xlabel("% de las ventas netas"); ax.xaxis.grid(True, color="#E5E5E5"); ax.set_axisbelow(True)
fig.tight_layout(); fig.savefig(FIG / "canal.png", dpi=220); plt.close(fig)

# 4 · tasa de devolución por categoría (unidades)
dev = q("""SELECT p.categoria, 100.0*SUM(d.cantidad_devuelta)/(SELECT SUM(v2.cantidad) FROM ventas v2 JOIN productos p2 USING(id_producto) WHERE p2.categoria=p.categoria)
           FROM devoluciones d JOIN ventas v USING(id_venta) JOIN productos p USING(id_producto) GROUP BY 1 ORDER BY 2 DESC""")
glob = q("SELECT 100.0*(SELECT SUM(cantidad_devuelta) FROM devoluciones)/(SELECT SUM(cantidad) FROM ventas)")[0][0]
fig, ax = plt.subplots(figsize=(7.2, 2.6))
ax.barh([c for c, _ in dev][::-1], [v for _, v in dev][::-1], height=0.5,
        color=[ROJO if c == dev[0][0] else AZUL for c, _ in dev][::-1])
for i, (c, v) in enumerate(dev[::-1]): ax.text(v + 0.1, i, f"{v:.2f} %", va="center", fontsize=10)
ax.axvline(glob, color=SABLE, linestyle="--", linewidth=1.2)
ax.text(glob + 0.08, 3.45, f"Total {glob:.2f} %", fontsize=9.5, color=SABLE)
ax.set_xlim(0, 7.5); ax.set_xlabel("% de unidades devueltas"); ax.set_ylim(-0.5, 3.8)
fig.tight_layout(); fig.savefig(FIG / "devolucion_categoria.png", dpi=220); plt.close(fig)

# resultados.json (lo consume el portal)
res = {
  "ventas_netas": q("SELECT SUM(importe_neto) FROM ventas")[0][0],
  "meta_total": q("SELECT SUM(meta_ventas) FROM metas")[0][0],
  "unidades": q("SELECT SUM(cantidad) FROM ventas")[0][0],
  "unidades_devueltas": q("SELECT SUM(cantidad_devuelta) FROM devoluciones")[0][0],
  "tasa_devolucion_pct": glob,
  "cumplimiento": [{"periodo": p, "region": r, "meta": cum[(p, r)][1], "ventas": cum[(p, r)][0]} for p in PER for r in REG],
  "canal": [{"canal": c, "ventas": v, "pct": 100 * v / tot} for c, v in can],
  "devolucion_categoria": [{"categoria": c, "tasa": v} for c, v in dev],
  "top5": [dict(zip(("id", "nombre", "categoria", "ingreso"), r)) for r in q(
     "SELECT p.id_producto,p.nombre_producto,p.categoria,SUM(importe_neto) FROM ventas v JOIN productos p USING(id_producto) GROUP BY 1 ORDER BY 4 DESC LIMIT 5")],
  "region_total": [dict(zip(("region", "ventas", "meta"), r)) for r in q(
     "SELECT c.region,SUM(v.importe_neto),(SELECT SUM(meta_ventas) FROM metas m WHERE m.region=c.region) FROM ventas v JOIN clientes c USING(id_cliente) GROUP BY 1")],
}
(RAIZ / "salida" / "resultados.json").write_text(json.dumps(res, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", sorted(p.name for p in FIG.iterdir()), familia)

# Tabla LaTeX de Q1 (región x mes, millones de pesos) para el informe
(RAIZ / "informe").mkdir(exist_ok=True)
m = {(p, r): v for p, r, _, v in [(p, r, cum[(p, r)][1], cum[(p, r)][0]) for p in PER for r in REG]}
fmt = lambda x: f"{x/1e6:.1f}".replace(".", ",")
filas = [f"{r} & " + " & ".join(fmt(m[(p, r)]) for p in PER) + f" & {fmt(sum(m[(p, r)] for p in PER))} \\\\" for r in REG]
tot = " & ".join(fmt(sum(m[(p, r)] for r in REG)) for p in PER)
(RAIZ / "informe" / "q1_tabla.tex").write_text(
    "\\begin{tabularx}{\\linewidth}{L r r r r r r r}\n\\toprule\nRegión & " + " & ".join(MES) + " & Total \\\\\n\\midrule\n"
    + "\n".join(filas) + f"\n\\midrule\n\\textbf{{Total}} & {tot} & \\textbf{{{fmt(sum(m.values()))}}} \\\\\n\\bottomrule\n\\end{{tabularx}}\n",
    encoding="utf-8")
