package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.CambiarPasswordRequest;
import com.jass.huacariz.dto.request.PagoRequest;
import com.jass.huacariz.dto.response.ClientePerfilResponse;
import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.service.ClientePortalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

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

    @PatchMapping("/me/recibos/{id}/pagar")
    public ResponseEntity<PagoResponse> pagarMiRecibo(
            @PathVariable Integer id,
            @RequestBody PagoRequest request
    ) {
        return ResponseEntity.ok(clientePortalService.pagarMiRecibo(id, request));
    }

    @PatchMapping("/me/password")
    public ResponseEntity<Map<String, String>> cambiarMiPassword(
            @RequestBody CambiarPasswordRequest request
    ) {
        String mensaje = clientePortalService.cambiarMiPassword(request);
        return ResponseEntity.ok(Map.of("mensaje", mensaje));
    }
}