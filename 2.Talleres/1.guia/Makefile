UD ?= $(HOME)/repos/ud/maestria/mcic/.UniversidadDistrital-manual-marca/plantillas-latex
TEX = tectonic -Z search-path=$(UD)

.PHONY: todo portal datos paquete guia informe presentacion revisar entrega
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

# Zip para subir al aula virtual ("Desarrollo Laboratorio PQ")
ENTREGA = juan-rodriguez-20261595004-lab-novaretail
entrega:
	rm -rf $(ENTREGA) $(ENTREGA).zip && mkdir -p $(ENTREGA)/salida
	cp informe/informe.pdf presentacion/presentacion.pdf NovaRetail360.pbix README.md $(ENTREGA)/
	cp -R evidencias_powerbi power_query sql pipeline $(ENTREGA)/
	cp -R salida/datos_limpios salida/figuras salida/novaretail.db salida/bitacora_calidad.csv \
	      salida/auditoria_rechazados.csv salida/resultados.json $(ENTREGA)/salida/
	find $(ENTREGA) -name '.DS_Store' -delete
	zip -qr $(ENTREGA).zip $(ENTREGA) && rm -rf $(ENTREGA)
	@echo "Listo: $(ENTREGA).zip"
