-- Evita mostrar números o cuentas ficticias mientras administración
-- registra los datos oficiales de cobro.
UPDATE canales_pago
SET numero = NULL,
    descripcion = 'Número de Yape pendiente de configuración por administración.',
    fecha_actualizacion = CURRENT_TIMESTAMP
WHERE UPPER(metodo_pago) = 'YAPE'
  AND numero = '999999999';

UPDATE canales_pago
SET numero = NULL,
    descripcion = 'Número de Plin pendiente de configuración por administración.',
    fecha_actualizacion = CURRENT_TIMESTAMP
WHERE UPPER(metodo_pago) = 'PLIN'
  AND numero = '999999999';

UPDATE canales_pago
SET banco = NULL,
    cuenta = NULL,
    cci = NULL,
    descripcion = 'Datos de transferencia pendientes de configuración por administración.',
    fecha_actualizacion = CURRENT_TIMESTAMP
WHERE UPPER(metodo_pago) = 'TRANSFERENCIA'
  AND (cuenta = '000-000000000-00' OR cci = '000-000-000000000000-00');
