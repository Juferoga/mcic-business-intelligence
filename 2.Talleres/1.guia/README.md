# Taller 1 · NovaRetail 360

Guía de laboratorio de Inteligencia de Negocios (Power Query, modelo relacional y SQL). Ver `Guia_NovaRetail_360.pdf`.

| Entregable | Ruta |
|---|---|
| Informe (PDF, plantilla UD) | `informe/informe.pdf` |
| Presentación (PDF, tema Beamer UD) | `presentacion/presentacion.pdf` |
| Guía para hacer la parte de Power BI desde un Mac | `guia-powerbi/guia_powerbi.pdf` (+ `make paquete` crea `paquete_powerbi.zip`) |
| Portal explicativo | `portal/index.html` (abrir en el navegador) |
| Bitácora de calidad, auditoría, datos limpios, SQLite | `salida/` |
| Consultas SQL (esquema, estrella, 5 consultas, calidad) | `sql/` |
| Power Query (M), ejecutado en Power BI | `power_query/` |
| **Archivo Power BI** (8 consultas, 7 relaciones, 13 medidas, 3 páginas) | `NovaRetail360.pbix` |
| Capturas del informe y del modelo en Power BI | `evidencias_powerbi/` |

Reproducir todo: `make todo` (requiere `python3`, `uv`, `tectonic`, y el manual de marca en `~/repos/ud/maestria/mcic/.UniversidadDistrital-manual-marca`).
El portal se regenera con `python3 pipeline/portal.py`.

Los CSV originales de la guía (`*.csv`, `consultas_referencia.sql`) no se modificaron.
