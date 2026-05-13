package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.PagoRequest;
import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.service.ReciboService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recibos")
@RequiredArgsConstructor
public class ReciboController {

    private final ReciboService reciboService;

    @GetMapping
    public ResponseEntity<List<ReciboResponse>> listarRecibos() {
        return ResponseEntity.ok(reciboService.listarRecibos());
    }

    @GetMapping("/pendientes")
    public ResponseEntity<List<ReciboResponse>> listarRecibosPendientes() {
        return ResponseEntity.ok(reciboService.listarRecibosPendientes());
    }

    @GetMapping("/codigo/{codigoRecibo}")
    public ResponseEntity<ReciboResponse> obtenerPorCodigoRecibo(@PathVariable String codigoRecibo) {
        return ResponseEntity.ok(reciboService.obtenerPorCodigoRecibo(codigoRecibo));
    }

    @GetMapping("/suministro/{codigoSuministro}")
    public ResponseEntity<List<ReciboResponse>> listarPorSuministro(@PathVariable String codigoSuministro) {
        return ResponseEntity.ok(reciboService.listarRecibosPorSuministro(codigoSuministro));
    }

    @PatchMapping("/{id}/pagar")
    public ResponseEntity<PagoResponse> pagarRecibo(
            @PathVariable Integer id,
            @Valid @RequestBody PagoRequest request
    ) {
        return ResponseEntity.ok(reciboService.pagarRecibo(id, request));
    }
}