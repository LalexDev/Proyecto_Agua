package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.service.HistorialLecturaService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HistorialLecturaController {

    private final HistorialLecturaService historialLecturaService;

    @GetMapping({
            "/lecturas/historial",
            "/admin/lecturas/historial"
    })
    public List<HistorialLecturaResponse> listarHistorial() {
        return historialLecturaService.listarHistorial();
    }
}
