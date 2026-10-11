UD ?= $(HOME)/repos/ud/maestria/mcic/.UniversidadDistrital-manual-marca/plantillas-latex
TEX = tectonic -Z search-path=$(UD)

.PHONY: todo portal datos paquete guia informe presentacion revisar
todo: datos portal informe presentacion revisar

datos:
	python3 pipeline/limpieza.py
	uv run --no-project --with matplotlib python pipeline/graficos.py

informe:
	cd informe && $(TEX) informe.tex

presentacion:
	cd presentacion && $(TEX) presentacion.tex

revisar:
	uv run --no-project --with pymupdf python $(UD)/revisar_pdf.py presentacion/presentacion.pdf

portal:
	python3 pipeline/portal.py

# Carpeta y zip para llevar a la máquina Windows (ver guia-powerbi/guia_powerbi.pdf)
paquete:
	rm -rf paquete_powerbi paquete_powerbi.zip && mkdir -p paquete_powerbi/consultas_M
	cp clientes.csv productos.csv devoluciones.csv metas.csv ventas_sucias.csv paquete_powerbi/
	cp salida/bitacora_calidad.csv paquete_powerbi/
	cp power_query/*.pq power_query/ud-tema-powerbi.json paquete_powerbi/consultas_M/
	cp guia-powerbi/guia_powerbi.pdf paquete_powerbi/ 2>/dev/null || true
	zip -qr paquete_powerbi.zip paquete_powerbi
	@echo "Listo: paquete_powerbi.zip"

guia:
	cd guia-powerbi && $(TEX) guia_powerbi.tex
