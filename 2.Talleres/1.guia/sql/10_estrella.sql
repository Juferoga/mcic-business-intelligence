-- Esquema estrella orientado al análisis, derivado del modelo operacional.
-- Hechos: fact_ventas (1 fila por venta), fact_devoluciones (1 por devolución), fact_metas (1 por mes x región).
-- Dimensiones conformadas: dim_fecha, dim_cliente (trae región), dim_producto, dim_canal.

CREATE TABLE dim_fecha AS
SELECT DISTINCT
  CAST(REPLACE(fecha,'-','') AS INTEGER) AS sk_fecha,
  fecha,
  substr(fecha,1,7)                       AS periodo,
  CAST(substr(fecha,1,4) AS INTEGER)      AS anio,
  CAST(substr(fecha,6,2) AS INTEGER)      AS mes,
  (CAST(substr(fecha,6,2) AS INTEGER)+2)/3 AS trimestre
FROM ventas;

CREATE TABLE dim_cliente  AS SELECT id_cliente AS sk_cliente, nombre, region, segmento FROM clientes;
CREATE TABLE dim_producto AS SELECT id_producto AS sk_producto, nombre_producto, categoria, precio_lista FROM productos;
CREATE TABLE dim_canal    AS SELECT ROW_NUMBER() OVER (ORDER BY canal) AS sk_canal, canal FROM (SELECT DISTINCT canal FROM ventas);

CREATE TABLE fact_ventas AS
SELECT v.id_venta,
       CAST(REPLACE(v.fecha,'-','') AS INTEGER) AS sk_fecha,
       v.id_cliente  AS sk_cliente,
       v.id_producto AS sk_producto,
       k.sk_canal,
       v.cantidad, v.precio_unitario, v.descuento,
       v.cantidad * v.precio_unitario                    AS importe_bruto,
       v.cantidad * v.precio_unitario * (1 - v.descuento) AS importe_neto
FROM ventas v JOIN dim_canal k ON k.canal = v.canal;

-- Valor devuelto = unidades devueltas al precio neto de la venta original (sin duplicar importes de la venta).
CREATE TABLE fact_devoluciones AS
SELECT d.id_devolucion, d.id_venta,
       CAST(REPLACE(v.fecha,'-','') AS INTEGER) AS sk_fecha_venta,
       v.id_cliente AS sk_cliente, v.id_producto AS sk_producto,
       d.motivo, d.cantidad_devuelta,
       d.cantidad_devuelta * v.precio_unitario * (1 - v.descuento) AS valor_devuelto
FROM devoluciones d JOIN ventas v ON v.id_venta = d.id_venta;

CREATE TABLE fact_metas AS SELECT periodo, region, meta_ventas FROM metas;
