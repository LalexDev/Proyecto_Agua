package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.TarifaRequest;
import com.jass.huacariz.dto.response.TarifaResponse;
import com.jass.huacariz.service.TarifaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tarifas")
@RequiredArgsConstructor
public class TarifaController {

    private final TarifaService tarifaService;

    @GetMapping
    public ResponseEntity<List<TarifaResponse>> listarTarifas() {
        return ResponseEntity.ok(tarifaService.listarTarifas());
    }

    @GetMapping("/activas")
    public ResponseEntity<List<TarifaResponse>> listarTarifasActivas() {
        return ResponseEntity.ok(tarifaService.listarTarifasActivas());
    }

    @PostMapping
    public ResponseEntity<TarifaResponse> registrarTarifa(@Valid @RequestBody TarifaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(tarifaService.registrarTarifa(request));
    }
}