package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.ConfiguracionCobranzaRequest;
import com.jass.huacariz.dto.response.ConfiguracionCobranzaResponse;
import com.jass.huacariz.service.ConfiguracionCobranzaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/configuracion-cobranza")
@RequiredArgsConstructor
public class ConfiguracionCobranzaController {

    private final ConfiguracionCobranzaService service;

    @GetMapping
    public ResponseEntity<ConfiguracionCobranzaResponse>
    obtenerConfiguracion() {
        return ResponseEntity.ok(
            service.obtenerConfiguracion()
        );
    }

    @PutMapping
    public ResponseEntity<ConfiguracionCobranzaResponse>
    actualizarConfiguracion(
        @Valid
        @RequestBody
        ConfiguracionCobranzaRequest request
    ) {
        return ResponseEntity.ok(
            service.actualizarConfiguracion(request)
        );
    }
}