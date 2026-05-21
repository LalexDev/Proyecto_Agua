package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.TarifaRequest;
import com.jass.huacariz.dto.response.TarifaResponse;
import com.jass.huacariz.service.TarifaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tarifas")
@RequiredArgsConstructor
public class TarifaController {

    private final TarifaService tarifaService;

    @GetMapping
    public ResponseEntity<?> listarTarifas() {
        return ResponseEntity.ok(tarifaService.listarTarifas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TarifaResponse> obtenerTarifaPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(tarifaService.obtenerTarifaPorId(id));
    }

    @PostMapping
    public ResponseEntity<TarifaResponse> registrarTarifa(@Valid @RequestBody TarifaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(tarifaService.registrarTarifa(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TarifaResponse> actualizarTarifa(
            @PathVariable Integer id,
            @Valid @RequestBody TarifaRequest request
    ) {
        return ResponseEntity.ok(tarifaService.actualizarTarifa(id, request));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<TarifaResponse> cambiarEstadoTarifa(
            @PathVariable Integer id,
            @RequestParam Boolean estado
    ) {
        return ResponseEntity.ok(tarifaService.cambiarEstadoTarifa(id, estado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarTarifa(@PathVariable Integer id) {
        tarifaService.eliminarTarifa(id);
        return ResponseEntity.noContent().build();
    }
}