#!/bin/sh
# Copia de trabajo del día: duplica la copia más reciente de base/ (o la base del lab 1 si no hay)
# como base/novaretail_lab2_AAAA-MM-DD.db y la abre en DBeaver como conexión lab2_AAAA-MM-DD.
set -e
cd "$(dirname "$0")"
HOY=$(date +%F)
DESTINO="base/novaretail_lab2_$HOY.db"
if [ -f "$DESTINO" ]; then
  echo "Ya existe $DESTINO"
else
  ULTIMA=$(ls base/novaretail_lab2_*.db 2>/dev/null | sort | tail -1)
  ORIGEN=${ULTIMA:-../1.guia/salida/novaretail.db}
  cp "$ORIGEN" "$DESTINO"
  echo "Copia del día: $ORIGEN -> $DESTINO"
fi
/Applications/DBeaver.app/Contents/MacOS/dbeaver -nosplash \
  -con "driver=sqlite|database=$PWD/$DESTINO|name=lab2_$HOY|folder=Laboratorio 2|connect=true|openConsole=true|save=true" >/dev/null 2>&1 &
