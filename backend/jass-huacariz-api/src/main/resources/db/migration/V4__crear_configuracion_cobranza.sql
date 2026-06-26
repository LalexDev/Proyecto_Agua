CREATE TABLE IF NOT EXISTS configuracion_cobranza (
    id INTEGER PRIMARY KEY,
    cargo_lector NUMERIC(10, 2) NOT NULL DEFAULT 3.00,
    cargo_mantenimiento NUMERIC(10, 2) NOT NULL DEFAULT 3.00,
    otros_cargos NUMERIC(10, 2) NOT NULL DEFAULT 0.25,
    dias_vencimiento INTEGER NOT NULL DEFAULT 15,
    mora_base NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_cargo_lector_no_negativo
        CHECK (cargo_lector >= 0),

    CONSTRAINT chk_cargo_mantenimiento_no_negativo
        CHECK (cargo_mantenimiento >= 0),

    CONSTRAINT chk_otros_cargos_no_negativo
        CHECK (otros_cargos >= 0),

    CONSTRAINT chk_mora_base_no_negativa
        CHECK (mora_base >= 0),

    CONSTRAINT chk_dias_vencimiento_positivo
        CHECK (dias_vencimiento > 0)
);

INSERT INTO configuracion_cobranza (
    id,
    cargo_lector,
    cargo_mantenimiento,
    otros_cargos,
    dias_vencimiento,
    mora_base
)
VALUES (
    1,
    3.00,
    3.00,
    0.25,
    15,
    2.00
)
ON CONFLICT (id) DO NOTHING;