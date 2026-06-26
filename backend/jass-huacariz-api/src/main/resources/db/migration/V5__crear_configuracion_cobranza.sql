CREATE TABLE IF NOT EXISTS configuracion_cobranza (
    id INTEGER PRIMARY KEY,
    cargo_lector NUMERIC(10, 2) NOT NULL DEFAULT 3.00,
    cargo_mantenimiento NUMERIC(10, 2) NOT NULL DEFAULT 3.00,
    cargo_otros NUMERIC(10, 2) NOT NULL DEFAULT 0.25,
    dias_vencimiento INTEGER NOT NULL DEFAULT 15,
    mora_base NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_cargo_lector_no_negativo
        CHECK (cargo_lector >= 0),

    CONSTRAINT chk_cargo_mantenimiento_no_negativo
        CHECK (cargo_mantenimiento >= 0),

    CONSTRAINT chk_cargo_otros_no_negativo
        CHECK (cargo_otros >= 0),

    CONSTRAINT chk_mora_base_no_negativa
        CHECK (mora_base >= 0),

    CONSTRAINT chk_dias_vencimiento_positivo
        CHECK (dias_vencimiento > 0)
);

-- Corrige bases de datos donde la tabla ya existía
-- con la columna antigua "otros_cargos".
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'configuracion_cobranza'
          AND column_name = 'otros_cargos'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'configuracion_cobranza'
          AND column_name = 'cargo_otros'
    ) THEN
        ALTER TABLE configuracion_cobranza
            RENAME COLUMN otros_cargos TO cargo_otros;
    END IF;
END
$$;

-- Garantiza que la columna exista aunque la tabla
-- haya sido creada previamente con otra estructura.
ALTER TABLE configuracion_cobranza
    ADD COLUMN IF NOT EXISTS cargo_otros
    NUMERIC(10, 2) NOT NULL DEFAULT 0.25;

INSERT INTO configuracion_cobranza (
    id,
    cargo_lector,
    cargo_mantenimiento,
    cargo_otros,
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