package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.CanalPagoRequest;
import com.jass.huacariz.dto.response.CanalPagoResponse;
import com.jass.huacariz.service.CanalPagoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/canales-pago")
@RequiredArgsConstructor
public class CanalPagoController {

    private final CanalPagoService canalPagoService;

    @GetMapping
    public ResponseEntity<List<CanalPagoResponse>> listar() {
        return ResponseEntity.ok(canalPagoService.listar());
    }

    @GetMapping("/activos")
    public ResponseEntity<List<CanalPagoResponse>> listarActivos() {
        return ResponseEntity.ok(canalPagoService.listarActivos());
    }

    @PutMapping("/{id}")
    public ResponseEntity<CanalPagoResponse> actualizar(
            @PathVariable Integer id,
            @RequestBody CanalPagoRequest request
    ) {
        return ResponseEntity.ok(canalPagoService.actualizar(id, request));
    }
}