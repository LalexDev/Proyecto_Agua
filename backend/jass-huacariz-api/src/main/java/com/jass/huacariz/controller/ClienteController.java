package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.ClienteRequest;
import com.jass.huacariz.dto.response.ClienteResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.service.ClienteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clientes")
@RequiredArgsConstructor
public class ClienteController {

    private final ClienteService clienteService;

    @PostMapping
    public ResponseEntity<ClienteResponse> registrarCliente(@Valid @RequestBody ClienteRequest request) {
        ClienteResponse response = clienteService.registrarCliente(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
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

    @GetMapping("/{id}/suministros")
    public ResponseEntity<List<SuministroResponse>> listarSuministrosPorCliente(@PathVariable Integer id) {
        return ResponseEntity.ok(clienteService.listarSuministrosPorCliente(id));
    }
}