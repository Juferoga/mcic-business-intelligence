-- Esquema operacional normalizado (3FN) de NovaRetail 360.
-- Las claves foráneas están declaradas; SQLite no las valida si no se activa PRAGMA foreign_keys.
PRAGMA foreign_keys = ON;

CREATE TABLE clientes (
  id_cliente  TEXT PRIMARY KEY,
  nombre      TEXT NOT NULL,
  region      TEXT NOT NULL,
  segmento    TEXT NOT NULL CHECK (segmento IN ('Persona','Corporativo'))
);

CREATE TABLE productos (
  id_producto     TEXT PRIMARY KEY,
  nombre_producto TEXT NOT NULL,
  categoria       TEXT NOT NULL,
  precio_lista    INTEGER NOT NULL CHECK (precio_lista > 0)
);

-- Granularidad: UNA FILA POR VENTA (una línea de producto por transacción).
CREATE TABLE ventas (
  id_venta        TEXT PRIMARY KEY,
  fecha           TEXT NOT NULL CHECK (fecha GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  id_cliente      TEXT NOT NULL REFERENCES clientes (id_cliente),
  id_producto     TEXT NOT NULL REFERENCES productos (id_producto),
  canal           TEXT NOT NULL CHECK (canal IN ('Web','Marketplace','Tienda')),
  cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario INTEGER NOT NULL CHECK (precio_unitario > 0),
  descuento       REAL NOT NULL CHECK (descuento >= 0 AND descuento <= 1),
  importe_bruto   REAL GENERATED ALWAYS AS (cantidad * precio_unitario) VIRTUAL,
  importe_neto    REAL GENERATED ALWAYS AS (cantidad * precio_unitario * (1 - descuento)) VIRTUAL
);

-- Se vincula a la venta original (N devoluciones posibles por venta).
CREATE TABLE devoluciones (
  id_devolucion     TEXT PRIMARY KEY,
  id_venta          TEXT NOT NULL REFERENCES ventas (id_venta),
  cantidad_devuelta INTEGER NOT NULL CHECK (cantidad_devuelta > 0),
  motivo            TEXT NOT NULL
);

-- Granularidad: UNA FILA POR MES Y REGIÓN (distinta a la de ventas).
CREATE TABLE metas (
  periodo     TEXT NOT NULL,
  region      TEXT NOT NULL,
  meta_ventas INTEGER NOT NULL CHECK (meta_ventas > 0),
  PRIMARY KEY (periodo, region)
);

-- Capa de auditoría: lo que llegó tal cual y lo que se apartó (sin restricciones).
CREATE TABLE ventas_crudas (
  id_venta TEXT, fecha TEXT, id_cliente TEXT, id_producto TEXT, canal TEXT,
  cantidad TEXT, precio_unitario TEXT, descuento TEXT
);
CREATE TABLE auditoria_rechazados (
  id_venta TEXT, fecha TEXT, id_cliente TEXT, id_producto TEXT, canal TEXT,
  cantidad TEXT, precio_unitario TEXT, descuento TEXT, motivo_rechazo TEXT
);
