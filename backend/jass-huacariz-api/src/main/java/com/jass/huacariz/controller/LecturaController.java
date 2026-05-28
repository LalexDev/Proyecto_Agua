package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.LecturaRequest;
import com.jass.huacariz.dto.request.MantenimientoRequest;
import com.jass.huacariz.dto.response.LecturaResponse;
import com.jass.huacariz.service.LecturaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/lecturas")
@RequiredArgsConstructor
public class LecturaController {

    private final LecturaService lecturaService;

    @PostMapping
    public ResponseEntity<LecturaResponse> registrarLectura(
            @Valid @RequestBody LecturaRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(lecturaService.registrarLectura(request));
    }

    @PostMapping("/mantenimiento")
    public ResponseEntity<LecturaResponse> registrarMantenimiento(
            @RequestBody MantenimientoRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(lecturaService.registrarMantenimiento(request));
    }

    @GetMapping
    public ResponseEntity<List<LecturaResponse>> listarLecturas() {
        return ResponseEntity.ok(lecturaService.listarLecturas());
    }

    @GetMapping("/suministro/{suministroId}")
    public ResponseEntity<List<LecturaResponse>> listarLecturasPorSuministro(
            @PathVariable Integer suministroId
    ) {
        return ResponseEntity.ok(lecturaService.listarLecturasPorSuministro(suministroId));
    }
}