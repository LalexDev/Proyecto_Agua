CREATE TABLE prueba_conexion (
    id SERIAL PRIMARY KEY,
    mensaje VARCHAR(100) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO prueba_conexion (mensaje)
VALUES ('Backend AGUA POTABLE HUACARIZ SAN ANTONIO conectado correctamente');