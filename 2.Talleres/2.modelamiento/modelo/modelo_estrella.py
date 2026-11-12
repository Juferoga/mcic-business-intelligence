"""NovaRetail 360 · Laboratorio 2 · Parte 4 sin Power BI.

Equipo: Juan Felipe Rodríguez Galindo (20261595004) · Carlos Stiven Mora Hoyos (20261595003)

Power BI Desktop solo corre en Windows, así que la parte 4 se reproduce con pandas:
1. importa los ocho CSV de la estrella (descuento como decimal);
2. declara las ocho relaciones y verifica en los datos su cardinalidad (1 a muchos)
   e integridad; la dirección del filtro es única, de la dimensión al hecho;
3. calcula las tres medidas (Ventas Netas, Meta, % Cumplimiento = DIVIDE) en una
   matriz región x mes con totales, propagando el filtro por las relaciones;
4. compara la matriz con los controles C2 y C3 calculados en SQLite;
5. prueba qué pasa al relacionar FactMetas directamente con FactVentas;
6. dibuja la vista de modelo y la matriz (capturas/) y escribe tablas para el informe.

Uso (desde la carpeta del laboratorio):
    uv run --no-project --with pandas --with matplotlib python modelo/modelo_estrella.py
"""
import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
import pandas as pd

# ---------------------------------------------------------------- parámetros
RAIZ = Path(__file__).resolve().parent.parent
BASE = RAIZ / "base" / "novaretail_lab2_2026-11-11.db"   # copia de trabajo del día
CSV = RAIZ / "csv_estrella"
CAPTURAS = RAIZ / "capturas"
TABLAS_INFORME = RAIZ / "informe" / "generado"
TOLERANCIA = 0.5                     # pesos; los controles SQL se redondean con ROUND
AZUL, AZUL_OSC, SABLE, PLATA = "#1291C0", "#085C83", "#373435", "#98999A"
FUENTE = "Times New Roman"

TABLAS = ["DimPeriodo", "DimFecha", "DimRegion", "DimCliente",
          "DimProducto", "DimCanal", "FactVentas", "FactMetas"]

# (tabla lado 1, columna, tabla lado muchos, columna)  -- tabla de la parte 4
RELACIONES = [
    ("DimPeriodo", "id_periodo", "DimFecha", "id_periodo"),
    ("DimFecha", "id_fecha", "FactVentas", "id_fecha"),
    ("DimPeriodo", "id_periodo", "FactMetas", "id_periodo"),
    ("DimRegion", "id_region", "FactVentas", "id_region"),
    ("DimRegion", "id_region", "FactMetas", "id_region"),
    ("DimCliente", "sk_cliente", "FactVentas", "sk_cliente"),
    ("DimProducto", "sk_producto", "FactVentas", "sk_producto"),
    ("DimCanal", "id_canal", "FactVentas", "id_canal"),
]


# ------------------------------------------------------------ 1. importar CSV
def importar():
    tablas = {t: pd.read_csv(CSV / f"{t}.csv", dtype={"id_periodo": str}) for t in TABLAS}
    desc = tablas["FactVentas"]["descuento"]
    assert desc.dtype.kind == "f" and desc.max() <= 1, "descuento debe ser decimal (0,05 y no 5)"
    return tablas


# -------------------------------------------------- 2. relaciones y cardinalidad
def cardinalidad(t, a, col_a, b, col_b):
    lado_a = "1" if t[a][col_a].is_unique else "*"
    lado_b = "1" if t[b][col_b].is_unique else "*"
    return f"{lado_a}:{lado_b}"


def validar_relaciones(t):
    filas = []
    for uno, c1, muchos, c2 in RELACIONES:
        card = cardinalidad(t, uno, c1, muchos, c2)
        huerfanas = int((~t[muchos][c2].isin(t[uno][c1])).sum())
        assert card == "1:*", f"{uno}->{muchos} no es 1 a muchos ({card})"
        assert huerfanas == 0, f"{muchos}[{c2}] tiene {huerfanas} claves sin dimensión"
        filas.append({"desde": f"{uno}[{c1}]", "hacia": f"{muchos}[{c2}]",
                      "cardinalidad": "Uno a varios (1:*)", "direccion": "Única (dimensión a hecho)",
                      "filas_muchos": len(t[muchos])})
    return pd.DataFrame(filas)


# ----------------------------------------------------- 3. medidas y matriz
def matriz(t):
    """Matriz DimRegion[region] x DimPeriodo[nombre_mes] con las tres medidas.

    El filtro baja por las relaciones: DimPeriodo -> DimFecha -> FactVentas y
    DimPeriodo -> FactMetas; DimRegion -> FactVentas y DimRegion -> FactMetas.
    Cada hecho se agrega a su celda por separado y luego se dividen (DIVIDE).
    """
    ventas = (t["FactVentas"]
              .merge(t["DimFecha"][["id_fecha", "id_periodo"]], on="id_fecha")
              .groupby(["id_periodo", "id_region"])["ventas_netas"].sum())
    metas = t["FactMetas"].groupby(["id_periodo", "id_region"])["meta_ventas"].sum()
    celdas = pd.concat([ventas.rename("Ventas Netas"), metas.rename("Meta")], axis=1).fillna(0)
    celdas = (celdas.reset_index()
              .merge(t["DimRegion"], on="id_region")
              .merge(t["DimPeriodo"][["id_periodo", "mes", "nombre_mes"]], on="id_periodo"))
    celdas["% Cumplimiento"] = celdas["Ventas Netas"] / celdas["Meta"]

    def totales(por):
        g = celdas.groupby(por)[["Ventas Netas", "Meta"]].sum()
        g["% Cumplimiento"] = g["Ventas Netas"] / g["Meta"]   # cociente de totales
        return g

    total = celdas[["Ventas Netas", "Meta"]].sum()
    total["% Cumplimiento"] = total["Ventas Netas"] / total["Meta"]
    return celdas, totales("region"), totales(["mes", "nombre_mes"]), total


# ------------------------------------------- 4. conciliación con SQLite (C2, C3)
C2 = "SELECT SUM(ventas_netas), (SELECT SUM(meta_ventas) FROM FactMetas) FROM FactVentas"
C3 = """
WITH real AS (
    SELECT f.id_periodo, v.id_region, SUM(v.ventas_netas) AS ventas_netas
    FROM FactVentas v JOIN DimFecha f ON f.id_fecha = v.id_fecha
    GROUP BY f.id_periodo, v.id_region)
SELECT m.id_periodo, r.region, m.meta_ventas, COALESCE(real.ventas_netas, 0)
FROM FactMetas m
JOIN DimRegion r ON r.id_region = m.id_region
LEFT JOIN real ON real.id_periodo = m.id_periodo AND real.id_region = m.id_region"""


def conciliar(celdas, total):
    with sqlite3.connect(BASE) as con:
        netas_sql, meta_sql = con.execute(C2).fetchone()
        c3 = pd.DataFrame(con.execute(C3).fetchall(),
                          columns=["id_periodo", "region", "meta_sql", "netas_sql"])
    cruce = celdas.merge(c3, on=["id_periodo", "region"], how="outer", indicator=True)
    assert (cruce["_merge"] == "both").all() and len(cruce) == 30
    dif_celdas = max((cruce["Ventas Netas"] - cruce["netas_sql"]).abs().max(),
                     (cruce["Meta"] - cruce["meta_sql"]).abs().max())
    dif_total = max(abs(total["Ventas Netas"] - netas_sql), abs(total["Meta"] - meta_sql))
    assert dif_celdas < TOLERANCIA and dif_total < TOLERANCIA
    return {"celdas": len(cruce), "dif_celdas": dif_celdas, "dif_total": dif_total,
            "netas_sql": netas_sql, "meta_sql": meta_sql}


# ------------------------------------ 5. relación directa FactMetas - FactVentas
def relacion_directa(t):
    fv, fm = t["FactVentas"], t["FactMetas"]
    card = cardinalidad(t, "FactMetas", "id_region", "FactVentas", "id_region")
    unida = fv.merge(fm, on="id_region")                  # única columna común
    por_region = (unida.groupby("id_region")["meta_ventas"].sum()
                  .rename("meta_relacion_directa").to_frame()
                  .join(fm.groupby("id_region")["meta_ventas"].sum().rename("meta_real"))
                  .join(t["DimRegion"].set_index("id_region")))
    return {"cardinalidad": card, "filas": len(unida), "meta": unida["meta_ventas"].sum(),
            "netas": unida["ventas_netas"].sum(), "meta_real": fm["meta_ventas"].sum(),
            "netas_real": fv["ventas_netas"].sum(), "por_region": por_region}


# ------------------------------------------------------- 6. figuras y tablas
plt.rcParams.update({"font.family": FUENTE, "font.size": 10})

COLUMNAS = {
    "DimPeriodo": ["id_periodo (PK)", "anio, mes", "nombre_mes", "trimestre"],
    "DimFecha": ["id_fecha (PK)", "fecha, anio, mes, dia", "dia_semana, es_fin_semana", "id_periodo (FK)"],
    "DimRegion": ["id_region (PK)", "region"],
    "DimCliente": ["sk_cliente (PK)", "id_cliente, nombre", "segmento, region", "vigente_desde/hasta, es_actual"],
    "DimProducto": ["sk_producto (PK)", "id_producto", "nombre_producto, categoria", "precio_lista"],
    "DimCanal": ["id_canal (PK)", "canal"],
    "FactVentas": ["id_venta", "id_fecha, sk_cliente (FK)", "sk_producto, id_canal (FK)", "id_region (FK)",
                   "cantidad, precio_unitario, descuento", "importe_bruto, importe_neto",
                   "unidades_devueltas, valor_devuelto", "ventas_netas"],
    "FactMetas": ["id_periodo (FK)", "id_region (FK)", "meta_ventas"],
}
POSICION = {"DimPeriodo": (6.2, 8.4), "DimFecha": (2.0, 8.4), "DimRegion": (6.2, 4.2),
            "DimCliente": (-2.4, 5.8), "DimProducto": (-2.4, 2.2), "DimCanal": (2.0, 0.4),
            "FactVentas": (2.0, 4.2), "FactMetas": (10.2, 4.2)}
ANCHO, ALTO_FILA = 3.3, 0.36


def caja(nombre):
    x, y = POSICION[nombre]
    alto = ALTO_FILA * (len(COLUMNAS[nombre]) + 1.3)
    return x, y, ANCHO / 2, alto / 2


def borde(desde, hacia):
    """Punto donde la recta entre centros sale de la caja 'desde'."""
    x, y, w, h = caja(desde)
    x2, y2, _, _ = caja(hacia)
    dx, dy = x2 - x, y2 - y
    s = min(w / abs(dx) if dx else 1e9, h / abs(dy) if dy else 1e9)
    return x + dx * s, y + dy * s


def vista_modelo(ruta):
    fig, ax = plt.subplots(figsize=(11, 7.6))
    for uno, c1, muchos, c2 in RELACIONES:
        (xa, ya), (xb, yb) = borde(uno, muchos), borde(muchos, uno)
        ax.annotate("", xy=((xa + xb) / 2, (ya + yb) / 2), xytext=(xa, ya),
                    arrowprops=dict(arrowstyle="-|>", color=PLATA, lw=1.4), zorder=1)
        ax.plot([xa, xb], [ya, yb], color=PLATA, lw=1.4, zorder=1)
        for (px, py), etiqueta in (((xa, ya), "1"), ((xb, yb), "*")):
            ax.text(px + (xb - xa if etiqueta == "1" else xa - xb) * 0.07,
                    py + (yb - ya if etiqueta == "1" else ya - yb) * 0.07 + 0.12,
                    etiqueta, ha="center", va="center", fontsize=11, color=SABLE,
                    fontweight="bold", zorder=3,
                    bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none"))
    for nombre, cols in COLUMNAS.items():
        x, y, w, h = caja(nombre)
        hecho = nombre.startswith("Fact")
        color = AZUL_OSC if hecho else AZUL
        ax.add_patch(FancyBboxPatch((x - w, y - h), 2 * w, 2 * h, boxstyle="round,pad=0,rounding_size=0.12",
                                    fc="white", ec=color, lw=1.6, zorder=2))
        ax.add_patch(FancyBboxPatch((x - w, y + h - ALTO_FILA * 1.15), 2 * w, ALTO_FILA * 1.15,
                                    boxstyle="round,pad=0,rounding_size=0.12", fc=color, ec=color, zorder=2))
        ax.text(x, y + h - ALTO_FILA * 0.58, nombre, ha="center", va="center", color="white",
                fontweight="bold", fontsize=11, zorder=3)
        for i, c in enumerate(cols):
            ax.text(x - w + 0.15, y + h - ALTO_FILA * (1.75 + i), c, ha="left", va="center",
                    fontsize=8.5, color=SABLE, zorder=3)
    ax.set_xlim(-4.4, 12.2)
    ax.set_ylim(-0.6, 9.9)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.set_title("Vista de modelo: 8 relaciones de uno a varios, filtro de la dimensión al hecho",
                 fontsize=12, color=SABLE, loc="left")
    fig.tight_layout()
    fig.savefig(ruta, dpi=200)
    plt.close(fig)


def figura_matriz(celdas, por_region, por_mes, total, ruta):
    regiones = sorted(celdas["region"].unique())
    meses = [n for _, n in sorted(set(zip(celdas["mes"], celdas["nombre_mes"])))]
    tabla = (celdas.pivot(index="region", columns="nombre_mes", values="% Cumplimiento")
             .loc[regiones, meses])
    tabla["Total"] = por_region.loc[regiones, "% Cumplimiento"]
    fila_total = list(por_mes["% Cumplimiento"].values) + [total["% Cumplimiento"]]
    tabla.loc["Total"] = fila_total
    # Escala secuencial de un solo tono (azur UD) lo bastante clara para tinta oscura en todas las celdas
    fig, ax = plt.subplots(figsize=(8.6, 3.6))
    cmap = matplotlib.colors.LinearSegmentedColormap.from_list("ud", ["#F4FAFD", "#8DCBE4"])
    datos = tabla.values * 100
    ax.imshow(datos, cmap=cmap, vmin=20, vmax=60, aspect="auto")
    for i in range(datos.shape[0]):
        for j in range(datos.shape[1]):
            v = datos[i, j]
            ax.text(j, i, f"{v:.1f} %".replace(".", ","), ha="center", va="center", fontsize=9.5,
                    color=SABLE,
                    fontweight="bold" if i == datos.shape[0] - 1 or j == datos.shape[1] - 1 else "normal")
    ax.set_xticks(range(len(tabla.columns)), tabla.columns)
    ax.set_yticks(range(len(tabla.index)), tabla.index)
    ax.tick_params(length=0)
    for s in ax.spines.values():
        s.set_visible(False)
    ax.axhline(len(regiones) - 0.5, color="white", lw=3)
    ax.axvline(len(meses) - 0.5, color="white", lw=3)
    ax.xaxis.set_ticks_position("top")
    ax.set_title("% Cumplimiento = DIVIDE([Ventas Netas], [Meta]) por región y mes",
                 fontsize=11, color=SABLE, loc="left", pad=24)
    fig.tight_layout()
    fig.savefig(ruta, dpi=200)
    plt.close(fig)
    return tabla


def pesos(v):
    return f"{v:,.0f}".replace(",", ".")


def pct(v):
    return f"{100 * v:.1f}".replace(".", "{,}") + "\\,\\%"


def escribir_informe(rel, celdas, por_region, por_mes, total, conc, directa):
    TABLAS_INFORME.mkdir(parents=True, exist_ok=True)
    tex = lambda s: s.replace("_", "\\_")
    filas = [f"\\texttt{{{tex(r.desde)}}} & \\texttt{{{tex(r.hacia)}}} & 1 a * & Única \\\\" for r in rel.itertuples()]
    (TABLAS_INFORME / "relaciones.tex").write_text("\n".join(filas) + "\n")

    regiones = sorted(celdas["region"].unique())
    meses = sorted(set(zip(celdas["mes"], celdas["nombre_mes"])))
    lin = []
    for reg in regiones:
        c = celdas[celdas.region == reg].set_index("mes")
        lin.append(reg + " & " + " & ".join(pct(c.loc[m, "% Cumplimiento"]) for m, _ in meses)
                   + f" & \\textbf{{{pct(por_region.loc[reg, '% Cumplimiento'])}}} \\\\")
    lin.append("\\midrule\n\\textbf{Total} & " + " & ".join(
        f"\\textbf{{{pct(por_mes.loc[(m, n), '% Cumplimiento'])}}}" for m, n in meses)
        + f" & \\textbf{{{pct(total['% Cumplimiento'])}}} \\\\")
    (TABLAS_INFORME / "matriz.tex").write_text("\n".join(lin) + "\n")

    macros = {
        "VentasNetasTotal": pesos(total["Ventas Netas"]), "MetaTotal": pesos(total["Meta"]),
        "CumplTotal": pct(total["% Cumplimiento"]), "CeldasConciliadas": str(conc["celdas"]),
        "DifMaxCelda": f"{conc['dif_celdas']:.2f}".replace(".", "{,}"),
        "DirectaCard": directa["cardinalidad"].replace(":", " a "),
        "DirectaFilas": pesos(directa["filas"]), "DirectaMeta": pesos(directa["meta"]),
        "DirectaNetas": pesos(directa["netas"]),
        "DirectaVecesMeta": f"{directa['meta'] / directa['meta_real']:.1f}".replace(".", "{,}"),
        "DirectaVecesNetas": f"{directa['netas'] / directa['netas_real']:.1f}".replace(".", "{,}"),
        "CumplRegMin": pct(por_region["% Cumplimiento"].min()),
        "CumplRegMax": pct(por_region["% Cumplimiento"].max()),
        "CumplMesMin": pct(por_mes["% Cumplimiento"].min()),
        "CumplMesMax": pct(por_mes["% Cumplimiento"].max()),
        "CumplCeldaMin": pct(celdas["% Cumplimiento"].min()),
        "CumplCeldaMax": pct(celdas["% Cumplimiento"].max()),
    }
    (TABLAS_INFORME / "cifras.tex").write_text(
        "".join(f"\\newcommand{{\\{k}}}{{{v}}}\n" for k, v in macros.items()))


def main():
    t = importar()
    rel = validar_relaciones(t)
    print(rel.to_string(index=False))
    celdas, por_region, por_mes, total = matriz(t)
    conc = conciliar(celdas, total)
    print(f"\nConciliación: {conc['celdas']} celdas iguales a C3 (dif. máx. {conc['dif_celdas']:.4f}); "
          f"total igual a C2 (dif. {conc['dif_total']:.4f})")
    print(f"Total: Ventas Netas {pesos(total['Ventas Netas'])} | Meta {pesos(total['Meta'])} | "
          f"% Cumplimiento {100 * total['% Cumplimiento']:.2f} %")
    print("\nPor región:\n", (por_region["% Cumplimiento"] * 100).round(1).to_string())
    print("\nPor mes:\n", (por_mes["% Cumplimiento"] * 100).round(1).to_string())
    d = relacion_directa(t)
    print(f"\nRelación directa FactMetas[id_region] - FactVentas[id_region]: {d['cardinalidad']} "
          f"(muchos a muchos), {pesos(d['filas'])} filas; Meta {pesos(d['meta'])} "
          f"({d['meta'] / d['meta_real']:.1f} veces la real); Ventas Netas {pesos(d['netas'])} "
          f"({d['netas'] / d['netas_real']:.1f} veces la real)")
    print(d["por_region"].to_string())
    CAPTURAS.mkdir(exist_ok=True)
    vista_modelo(CAPTURAS / "vista_modelo.png")
    figura_matriz(celdas, por_region, por_mes, total, CAPTURAS / "matriz_cumplimiento.png")
    escribir_informe(rel, celdas, por_region, por_mes, total, conc, d)
    print("\nCapturas en capturas/ y tablas en informe/generado/")


if __name__ == "__main__":
    main()
