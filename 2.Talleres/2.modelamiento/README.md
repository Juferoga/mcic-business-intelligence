# Laboratorio 2 · Modelamiento dimensional e indicadores

Inteligencia de Negocios · Ing. Nancy Gélvez García PhD. · UDistrital · Caso NovaRetail 360

**Equipo:** Juan Felipe Rodríguez Galindo (20261595004) · Carlos Stiven Mora Hoyos (20261595003)

Pregunta orientadora: ¿se están cumpliendo las metas comerciales de NovaRetail 360?

## Estructura

| Carpeta | Contenido |
|---|---|
| `bibliografia/` | Enunciado (PDF) y plantilla original del catálogo de KPI, sin tocar |
| `base/novaretail_lab2_AAAA-MM-DD.db` | Una copia de trabajo por día (`make dia`); la primera sale de `../1.guia/salida/novaretail.db`, que no se toca |
| `informe/informe.tex` | Informe en LaTeX con la plantilla UD (`make informe`) |
| `sql/` | `clase1_reto_oltp.sql` (parte 1), `clase1_estrella_PLANTILLA.sql` (parte 2, completo con C1–C5 y respuestas) y `parte3_cambios_dimension.sql` (tipo 1 y 2, termina en ROLLBACK) |
| `modelo/modelo_estrella.py` | Parte 4 sin Power BI: relaciones, medidas, matriz y conciliación con C2/C3 (`make modelo`) |
| `kpi/Catalogo_KPI_NovaRetail.xlsx` | Catálogo que se va a llenar (parte 5) |
| `csv_estrella/` | Las 8 tablas de la estrella exportadas a CSV para Power BI (parte 4) |
| `capturas/` | `vista_modelo.png` y `matriz_cumplimiento.png`, generadas por `make modelo` |
| `entrega/` | Lo que se sube al aula |

## Estado de la base (paso 0)

- Las cinco tablas tienen los nombres y columnas que espera la plantilla: no hacen falta vistas.
- Fechas en `aaaa-mm-dd`, periodos en `aaaa-mm`, canales: Marketplace (411), Tienda (404), Web (378).
- **Ventas en la base: 1193** (se usa en el control C1).
- `clase1_reto_oltp.sql` corre sin errores sobre la copia.

## Herramientas

- DBeaver (en lugar de DB Browser for SQLite): `make dia` crea la copia del día y la abre como conexión
  `lab2_AAAA-MM-DD` en la carpeta *Laboratorio 2*. `novaretail_demo` es la base del lab 1.
- LaTeX: `make informe` compila con tectonic y `ud-informe.sty` del manual de marca UD.
- Power BI Desktop no corre en Mac: la parte 4 se reprodujo en Python (`uv run`, sin instalar nada) sobre los CSV de `csv_estrella/`.

## Entregables

`make entrega` arma `entrega/juan-rodriguez-carlos-mora-lab2-novaretail.zip` (informe, SQL, catálogo, modelo, CSV, capturas y la base del día), con la misma estructura de carpetas.

1. `sql/clase1_estrella_PLANTILLA.sql` completo, con C1–C5 y las tres respuestas como comentario.
2. Captura de la vista de modelo de Power BI con las 8 relaciones.
3. Catálogo de KPI (fichas K1–K4 y hoja Validación).
4. Párrafo de máximo cinco líneas que responda la pregunta orientadora con las cifras.
