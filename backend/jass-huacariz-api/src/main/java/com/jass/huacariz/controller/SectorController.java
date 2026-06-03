package com.jass.huacariz.controller;

import com.jass.huacariz.dto.request.SectorRequest;
import com.jass.huacariz.dto.response.SectorResponse;
import com.jass.huacariz.service.SectorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sectores")
@RequiredArgsConstructor
public class SectorController {

    private final SectorService sectorService;

    @GetMapping
    public ResponseEntity<List<SectorResponse>> listarSectores() {
        return ResponseEntity.ok(sectorService.listarSectores());
    }

    @GetMapping("/activos")
    public ResponseEntity<List<SectorResponse>> listarSectoresActivos() {
        return ResponseEntity.ok(sectorService.listarSectoresActivos());
    }

    @PostMapping
    public ResponseEntity<SectorResponse> registrarSector(
            @Valid @RequestBody SectorRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(sectorService.registrarSector(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SectorResponse> actualizarSector(
            @PathVariable Integer id,
            @Valid @RequestBody SectorRequest request
    ) {
        return ResponseEntity.ok(sectorService.actualizarSector(id, request));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<SectorResponse> cambiarEstado(
            @PathVariable Integer id,
            @RequestParam Boolean estado
    ) {
        return ResponseEntity.ok(sectorService.cambiarEstado(id, estado));
    }
}