package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.PagoRequest;
import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.service.ReciboPdfService;
import com.jass.huacariz.service.ReciboService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recibos")
@RequiredArgsConstructor
public class ReciboController {

    private final ReciboService reciboService;
    private final ReciboPdfService reciboPdfService;

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

    @GetMapping(value = "/{id}/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> descargarPdfAdmin(@PathVariable Integer id) {
        byte[] pdf = reciboPdfService.generarPdfAdmin(id);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline()
                                .filename("recibo-" + id + ".pdf")
                                .build()
                                .toString()
                )
                .body(pdf);
    }

    @PatchMapping("/{id}/pagar")
    public ResponseEntity<PagoResponse> pagarRecibo(
            @PathVariable Integer id,
            @Valid @RequestBody PagoRequest request
    ) {
        return ResponseEntity.ok(reciboService.pagarRecibo(id, request));
    }
}