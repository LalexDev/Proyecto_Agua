package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.ClientePerfilResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.service.ClientePortalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cliente")
@RequiredArgsConstructor
public class ClientePortalController {

    private final ClientePortalService clientePortalService;

    @GetMapping("/me")
    public ResponseEntity<ClientePerfilResponse> obtenerMiPerfil() {
        return ResponseEntity.ok(clientePortalService.obtenerMiPerfil());
    }

    @GetMapping("/me/suministros")
    public ResponseEntity<List<SuministroResponse>> listarMisSuministros() {
        return ResponseEntity.ok(clientePortalService.listarMisSuministros());
    }

    @GetMapping("/me/recibos")
    public ResponseEntity<List<ReciboResponse>> listarMisRecibos() {
        return ResponseEntity.ok(clientePortalService.listarMisRecibos());
    }
}