CREATE TABLE IF NOT EXISTS canales_pago (
    id SERIAL PRIMARY KEY,
    metodo_pago VARCHAR(50) NOT NULL,
    titular VARCHAR(120) NOT NULL,
    numero VARCHAR(80),
    banco VARCHAR(100),
    cuenta VARCHAR(100),
    cci VARCHAR(120),
    descripcion VARCHAR(255),
    qr_url VARCHAR(255),
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO canales_pago (
    metodo_pago, titular, numero, banco, cuenta, cci, descripcion, qr_url, estado
)
VALUES
('YAPE', 'Agua Potable Huacariz', '999999999', NULL, NULL, NULL, 'Pago mediante Yape. Verifica que el titular sea Agua Potable Huacariz.', NULL, TRUE),
('PLIN', 'Agua Potable Huacariz', '999999999', NULL, NULL, NULL, 'Pago mediante Plin. Verifica que el titular sea Agua Potable Huacariz.', NULL, TRUE),
('TRANSFERENCIA', 'Agua Potable Huacariz', NULL, 'BCP', '000-000000000-00', '000-000-000000000000-00', 'Transferencia bancaria a cuenta institucional.', NULL, TRUE);