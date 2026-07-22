package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.ClienteRequest;
import com.jass.huacariz.dto.request.SuministroRequest;
import com.jass.huacariz.dto.response.ClienteResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.service.ClienteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/clientes")
@RequiredArgsConstructor
public class ClienteController {

    private final ClienteService clienteService;

    @PostMapping
    public ResponseEntity<ClienteResponse> registrarCliente(@Valid @RequestBody ClienteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(clienteService.registrarCliente(request));
    }

    @GetMapping
    public ResponseEntity<List<ClienteResponse>> listarClientes() {
        return ResponseEntity.ok(clienteService.listarClientes());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClienteResponse> obtenerClientePorId(@PathVariable Integer id) {
        return ResponseEntity.ok(clienteService.obtenerClientePorId(id));
    }

    @GetMapping("/dni/{dni}")
    public ResponseEntity<ClienteResponse> obtenerClientePorDni(@PathVariable String dni) {
        return ResponseEntity.ok(clienteService.obtenerClientePorDni(dni));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ClienteResponse> actualizarCliente(
            @PathVariable Integer id,
            @RequestBody ClienteRequest request
    ) {
        return ResponseEntity.ok(clienteService.actualizarCliente(id, request));
    }

    @GetMapping("/{id}/suministros")
    public ResponseEntity<List<SuministroResponse>> listarSuministrosPorCliente(@PathVariable Integer id) {
        return ResponseEntity.ok(clienteService.listarSuministrosPorCliente(id));
    }

    @PostMapping("/{clienteId}/suministros")
    public ResponseEntity<SuministroResponse> agregarSuministro(
            @PathVariable Integer clienteId,
            @Valid @RequestBody SuministroRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(clienteService.agregarSuministro(clienteId, request));
    }

    @PutMapping("/{clienteId}/suministros/{suministroId}")
    public ResponseEntity<SuministroResponse> actualizarSuministro(
            @PathVariable Integer clienteId,
            @PathVariable Integer suministroId,
            @Valid @RequestBody SuministroRequest request
    ) {
        return ResponseEntity.ok(clienteService.actualizarSuministro(clienteId, suministroId, request));
    }

    @DeleteMapping("/{clienteId}/suministros/{suministroId}")
    public ResponseEntity<Void> eliminarSuministro(
            @PathVariable Integer clienteId,
            @PathVariable Integer suministroId
    ) {
        clienteService.eliminarSuministro(clienteId, suministroId);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<ClienteResponse> cambiarEstadoCliente(
            @PathVariable Integer id,
            @RequestParam Boolean estado
    ) {
        return ResponseEntity.ok(clienteService.cambiarEstadoCliente(id, estado));
    }

    @PatchMapping("/{clienteId}/suministros/{suministroId}/estado")
    public ResponseEntity<SuministroResponse> cambiarEstadoSuministro(
            @PathVariable Integer clienteId,
            @PathVariable Integer suministroId,
            @RequestParam Boolean estado
    ) {
        return ResponseEntity.ok(clienteService.cambiarEstadoSuministro(clienteId, suministroId, estado));
    }

    @PatchMapping("/{clienteId}/suministros/{suministroId}/estado-instalacion")
    public ResponseEntity<SuministroResponse> cambiarEstadoInstalacionSuministro(
            @PathVariable Integer clienteId,
            @PathVariable Integer suministroId,
            @RequestParam String estadoInstalacion
    ) {
        return ResponseEntity.ok(
                clienteService.cambiarEstadoInstalacionSuministro(
                        clienteId,
                        suministroId,
                        estadoInstalacion
                )
        );
    }
    
    @PatchMapping("/{id}/reset-password")
    public ResponseEntity<Map<String, String>> restablecerPasswordCliente(@PathVariable Integer id) {
        String passwordTemporal = clienteService.restablecerPasswordCliente(id);

        return ResponseEntity.ok(
                Map.of(
                        "mensaje", "Contraseña restablecida correctamente. El cliente deberá cambiarla al iniciar sesión.",
                        "passwordTemporal", passwordTemporal
                )
        );
    }
}