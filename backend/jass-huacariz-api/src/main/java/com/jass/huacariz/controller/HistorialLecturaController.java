package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.service.HistorialLecturaService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
    public List<HistorialLecturaResponse> listarHistorial(
            @RequestParam(value = "anio", required = false) Integer anio,
            @RequestParam(value = "mes", required = false) Integer mes,
            @RequestParam(value = "buscar", required = false) String buscar,
            @RequestParam(value = "limit", required = false) Integer limit
    ) {
        boolean modoOptimizado = anio != null
                || mes != null
                || buscar != null
                || limit != null;

        if (modoOptimizado) {
            return historialLecturaService.listarHistorialOptimizado(anio, mes, buscar, limit);
        }

        return historialLecturaService.listarHistorial();
    }
}
