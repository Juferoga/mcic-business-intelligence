# 👻  **INTELIGENCIA DE NEGOCIOS**

<p align="right">
	<img src="https://www.udistrital.edu.co/themes/custom/versh/images/default/preloader.png" width="128" height="128" alt="UDistrital" />
</p>

[![Autor: Juferoga](https://img.shields.io/badge/Autor-Juferoga-0a66c2?style=flat-square)](https://github.com/Juferoga) [![License: GPL2](https://img.shields.io/badge/License-GPL2-blue?style=flat-square)](LICENSE)

Repositorio de la asignatura *Inteligencia de Negocios* (Maestría). Aquí se conservan los talleres, trabajos y el proyecto final desarrollados durante el semestre.

**Contenido rápido**

- **Estado:** En curso — semestre 2026-3
- **Autor:** Juan Felipe Rodríguez Galindo (Juferoga)
- **Docente:** Nancy Yaneth Gelvez Garcia
- **Licencia:** GPL2 — ver archivo `LICENSE`

**Tabla de contenidos**

- Avance
- Estructura del repositorio
- Cómo reproducir el Taller 1
- Licencia

## Avance

| Entrega | Tema | Carpeta |
|---|---|---|
| Taller 1 | Guía *NovaRetail 360*: limpieza de datos, Power Query, modelo en estrella y SQL, informe y presentación | [`2.Talleres/1.guia/`](2.Talleres/1.guia/) |
| Proyecto final | Proyecto integrador de inteligencia de negocios (con Carlos Mora): SQL, esquema estrella, modelo de conversión y simulación Monte Carlo. Submódulo: [`mcic-inteligencia-negocios`](4.ProyectoFinal/mcic-inteligencia-negocios/). Además, datos base de los sorteos de loterías de Colombia (corte 2026-09-02) y panel en Excel | [`4.ProyectoFinal/`](4.ProyectoFinal/) |

## Estructura del repositorio

- `0.Bibliografia/` — Material de referencia y recursos bibliográficos.
- `1.Tareas/` — Entregas formales por actividad.
- `2.Talleres/` — Ejercicios prácticos y pequeñas aplicaciones.
  - `1.guia/` — Taller 1 (ver su [README](2.Talleres/1.guia/README.md)): `pipeline/` (limpieza y gráficos en Python), `power_query/` (consultas M), `sql/` (esquema, estrella, consultas y calidad), `informe/`, `presentacion/`, `guia-powerbi/`, `portal/` y `salida/`.
- `3.Trabajos/` — Trabajos y entregas mayores.
- `4.ProyectoFinal/` — Datos y documentación del proyecto final.
- `docs/` — Página estática `index.html` (Loterías de Colombia · Sorteos 2020–2023).
- `README.md` — Este archivo.
- `LICENSE` — Licencia del repositorio.

## Cómo reproducir el Taller 1

Requiere `python3`, `uv` y `tectonic`, además del manual de marca de la UD (plantillas LaTeX) del [repositorio raíz](https://github.com/Juferoga/mcic).

```bash
cd 2.Talleres/1.guia
make todo        # datos, portal, informe, presentación y revisión del PDF
make paquete     # genera paquete_powerbi.zip para llevar a Power BI (Windows)
```

> El archivo `2.Talleres/1.guia/NovaRetail360.pbix` contiene las consultas Power Query, el modelo, las medidas DAX y el informe; las capturas están en `2.Talleres/1.guia/evidencias_powerbi/`.

**Contacto**

- Juan Felipe Rodríguez Galindo — https://github.com/Juferoga

**Licencia**

Este repositorio está bajo la licencia GPL V2. Consulta el archivo `LICENSE` para más detalles.
