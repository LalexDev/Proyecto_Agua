package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.LecturadorRequest;
import com.jass.huacariz.dto.response.LecturadorResponse;
import com.jass.huacariz.service.UsuarioAdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioAdminService usuarioAdminService;

    @GetMapping("/lecturadores")
    public ResponseEntity<?> listarLecturadores() {
        return ResponseEntity.ok(usuarioAdminService.listarLecturadores());
    }

    @GetMapping("/lecturadores/{id}")
    public ResponseEntity<LecturadorResponse> obtenerLecturador(@PathVariable Integer id) {
        return ResponseEntity.ok(usuarioAdminService.obtenerLecturadorPorId(id));
    }

    @PostMapping("/lecturadores")
    public ResponseEntity<LecturadorResponse> registrarLecturador(
            @RequestBody LecturadorRequest request
    ) {
        LecturadorResponse response = usuarioAdminService.registrarLecturador(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/lecturadores/{id}")
    public ResponseEntity<LecturadorResponse> actualizarLecturador(
            @PathVariable Integer id,
            @RequestBody LecturadorRequest request
    ) {
        return ResponseEntity.ok(usuarioAdminService.actualizarLecturador(id, request));
    }

    @PatchMapping("/lecturadores/{id}/estado")
    public ResponseEntity<LecturadorResponse> cambiarEstadoLecturador(
            @PathVariable Integer id,
            @RequestParam Boolean estado
    ) {
        return ResponseEntity.ok(usuarioAdminService.cambiarEstadoLecturador(id, estado));
    }

    @DeleteMapping("/lecturadores/{id}")
    public ResponseEntity<Void> eliminarLecturador(@PathVariable Integer id) {
        usuarioAdminService.eliminarLecturador(id);
        return ResponseEntity.noContent().build();
    }
}