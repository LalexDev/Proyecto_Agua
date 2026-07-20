package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.MovimientoCajaRequest;
import com.jass.huacariz.dto.response.MovimientoCajaResponse;
import com.jass.huacariz.dto.response.ResumenCajaResponse;
import com.jass.huacariz.service.MovimientoCajaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/movimientos-caja")
@RequiredArgsConstructor
public class MovimientoCajaController {

    private final MovimientoCajaService service;

    @GetMapping
    public ResponseEntity<List<MovimientoCajaResponse>> listar() {
        return ResponseEntity.ok(service.listar());
    }

    @GetMapping("/activos")
    public ResponseEntity<List<MovimientoCajaResponse>> listarActivos() {
        return ResponseEntity.ok(service.listarActivos());
    }

    @GetMapping("/resumen")
    public ResponseEntity<ResumenCajaResponse> resumen() {
        return ResponseEntity.ok(service.resumen());
    }

    @PostMapping
    public ResponseEntity<MovimientoCajaResponse> crear(
            @Valid @RequestBody MovimientoCajaRequest request
    ) {
        return ResponseEntity.ok(service.crear(request));
    }

    @PatchMapping("/{id}/anular")
    public ResponseEntity<MovimientoCajaResponse> anular(
            @PathVariable Integer id
    ) {
        return ResponseEntity.ok(service.anular(id));
    }
}