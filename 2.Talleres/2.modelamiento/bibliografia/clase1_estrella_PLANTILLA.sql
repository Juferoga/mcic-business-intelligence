-- =====================================================================
-- NovaRetail 360 · Clase 1 · Modelo estrella (PLANTILLA DEL ESTUDIANTE)
-- Complete las secciones marcadas con TODO. Las demás ya funcionan.
-- Equipo: ____________________________________________
-- Inteligencia de Negocios · Ing. Nancy Gélvez Garcia PhD. · UDistrital
--
-- Se ejecuta sobre novaretail_base.db (tablas operacionales depuradas:
-- clientes, productos, ventas, devoluciones, metas).
-- Herramienta: DB Browser for SQLite, pestaña "Ejecutar SQL", o cualquier
-- cliente con SQLite 3.25 o superior.
--
-- Esquema resultante:
--   DimPeriodo (mes) 1--* DimFecha (día) 1--* FactVentas
--   DimPeriodo (mes) 1--* FactMetas
--   DimRegion        1--* FactVentas  y  1--* FactMetas
--   DimCliente, DimProducto, DimCanal 1--* FactVentas
-- Las dos tablas de hechos NUNCA se unen entre sí: se comparan a través de
-- las dimensiones compartidas DimRegion y DimPeriodo.
-- =====================================================================

-- =====================================================================
-- PASO 0. Verifique su base del laboratorio 1 ANTES de construir la estrella
-- Este script espera cinco tablas depuradas con estos nombres y columnas:
--   clientes(id_cliente, nombre, region, segmento)
--   productos(id_producto, nombre_producto, categoria, precio_lista)
--   ventas(id_venta, fecha, id_cliente, id_producto, canal, cantidad,
--          precio_unitario, descuento)       -- fecha en formato aaaa-mm-dd
--   devoluciones(id_devolucion, id_venta, cantidad_devuelta, motivo)
--   metas(periodo, region, meta_ventas)     -- periodo en formato aaaa-mm
-- Si su base usa otros nombres, renómbrelos o cree vistas con estos nombres
-- (por ejemplo: CREATE VIEW ventas AS SELECT ... FROM ventas_limpias;).
-- =====================================================================

-- 0.1 Deben aparecer las cinco tablas (o vistas).
SELECT name, type FROM sqlite_master
WHERE name IN ('clientes', 'productos', 'ventas', 'devoluciones', 'metas')
ORDER BY name;

-- 0.2 Columnas de ventas: compare con la lista de arriba.
SELECT name, type FROM pragma_table_info('ventas');

-- 0.3 Fechas fuera del formato aaaa-mm-dd o vacías. Esperado: 0.
SELECT COUNT(*) AS fechas_con_problema
FROM ventas
WHERE fecha IS NULL OR fecha NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';

-- 0.4 Canales distintos. Esperado: Marketplace, Tienda y Web, sin variantes.
SELECT canal, COUNT(*) AS ventas FROM ventas GROUP BY canal;

-- 0.5 Cuántas ventas tiene SU base. Anote el número: lo usará en el control C1.
SELECT COUNT(*) AS ventas_en_mi_base FROM ventas;

DROP TABLE IF EXISTS FactVentas;
DROP TABLE IF EXISTS FactMetas;
DROP TABLE IF EXISTS DimFecha;
DROP TABLE IF EXISTS DimPeriodo;
DROP TABLE IF EXISTS DimRegion;
DROP TABLE IF EXISTS DimCliente;
DROP TABLE IF EXISTS DimProducto;
DROP TABLE IF EXISTS DimCanal;

-- ---------------------------------------------------------------------
-- 1. DimPeriodo: una fila por mes (grano de las metas)
-- ---------------------------------------------------------------------
CREATE TABLE DimPeriodo (
    id_periodo  TEXT PRIMARY KEY,      -- 'aaaa-mm'
    anio        INTEGER NOT NULL,
    mes         INTEGER NOT NULL,
    nombre_mes  TEXT    NOT NULL,
    trimestre   TEXT    NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. DimFecha: una fila por día del semestre, con su periodo mensual
-- ---------------------------------------------------------------------
CREATE TABLE DimFecha (
    id_fecha    INTEGER PRIMARY KEY,   -- aaaammdd
    fecha       TEXT    NOT NULL,      -- 'aaaa-mm-dd'
    anio        INTEGER NOT NULL,
    mes         INTEGER NOT NULL,
    dia         INTEGER NOT NULL,
    dia_semana  TEXT    NOT NULL,
    es_fin_semana INTEGER NOT NULL,
    id_periodo  TEXT    NOT NULL REFERENCES DimPeriodo(id_periodo)
);

-- Primero los meses (DimPeriodo), porque DimFecha los referencia.
WITH RECURSIVE meses(m) AS (
    SELECT date('2026-01-01')
    UNION ALL
    SELECT date(m, '+1 month') FROM meses WHERE m < '2026-06-01'
)
INSERT INTO DimPeriodo
SELECT strftime('%Y-%m', m),
       CAST(strftime('%Y', m) AS INTEGER),
       CAST(strftime('%m', m) AS INTEGER),
       CASE CAST(strftime('%m', m) AS INTEGER)
            WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
            WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo'    WHEN 6 THEN 'Junio'
            WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto'  WHEN 9 THEN 'Septiembre'
            WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' ELSE 'Diciembre' END,
       strftime('%Y', m) || '-T' || ((CAST(strftime('%m', m) AS INTEGER) - 1) / 3 + 1)
FROM meses;

-- Luego los días del semestre.
WITH RECURSIVE dias(d) AS (
    SELECT date('2026-01-01')
    UNION ALL
    SELECT date(d, '+1 day') FROM dias WHERE d < '2026-06-30'
)
INSERT INTO DimFecha
SELECT CAST(strftime('%Y%m%d', d) AS INTEGER),
       d,
       CAST(strftime('%Y', d) AS INTEGER),
       CAST(strftime('%m', d) AS INTEGER),
       CAST(strftime('%d', d) AS INTEGER),
       CASE strftime('%w', d)
            WHEN '0' THEN 'Domingo'   WHEN '1' THEN 'Lunes'  WHEN '2' THEN 'Martes'
            WHEN '3' THEN 'Miércoles' WHEN '4' THEN 'Jueves' WHEN '5' THEN 'Viernes'
            ELSE 'Sábado' END,
       CASE WHEN strftime('%w', d) IN ('0', '6') THEN 1 ELSE 0 END,
       strftime('%Y-%m', d)
FROM dias;

-- ---------------------------------------------------------------------
-- 3. Dimensiones descriptivas
-- ---------------------------------------------------------------------
CREATE TABLE DimRegion (
    id_region INTEGER PRIMARY KEY,
    region    TEXT NOT NULL UNIQUE
);
-- TODO 1. Inserte una fila por región. Las regiones aparecen en clientes
--         y en metas: tómelas de ambas tablas sin repetir (pista: UNION).
INSERT INTO DimRegion (region)
SELECT /* TODO */ ;

-- DimCliente se prepara para cambios en dimensiones tipo 2:
-- clave sustituta (sk_cliente) distinta de la clave de negocio (id_cliente)
-- y columnas de vigencia.
CREATE TABLE DimCliente (
    sk_cliente     INTEGER PRIMARY KEY,
    id_cliente     TEXT NOT NULL,
    nombre         TEXT NOT NULL,
    segmento       TEXT NOT NULL,
    region         TEXT NOT NULL,      -- atributo descriptivo (sin relación en Power BI)
    vigente_desde  TEXT NOT NULL,
    vigente_hasta  TEXT NOT NULL,
    es_actual      INTEGER NOT NULL
);
INSERT INTO DimCliente (id_cliente, nombre, segmento, region, vigente_desde, vigente_hasta, es_actual)
SELECT id_cliente, nombre, segmento, region, '2026-01-01', '9999-12-31', 1
FROM clientes
ORDER BY id_cliente;

CREATE TABLE DimProducto (
    sk_producto     INTEGER PRIMARY KEY,
    id_producto     TEXT NOT NULL UNIQUE,
    nombre_producto TEXT NOT NULL,
    categoria       TEXT NOT NULL,
    precio_lista    INTEGER NOT NULL
);
-- TODO 2. Cargue DimProducto desde la tabla productos.
INSERT INTO DimProducto (id_producto, nombre_producto, categoria, precio_lista)
SELECT /* TODO */ ;

CREATE TABLE DimCanal (
    id_canal INTEGER PRIMARY KEY,
    canal    TEXT NOT NULL UNIQUE
);
-- TODO 3. Una fila por canal distinto de la tabla ventas.
INSERT INTO DimCanal (canal)
SELECT /* TODO */ ;

-- ---------------------------------------------------------------------
-- 4. FactVentas: grano = una línea de venta (id_venta)
-- Las devoluciones se integran como medidas porque cada venta tiene
-- como máximo una devolución; se agregan por id_venta por precaución.
-- La región se guarda en el hecho: es la región del cliente al momento
-- de la venta (clave para los cambios en dimensiones).
-- ---------------------------------------------------------------------
CREATE TABLE FactVentas (
    id_venta          TEXT PRIMARY KEY,               -- dimensión degenerada
    id_fecha          INTEGER NOT NULL REFERENCES DimFecha(id_fecha),
    sk_cliente        INTEGER NOT NULL REFERENCES DimCliente(sk_cliente),
    sk_producto       INTEGER NOT NULL REFERENCES DimProducto(sk_producto),
    id_canal          INTEGER NOT NULL REFERENCES DimCanal(id_canal),
    id_region         INTEGER NOT NULL REFERENCES DimRegion(id_region),
    cantidad          INTEGER NOT NULL,
    precio_unitario   INTEGER NOT NULL,
    descuento         REAL    NOT NULL,
    importe_bruto     REAL    NOT NULL,
    importe_neto      REAL    NOT NULL,
    unidades_devueltas INTEGER NOT NULL,
    valor_devuelto    REAL    NOT NULL,
    ventas_netas      REAL    NOT NULL
);

WITH dev AS (
    SELECT id_venta, SUM(cantidad_devuelta) AS unidades_devueltas
    FROM devoluciones
    GROUP BY id_venta
)
INSERT INTO FactVentas
SELECT v.id_venta,
       CAST(strftime('%Y%m%d', v.fecha) AS INTEGER),
       dc.sk_cliente,
       dp.sk_producto,
       ca.id_canal,
       dr.id_region,
       v.cantidad,
       v.precio_unitario,
       v.descuento,
       v.cantidad * v.precio_unitario,
       v.cantidad * v.precio_unitario * (1 - v.descuento),
       -- TODO 4. Complete las tres medidas de devoluciones y ventas netas.
       --         Regla: la devolución se valora al precio neto pagado
       --         (precio_unitario x (1 - descuento)). Si la venta no tiene
       --         devolución, d.unidades_devueltas es NULL: use COALESCE.
       /* unidades_devueltas */ NULL,
       /* valor_devuelto     */ NULL,
       /* ventas_netas       */ NULL
FROM ventas v
JOIN DimCliente  dc ON dc.id_cliente  = v.id_cliente AND dc.es_actual = 1
JOIN DimProducto dp ON dp.id_producto = v.id_producto
JOIN DimCanal    ca ON ca.canal       = v.canal
JOIN DimRegion   dr ON dr.region      = dc.region
LEFT JOIN dev d     ON d.id_venta     = v.id_venta;

-- ---------------------------------------------------------------------
-- 5. FactMetas: grano = mes x región
-- ---------------------------------------------------------------------
CREATE TABLE FactMetas (
    id_periodo  TEXT    NOT NULL REFERENCES DimPeriodo(id_periodo),
    id_region   INTEGER NOT NULL REFERENCES DimRegion(id_region),
    meta_ventas INTEGER NOT NULL,
    PRIMARY KEY (id_periodo, id_region)
);
-- TODO 5. Cargue FactMetas desde metas, reemplazando el nombre de la
--         región por su id_region de DimRegion. ¿Cuántas filas deben quedar?
INSERT INTO FactMetas
SELECT /* TODO */ ;

-- =====================================================================
-- CONSULTAS DE CONTROL: ejecútelas al final y compare con la referencia
-- del docente. Los valores esperados que aparecen abajo corresponden a la base
-- de referencia (1.192 ventas). Si su base tiene otro número de ventas, sus
-- cifras serán distintas: explique la diferencia con su bitácora de limpieza.
-- =====================================================================

-- C1. Conteos por tabla. Esperado: FactVentas 1192, FactMetas 30,
--     DimFecha 181, DimPeriodo 6, DimRegion 5, DimCliente 120,
--     DimProducto 40, DimCanal 3.
SELECT 'FactVentas' AS tabla, COUNT(*) AS filas FROM FactVentas
UNION ALL SELECT 'FactMetas',   COUNT(*) FROM FactMetas
UNION ALL SELECT 'DimFecha',    COUNT(*) FROM DimFecha
UNION ALL SELECT 'DimPeriodo',  COUNT(*) FROM DimPeriodo
UNION ALL SELECT 'DimRegion',   COUNT(*) FROM DimRegion
UNION ALL SELECT 'DimCliente',  COUNT(*) FROM DimCliente
UNION ALL SELECT 'DimProducto', COUNT(*) FROM DimProducto
UNION ALL SELECT 'DimCanal',    COUNT(*) FROM DimCanal;

-- C2. Totales del semestre. Esperado: importe neto 698.796.460,
--     valor devuelto 29.963.315, ventas netas 668.833.145, meta 1.715.000.000.
SELECT ROUND(SUM(importe_neto))   AS importe_neto,
       ROUND(SUM(valor_devuelto)) AS valor_devuelto,
       ROUND(SUM(ventas_netas))   AS ventas_netas,
       (SELECT SUM(meta_ventas) FROM FactMetas) AS meta_total
FROM FactVentas;

-- C3. Cumplimiento por periodo y región, a través de las dimensiones
--     compartidas. Cada hecho se agrega a mes x región ANTES de compararlos.
WITH real AS (
    SELECT f.id_periodo, v.id_region, SUM(v.ventas_netas) AS ventas_netas
    FROM FactVentas v
    JOIN DimFecha f ON f.id_fecha = v.id_fecha
    GROUP BY f.id_periodo, v.id_region
)
SELECT p.nombre_mes, r.region, m.meta_ventas,
       ROUND(COALESCE(real.ventas_netas, 0)) AS ventas_netas,
       ROUND(100.0 * COALESCE(real.ventas_netas, 0) / m.meta_ventas, 1) AS cumplimiento_pct
FROM FactMetas m
JOIN DimPeriodo p ON p.id_periodo = m.id_periodo
JOIN DimRegion  r ON r.id_region  = m.id_region
LEFT JOIN real    ON real.id_periodo = m.id_periodo AND real.id_region = m.id_region
ORDER BY p.id_periodo, r.region;

-- C4. EL ERROR DE GRANULARIDAD (para mostrar en clase):
--     unir metas a cada línea de venta repite la meta.
--     Esperado: 1.192 filas y una "meta" de 68.262.000.000 en vez de 1.715.000.000.
SELECT COUNT(*) AS filas_unidas,
       SUM(m.meta_ventas) AS meta_inflada
FROM FactVentas v
JOIN DimFecha  f ON f.id_fecha = v.id_fecha
JOIN FactMetas m ON m.id_periodo = f.id_periodo AND m.id_region = v.id_region;

-- C5. KPI del semestre. Esperado: cumplimiento 39,0 %, tasa de devolución
--     4,15 % (174 / 4.190), descuento efectivo 5,10 %.
SELECT ROUND(100.0 * SUM(ventas_netas) / (SELECT SUM(meta_ventas) FROM FactMetas), 2) AS cumplimiento_pct,
       ROUND(100.0 * SUM(unidades_devueltas) / SUM(cantidad), 2)                    AS tasa_devolucion_pct,
       ROUND(100.0 * (SUM(importe_bruto) - SUM(importe_neto)) / SUM(importe_bruto), 2) AS descuento_efectivo_pct,
       ROUND(SUM(ventas_netas))                                                      AS ventas_netas
FROM FactVentas;
