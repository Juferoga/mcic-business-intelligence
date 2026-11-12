UD ?= $(HOME)/repos/ud/maestria/mcic/.UniversidadDistrital-manual-marca/plantillas-latex
TEX = tectonic -Z search-path=$(UD)

.PHONY: dia informe modelo entrega

# Copia de trabajo del día en base/ y conexión lab2_AAAA-MM-DD en DBeaver
dia:
	./nuevo_dia.sh

informe:
	cd informe && $(TEX) informe.tex

# Zip con la misma estructura de carpetas, para que modelo/modelo_estrella.py corra dentro de él
ENTREGA = juan-rodriguez-carlos-mora-lab2-novaretail
DIA ?= 2026-11-11
entrega:
	rm -rf entrega/$(ENTREGA) entrega/$(ENTREGA).zip
	mkdir -p entrega/$(ENTREGA)/sql entrega/$(ENTREGA)/modelo entrega/$(ENTREGA)/csv_estrella entrega/$(ENTREGA)/capturas entrega/$(ENTREGA)/base
	cp informe/informe.pdf kpi/Catalogo_KPI_NovaRetail.xlsx entrega/$(ENTREGA)/
	cp sql/clase1_estrella_PLANTILLA.sql sql/parte3_cambios_dimension.sql entrega/$(ENTREGA)/sql/
	cp modelo/modelo_estrella.py entrega/$(ENTREGA)/modelo/
	cp csv_estrella/*.csv entrega/$(ENTREGA)/csv_estrella/
	cp capturas/*.png entrega/$(ENTREGA)/capturas/
	cp base/novaretail_lab2_$(DIA).db entrega/$(ENTREGA)/base/
	cd entrega && zip -qr $(ENTREGA).zip $(ENTREGA)
	@echo "Listo: entrega/$(ENTREGA).zip"

modelo:
	uv run --no-project --with pandas --with matplotlib python modelo/modelo_estrella.py
