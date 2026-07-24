CREATE INDEX IF NOT EXISTS idx_clientes_dni ON clientes(dni);
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo_usuario ON usuarios(codigo_usuario);

CREATE INDEX IF NOT EXISTS idx_suministros_codigo ON suministros(codigo_suministro);
CREATE INDEX IF NOT EXISTS idx_suministros_cliente ON suministros(cliente_id);
CREATE INDEX IF NOT EXISTS idx_suministros_sector ON suministros(sector_id);

CREATE INDEX IF NOT EXISTS idx_lecturas_suministro_periodo ON lecturas(suministro_id, anio, mes);

CREATE INDEX IF NOT EXISTS idx_recibos_suministro_periodo ON recibos(suministro_id, anio, mes);
CREATE INDEX IF NOT EXISTS idx_recibos_estado_fecha ON recibos(estado_recibo, fecha_emision DESC);
CREATE INDEX IF NOT EXISTS idx_recibos_codigo ON recibos(codigo_recibo);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimiento ON recibos(fecha_vencimiento);

CREATE INDEX IF NOT EXISTS idx_pagos_recibo ON pagos(recibo_id);
CREATE INDEX IF NOT EXISTS idx_pagos_estado_fecha ON pagos(estado_pago, fecha_pago DESC);
