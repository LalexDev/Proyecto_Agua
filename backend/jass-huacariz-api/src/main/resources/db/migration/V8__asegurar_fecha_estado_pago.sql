ALTER TABLE pagos
ADD COLUMN IF NOT EXISTS fecha_estado_pago TIMESTAMP;

UPDATE pagos
SET fecha_estado_pago = COALESCE(fecha_pago, CURRENT_TIMESTAMP)
WHERE fecha_estado_pago IS NULL;