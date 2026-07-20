package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.service.PagoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pagos")
@RequiredArgsConstructor
public class PagoController {

    private final PagoService pagoService;

    @GetMapping
    public ResponseEntity<List<PagoResponse>> listarPagos(
            @RequestParam(value = "estado", required = false) String estado
    ) {
        return ResponseEntity.ok(pagoService.listarPagos(estado));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PagoResponse> obtenerPagoPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(pagoService.obtenerPagoPorId(id));
    }

    @GetMapping("/recibo/{reciboId}")
    public ResponseEntity<PagoResponse> obtenerPagoPorRecibo(@PathVariable Integer reciboId) {
        return ResponseEntity.ok(pagoService.obtenerPagoPorRecibo(reciboId));
    }

    @GetMapping("/suministro/{codigoSuministro}")
    public ResponseEntity<List<PagoResponse>> listarPagosPorSuministro(@PathVariable String codigoSuministro) {
        return ResponseEntity.ok(pagoService.listarPagosPorSuministro(codigoSuministro));
    }

    @GetMapping("/revision")
    public ResponseEntity<List<PagoResponse>> listarPagosEnRevision() {
        return ResponseEntity.ok(pagoService.listarPagosEnRevision());
    }

    @PatchMapping("/{id}/aprobar")
    public ResponseEntity<PagoResponse> aprobarPago(@PathVariable Integer id) {
        return ResponseEntity.ok(pagoService.aprobarPago(id));
    }

    @PatchMapping("/{id}/rechazar")
    public ResponseEntity<PagoResponse> rechazarPago(@PathVariable Integer id) {
        return ResponseEntity.ok(pagoService.rechazarPago(id));
    }
}