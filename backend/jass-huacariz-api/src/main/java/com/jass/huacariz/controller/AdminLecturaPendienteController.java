package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.LecturaPendienteResponse;
import com.jass.huacariz.service.LecturaPendienteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/lecturas")
@RequiredArgsConstructor
public class AdminLecturaPendienteController {

    private final LecturaPendienteService lecturaPendienteService;

    @GetMapping("/pendientes")
    public ResponseEntity<List<LecturaPendienteResponse>> listarSuministrosSinLectura(
            @RequestParam Integer anio,
            @RequestParam Integer mes,
            @RequestParam(value = "buscar", required = false) String buscar,
            @RequestParam(value = "limit", required = false) Integer limit
    ) {
        return ResponseEntity.ok(
                lecturaPendienteService.listarSuministrosSinLectura(anio, mes, buscar, limit)
        );
    }
}