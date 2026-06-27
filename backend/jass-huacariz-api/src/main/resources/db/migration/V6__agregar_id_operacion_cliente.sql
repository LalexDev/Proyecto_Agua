ALTER TABLE lecturas
    ADD COLUMN IF NOT EXISTS id_operacion_cliente VARCHAR(80);

CREATE UNIQUE INDEX IF NOT EXISTS uk_lecturas_id_operacion_cliente
    ON lecturas(id_operacion_cliente)
    WHERE id_operacion_cliente IS NOT NULL;
