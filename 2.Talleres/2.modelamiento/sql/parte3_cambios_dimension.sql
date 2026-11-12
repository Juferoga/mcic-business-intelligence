-- =====================================================================
-- NovaRetail 360 · Laboratorio 2 · Parte 3. Cambios en dimensiones
-- Equipo: Juan Felipe Rodríguez Galindo (20261595004) · Carlos Stiven Mora Hoyos (20261595003)
-- Caso hipotético: el cliente C0005 se traslada de Bogotá a Medellín el 2026-04-01.
-- Se ejecuta después de clase1_estrella_PLANTILLA.sql. Todo va dentro de una
-- transacción que termina en ROLLBACK: la base queda como estaba.
-- La región "según la dimensión" es la que vería un reporte que filtra por
-- DimCliente[region] (o una recarga del hecho que toma la región del cliente).
-- =====================================================================
BEGIN;

-- 0. Situación inicial: compras de C0005 por mes y región según la dimensión.
SELECT 'inicial' AS escenario, f.id_periodo, dc.sk_cliente, dc.region,
       COUNT(*) AS ventas, ROUND(SUM(v.ventas_netas)) AS ventas_netas
FROM FactVentas v
JOIN DimFecha f    ON f.id_fecha    = v.id_fecha
JOIN DimCliente dc ON dc.sk_cliente = v.sk_cliente
WHERE dc.id_cliente = 'C0005'
GROUP BY f.id_periodo, dc.sk_cliente, dc.region
ORDER BY f.id_periodo;

-- 1. TIPO 1: sobrescribir el atributo. Se pierde la historia.
SAVEPOINT tipo1;
UPDATE DimCliente SET region = 'Medellín' WHERE id_cliente = 'C0005';

SELECT 'tipo 1' AS escenario, f.id_periodo, dc.sk_cliente, dc.region,
       COUNT(*) AS ventas, ROUND(SUM(v.ventas_netas)) AS ventas_netas
FROM FactVentas v
JOIN DimFecha f    ON f.id_fecha    = v.id_fecha
JOIN DimCliente dc ON dc.sk_cliente = v.sk_cliente
WHERE dc.id_cliente = 'C0005'
GROUP BY f.id_periodo, dc.sk_cliente, dc.region
ORDER BY f.id_periodo;

-- Efecto sobre el cumplimiento de Bogotá, enero a marzo, si la región se toma
-- del cliente (como en la carga de FactVentas): antes vs. después del tipo 1.
SELECT p.nombre_mes, m.meta_ventas,
       ROUND(SUM(CASE WHEN c.region = 'Bogotá' THEN v.ventas_netas ELSE 0 END)) AS netas_region_original,
       ROUND(SUM(CASE WHEN dc.region = 'Bogotá' THEN v.ventas_netas ELSE 0 END)) AS netas_tipo1,
       ROUND(100.0 * SUM(CASE WHEN c.region = 'Bogotá' THEN v.ventas_netas ELSE 0 END) / m.meta_ventas, 1) AS cumpl_original_pct,
       ROUND(100.0 * SUM(CASE WHEN dc.region = 'Bogotá' THEN v.ventas_netas ELSE 0 END) / m.meta_ventas, 1) AS cumpl_tipo1_pct
FROM FactVentas v
JOIN DimFecha f    ON f.id_fecha    = v.id_fecha
JOIN DimPeriodo p  ON p.id_periodo  = f.id_periodo
JOIN DimCliente dc ON dc.sk_cliente = v.sk_cliente
JOIN clientes c    ON c.id_cliente  = dc.id_cliente
JOIN DimRegion r   ON r.region = 'Bogotá'
JOIN FactMetas m   ON m.id_periodo = p.id_periodo AND m.id_region = r.id_region
WHERE p.mes <= 3
GROUP BY p.id_periodo, p.nombre_mes, m.meta_ventas
ORDER BY p.id_periodo;
ROLLBACK TO tipo1;

-- 2. TIPO 2: cerrar la versión vigente y crear una nueva con otra sk_cliente.
UPDATE DimCliente
SET vigente_hasta = '2026-03-31', es_actual = 0
WHERE id_cliente = 'C0005' AND es_actual = 1;

INSERT INTO DimCliente (id_cliente, nombre, segmento, region, vigente_desde, vigente_hasta, es_actual)
SELECT id_cliente, nombre, segmento, 'Medellín', '2026-04-01', '9999-12-31', 1
FROM DimCliente WHERE id_cliente = 'C0005' AND vigente_hasta = '2026-03-31';

-- Las ventas desde el 1 de abril se cargan con la versión vigente en su fecha.
UPDATE FactVentas
SET sk_cliente = (SELECT sk_cliente FROM DimCliente WHERE id_cliente = 'C0005' AND es_actual = 1)
WHERE sk_cliente = (SELECT sk_cliente FROM DimCliente WHERE id_cliente = 'C0005' AND es_actual = 0)
  AND id_fecha >= 20260401;

SELECT sk_cliente, id_cliente, region, vigente_desde, vigente_hasta, es_actual
FROM DimCliente WHERE id_cliente = 'C0005' ORDER BY sk_cliente;

SELECT 'tipo 2' AS escenario, f.id_periodo, dc.sk_cliente, dc.region,
       COUNT(*) AS ventas, ROUND(SUM(v.ventas_netas)) AS ventas_netas
FROM FactVentas v
JOIN DimFecha f    ON f.id_fecha    = v.id_fecha
JOIN DimCliente dc ON dc.sk_cliente = v.sk_cliente
WHERE dc.id_cliente = 'C0005'
GROUP BY f.id_periodo, dc.sk_cliente, dc.region
ORDER BY f.id_periodo;

ROLLBACK;
