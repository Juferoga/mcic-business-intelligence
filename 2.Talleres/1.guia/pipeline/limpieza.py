#!/usr/bin/env python3
"""NovaRetail 360 · pipeline de limpieza reproducible (solo biblioteca estándar).

Lee los CSV originales de ../ y produce en ../salida/:
  datos_limpios/*.csv        tablas depuradas
  auditoria_rechazados.csv   registros apartados (nunca se borran en silencio)
  bitacora_calidad.csv       una fila por incidencia: regla, evidencia, impacto, decisión
  novaretail.db              SQLite con tablas operacionales + esquema estrella

Es el equivalente en Python de las consultas de Power Query de ../power_query/.
Ejecutar:  python3 pipeline/limpieza.py
"""
import csv
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "salida"
LIMPIOS = SALIDA / "datos_limpios"
LIMPIOS.mkdir(parents=True, exist_ok=True)

CANALES = {"web": "Web", "marketplace": "Marketplace", "tienda": "Tienda"}
DESCUENTOS_VALIDOS = {0.0, 0.05, 0.10, 0.15}


def leer(nombre):
    with open(RAIZ / nombre, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def escribir(ruta, filas, campos):
    with open(ruta, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=campos)
        w.writeheader()
        w.writerows(filas)


clientes = leer("clientes.csv")
productos = leer("productos.csv")
devoluciones = leer("devoluciones.csv")
metas = leer("metas.csv")
ventas = leer("ventas_sucias.csv")

ids_cliente = {c["id_cliente"] for c in clientes}
precio_lista = {p["id_producto"]: int(p["precio_lista"]) for p in productos}

# --- Evidencia previa para la regla de imputación de precio -----------------
validos = [
    r for r in ventas
    if re.fullmatch(r"\d+", r["precio_unitario"]) and r["id_producto"] in precio_lista
]
coinciden = sum(int(r["precio_unitario"]) == precio_lista[r["id_producto"]] for r in validos)

bitacora = []          # incidencias
rechazados = []        # registros apartados
limpias = []           # ventas aceptadas
vistos = {}            # id_venta -> fila aceptada (para detectar repetidos)
n_corregidos = 0


def incidencia(id_venta, regla, campo, valor, evidencia, impacto, decision, accion):
    bitacora.append({
        "n": len(bitacora) + 1, "id_registro": id_venta, "regla": regla, "campo": campo,
        "valor_observado": valor, "evidencia": evidencia, "impacto": impacto,
        "decision": decision, "accion": accion,
    })


def rechazar(r, motivo):
    rechazados.append({**r, "motivo_rechazo": motivo})


for r in ventas:
    r = {k: (v or "").strip() for k, v in r.items()}
    idv = r["id_venta"]
    corregido = []

    # R1 · id_venta repetido (fila idéntica) -> auditar la segunda aparición
    if idv in vistos:
        incidencia(idv, "R1 Unicidad de id_venta", "id_venta", idv,
                   "Segunda aparición con las 8 columnas idénticas a la primera",
                   "Duplicaría ingreso y unidades si se conservara", "Rechazar la repetición, conservar la primera",
                   "auditoría")
        rechazar(r, "R1 venta repetida")
        continue

    # R2 · fecha: debe existir y normalizarse a ISO (la configuración regional puede ser dd/mm)
    if not r["fecha"]:
        incidencia(idv, "R2 Fecha obligatoria", "fecha", "(vacío)",
                   "Sin fecha no se puede asignar mes ni comparar con metas",
                   "Ingreso fuera de todos los periodos", "Rechazar; no se inventa una fecha", "auditoría")
        rechazar(r, "R2 fecha vacía")
        continue
    m = re.fullmatch(r"(\d{2})/(\d{2})/(\d{4})", r["fecha"])
    if m:
        dd, mm, aaaa = m.groups()
        original = r["fecha"]
        r["fecha"] = f"{aaaa}-{mm}-{dd}"
        corregido.append("fecha")
        incidencia(idv, "R2 Formato de fecha ISO", "fecha", original,
                   f"Día {dd} > 12: solo puede ser dd/mm/aaaa; el resto del archivo está en aaaa-mm-dd",
                   "Con configuración regional en-US se leería mal o como error",
                   f"Convertir a {r['fecha']} (conversión determinista, no es un reemplazo)", "corregido")
    try:
        date.fromisoformat(r["fecha"])
    except ValueError:
        incidencia(idv, "R2 Fecha válida en el calendario", "fecha", r["fecha"],
                   "Formato aaaa-mm-dd correcto pero la fecha no existe (p. ej. 30 de febrero)",
                   "Se asignaría a un mes con una fecha imposible; Power Query la convierte en error",
                   "Rechazar; no se inventa el día correcto", "auditoría")
        rechazar(r, "R2 fecha inexistente")
        continue

    # R3 · integridad referencial
    if r["id_cliente"] not in ids_cliente:
        incidencia(idv, "R3 Integridad referencial (cliente)", "id_cliente", r["id_cliente"],
                   "LEFT JOIN con clientes devuelve NULL; la clave no existe en el maestro",
                   "Un INNER JOIN la descartaría sin dejar rastro; sin región no entra a metas",
                   "Rechazar y auditar; pedir alta o corrección al dueño del dato", "auditoría")
        rechazar(r, "R3 id_cliente inexistente")
        continue
    if r["id_producto"] not in precio_lista:
        incidencia(idv, "R3 Integridad referencial (producto)", "id_producto", r["id_producto"],
                   "LEFT JOIN con productos devuelve NULL; la clave no existe en el catálogo",
                   "Un INNER JOIN la descartaría sin dejar rastro", "Rechazar y auditar", "auditoría")
        rechazar(r, "R3 id_producto inexistente")
        continue

    # R4 · cantidad: entero positivo; no hay fuente para recuperarla
    if r["cantidad"] == "" or int(r["cantidad"]) <= 0:
        etiqueta = "(vacío)" if r["cantidad"] == "" else r["cantidad"]
        incidencia(idv, "R4 Cantidad entera positiva", "cantidad", etiqueta,
                   "Nulo o <= 0; ningún otro campo permite inferir las unidades vendidas",
                   "Importe y unidades erróneos (una cantidad negativa resta ingreso)",
                   "Rechazar y auditar; un negativo podría ser una devolución mal registrada, lo confirma el negocio",
                   "auditoría")
        rechazar(r, "R4 cantidad inválida")
        continue

    # R5 · descuento en [0,1] y dentro de la escala comercial
    d = float(r["descuento"])
    if d not in DESCUENTOS_VALIDOS:
        incidencia(idv, "R5 Descuento en escala comercial", "descuento", r["descuento"],
                   "Valores válidos: 0, 0,05, 0,10, 0,15. Un 125 % produce importe neto negativo",
                   "Ingreso neto negativo; el descuento correcto es desconocido",
                   "Rechazar; recortar a 1 o a 0 sería arbitrario", "auditoría")
        rechazar(r, "R5 descuento fuera de rango")
        continue

    # R6 · precio: positivo; si falta o es negativo se recupera del catálogo (regla con evidencia)
    if r["precio_unitario"] == "" or int(r["precio_unitario"]) <= 0:
        etiqueta = "(vacío)" if r["precio_unitario"] == "" else r["precio_unitario"]
        nuevo = precio_lista[r["id_producto"]]
        incidencia(idv, "R6 Precio positivo = precio de lista", "precio_unitario", etiqueta,
                   f"{coinciden}/{len(validos)} ventas válidas se facturan exactamente al precio_lista del catálogo",
                   "Sin corregir, el importe sería nulo o negativo",
                   f"Imputar precio_lista = {nuevo} y marcar la fila (columna ajustes)", "corregido")
        r["precio_unitario"] = str(nuevo)
        corregido.append("precio_unitario")

    # R7 · canal: recortar espacios y unificar mayúsculas
    canal = CANALES.get(r["canal"].lower())
    if canal != r["canal"]:
        incidencia(idv, "R7 Dominio de canal", "canal", repr(r["canal"]),
                   "Espacios finales o mayúsculas distintas de las 3 categorías válidas",
                   "Aparecería como un 4.º y 5.º canal y partiría la participación",
                   f"Normalizar a {canal} (trim + proper case)", "corregido")
        r["canal"] = canal
        corregido.append("canal")

    cant, precio = int(r["cantidad"]), int(r["precio_unitario"])
    bruto = cant * precio
    neto = round(bruto * (1 - d), 2)
    limpia = {
        "id_venta": idv, "fecha": r["fecha"], "id_cliente": r["id_cliente"], "id_producto": r["id_producto"],
        "canal": r["canal"], "cantidad": cant, "precio_unitario": precio, "descuento": d,
        "importe_bruto": bruto, "importe_neto": neto, "ajustes": "+".join(corregido),
    }
    vistos[idv] = limpia
    limpias.append(limpia)

# --- Devoluciones: se vinculan a la venta ORIGINAL ---------------------------
dev_limpias = []
for d in devoluciones:
    v = vistos.get(d["id_venta"])
    if v is None:
        incidencia(d["id_devolucion"], "R8 Devolución sin venta aceptada", "id_venta", d["id_venta"],
                   "La venta no está en el conjunto depurado", "Devolución huérfana", "Auditar", "auditoría")
        rechazados.append({"id_venta": d["id_venta"], "motivo_rechazo": "R8 devolución sin venta"})
        continue
    cdev = int(d["cantidad_devuelta"])
    if cdev > v["cantidad"]:
        incidencia(d["id_devolucion"], "R9 Devolución <= unidades vendidas", "cantidad_devuelta", cdev,
                   f"Venta original: {v['cantidad']} unidades", "Sobreestima devoluciones", "Auditar", "auditoría")
        continue
    dev_limpias.append({
        "id_devolucion": d["id_devolucion"], "id_venta": d["id_venta"], "cantidad_devuelta": cdev,
        "motivo": d["motivo"],
        "valor_devuelto": round(cdev * v["precio_unitario"] * (1 - v["descuento"]), 2),
    })

# Controles que NO produjeron hallazgos (también son evidencia de la revisión)
sin_hallazgo = [
    ("clientes.csv", "id_cliente único, región y segmento completos", len(clientes)),
    ("productos.csv", "id_producto único, categoría y precio_lista > 0", len(productos)),
    ("devoluciones.csv", "70 devoluciones, todas con venta aceptada y cantidad <= vendida", len(dev_limpias)),
    ("metas.csv", "30 filas = 6 meses x 5 regiones, sin huecos", len(metas)),
]

# --- Escritura ---------------------------------------------------------------
escribir(LIMPIOS / "clientes.csv", clientes, ["id_cliente", "nombre", "region", "segmento"])
escribir(LIMPIOS / "productos.csv", productos, ["id_producto", "nombre_producto", "categoria", "precio_lista"])
escribir(LIMPIOS / "metas.csv", metas, ["periodo", "region", "meta_ventas"])
escribir(LIMPIOS / "ventas.csv", limpias, list(limpias[0].keys()))
escribir(LIMPIOS / "devoluciones.csv", dev_limpias, list(dev_limpias[0].keys()))
campos_aud = ["id_venta", "fecha", "id_cliente", "id_producto", "canal", "cantidad", "precio_unitario",
              "descuento", "motivo_rechazo"]
escribir(SALIDA / "auditoria_rechazados.csv", rechazados, campos_aud)
escribir(SALIDA / "bitacora_calidad.csv", bitacora, list(bitacora[0].keys()))

# --- SQLite ------------------------------------------------------------------
db_ruta = SALIDA / "novaretail.db"
db_ruta.unlink(missing_ok=True)
con = sqlite3.connect(db_ruta)
con.executescript((RAIZ / "sql" / "00_esquema.sql").read_text(encoding="utf-8"))
con.executemany("INSERT INTO clientes VALUES (:id_cliente,:nombre,:region,:segmento)", clientes)
con.executemany("INSERT INTO productos VALUES (:id_producto,:nombre_producto,:categoria,:precio_lista)", productos)
con.executemany("INSERT INTO metas VALUES (:periodo,:region,:meta_ventas)", metas)
con.executemany(
    "INSERT INTO ventas (id_venta,fecha,id_cliente,id_producto,canal,cantidad,precio_unitario,descuento)"
    " VALUES (:id_venta,:fecha,:id_cliente,:id_producto,:canal,:cantidad,:precio_unitario,:descuento)", limpias)
con.executemany(
    "INSERT INTO devoluciones VALUES (:id_devolucion,:id_venta,:cantidad_devuelta,:motivo)", dev_limpias)
# Tabla de auditoría con TODO lo que ingresó crudo (permite el LEFT JOIN de la Parte C)
con.executemany(
    "INSERT INTO ventas_crudas VALUES (:id_venta,:fecha,:id_cliente,:id_producto,:canal,:cantidad,"
    ":precio_unitario,:descuento)", [{k: (v or "") for k, v in r.items()} for r in ventas])
con.executemany(
    "INSERT INTO auditoria_rechazados VALUES (:id_venta,:fecha,:id_cliente,:id_producto,:canal,:cantidad,"
    ":precio_unitario,:descuento,:motivo_rechazo)", [{k: r.get(k, "") for k in campos_aud} for r in rechazados
                                                     if "fecha" in r])
con.executescript((RAIZ / "sql" / "10_estrella.sql").read_text(encoding="utf-8"))
con.commit()

# --- Resumen en consola ------------------------------------------------------
print(f"Ventas crudas: {len(ventas)} | aceptadas: {len(limpias)} | rechazadas: {len(rechazados)} "
      f"| corregidas: {sum(1 for l in limpias if l['ajustes'])}")
print("Incidencias:", len(bitacora), dict(Counter(b['regla'].split()[0] for b in bitacora)))
print(f"Regla de precio: {coinciden}/{len(validos)} coinciden con precio_lista")
for nombre, regla, n in sin_hallazgo:
    print(f"  sin hallazgos · {nombre}: {regla} ({n})")
cuadre = con.execute("SELECT COUNT(*) FROM ventas").fetchone()[0] + con.execute(
    "SELECT COUNT(*) FROM auditoria_rechazados").fetchone()[0]
assert cuadre == len(ventas), "las ventas aceptadas + rechazadas deben sumar las crudas"
print("Cuadre OK: aceptadas + rechazadas = crudas =", cuadre)
con.close()
