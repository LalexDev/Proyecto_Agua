package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.service.HistorialLecturaService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/lecturas")
@RequiredArgsConstructor
public class HistorialLecturaController {

    private final HistorialLecturaService historialLecturaService;

    @GetMapping("/historial")
    public List<HistorialLecturaResponse> listarHistorial() {
        return historialLecturaService.listarHistorial();
    }
}