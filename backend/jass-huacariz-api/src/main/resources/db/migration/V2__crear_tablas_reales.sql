CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    codigo_usuario VARCHAR(30) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol_id INT NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (rol_id) REFERENCES roles(id)
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    dni VARCHAR(8) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(120),
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_clientes_usuarios
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE sectores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE suministros (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    sector_id INT NOT NULL,
    codigo_suministro VARCHAR(30) NOT NULL UNIQUE,
    direccion_suministro VARCHAR(180) NOT NULL,
    referencia VARCHAR(180),
    alias_suministro VARCHAR(100),
    lectura_inicial NUMERIC(10,3) NOT NULL DEFAULT 0,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_suministros_clientes
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_suministros_sectores
        FOREIGN KEY (sector_id) REFERENCES sectores(id)
);

CREATE TABLE tarifas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    consumo_desde NUMERIC(10,3) NOT NULL,
    consumo_hasta NUMERIC(10,3),
    precio_m3 NUMERIC(10,2) NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE lecturas (
    id SERIAL PRIMARY KEY,
    suministro_id INT NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    lectura_anterior NUMERIC(10,3) NOT NULL,
    lectura_actual NUMERIC(10,3) NOT NULL,
    consumo_m3 NUMERIC(10,3) NOT NULL,
    fecha_lectura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion VARCHAR(255),
    CONSTRAINT fk_lecturas_suministros
        FOREIGN KEY (suministro_id) REFERENCES suministros(id),
    CONSTRAINT uk_lectura_suministro_periodo
        UNIQUE (suministro_id, anio, mes)
);

CREATE TABLE recibos (
    id SERIAL PRIMARY KEY,
    lectura_id INT NOT NULL UNIQUE,
    suministro_id INT NOT NULL,
    codigo_recibo VARCHAR(40) NOT NULL UNIQUE,
    anio INT NOT NULL,
    mes INT NOT NULL,
    consumo_m3 NUMERIC(10,3) NOT NULL,
    subtotal_agua NUMERIC(10,2) NOT NULL,
    cargo_mantenimiento NUMERIC(10,2) NOT NULL DEFAULT 0,
    cargo_lector NUMERIC(10,2) NOT NULL DEFAULT 0,
    mora NUMERIC(10,2) NOT NULL DEFAULT 0,
    total NUMERIC(10,2) NOT NULL,
    estado_recibo VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATE,
    CONSTRAINT fk_recibos_lecturas
        FOREIGN KEY (lectura_id) REFERENCES lecturas(id),
    CONSTRAINT fk_recibos_suministros
        FOREIGN KEY (suministro_id) REFERENCES suministros(id)
);

CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    recibo_id INT NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    codigo_operacion VARCHAR(80),
    monto NUMERIC(10,2) NOT NULL,
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'PAGADO',
    fecha_pago TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pagos_recibos
        FOREIGN KEY (recibo_id) REFERENCES recibos(id)
);

INSERT INTO roles (nombre) VALUES
('ADMIN'),
('CLIENTE');

INSERT INTO sectores (nombre, descripcion) VALUES
('Sector 1', 'Zona principal de Huacariz'),
('Sector 2', 'Zona secundaria de Huacariz');

INSERT INTO tarifas (nombre, consumo_desde, consumo_hasta, precio_m3) VALUES
('Tramo básico', 0, 12, 3.00),
('Tramo intermedio', 12.001, 24, 5.00),
('Tramo alto', 24.001, NULL, 8.00);