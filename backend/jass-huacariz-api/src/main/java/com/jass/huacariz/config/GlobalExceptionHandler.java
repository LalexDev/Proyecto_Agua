package com.jass.huacariz.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> manejarValidacion(
            MethodArgumentNotValidException ex
    ) {
        String mensaje = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error -> error.getDefaultMessage() != null
                        ? error.getDefaultMessage()
                        : "Los datos enviados no son válidos.")
                .orElse("Los datos enviados no son válidos.");

        return respuesta(HttpStatus.BAD_REQUEST, mensaje);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> manejarRuntimeException(
            RuntimeException ex
    ) {
        String mensaje = ex.getMessage() == null
                ? "No se pudo completar la operación."
                : ex.getMessage();

        String normalizado = mensaje.toLowerCase();

        if (normalizado.contains("usuario o contraseña")
                || normalizado.contains("usuario se encuentra inactivo")) {
            return respuesta(HttpStatus.UNAUTHORIZED, mensaje);
        }

        if (normalizado.contains("no existe")
                || normalizado.contains("no se encontró")) {
            return respuesta(HttpStatus.NOT_FOUND, mensaje);
        }

        if (normalizado.contains("ya existe")
                || normalizado.contains("duplicad")) {
            return respuesta(HttpStatus.CONFLICT, mensaje);
        }

        return respuesta(HttpStatus.BAD_REQUEST, mensaje);
    }

    private ResponseEntity<Map<String, String>> respuesta(
            HttpStatus estado,
            String mensaje
    ) {
        return ResponseEntity
                .status(estado)
                .body(Map.of("error", mensaje));
    }
}
