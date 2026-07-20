CREATE TABLE IF NOT EXISTS movimientos_caja (
    id SERIAL PRIMARY KEY,
    tipo_movimiento VARCHAR(20) NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    responsable VARCHAR(120),
    comprobante_url VARCHAR(255),
    fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT chk_movimiento_caja_tipo
        CHECK (tipo_movimiento IN ('INGRESO', 'EGRESO')),

    CONSTRAINT chk_movimiento_caja_estado
        CHECK (estado IN ('ACTIVO', 'ANULADO')),

    CONSTRAINT chk_movimiento_caja_monto
        CHECK (monto > 0)
);

CREATE INDEX IF NOT EXISTS idx_movimientos_caja_fecha
ON movimientos_caja(fecha_movimiento);

CREATE INDEX IF NOT EXISTS idx_movimientos_caja_estado
ON movimientos_caja(estado);