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

    @PostMapping
    public ResponseEntity<SectorResponse> registrarSector(@Valid @RequestBody SectorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sectorService.registrarSector(request));
    }
}