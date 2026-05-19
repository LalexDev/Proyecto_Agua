package com.jass.huacariz.controller;

import com.jass.huacariz.dto.response.SuministroLecturadorResponse;
import com.jass.huacariz.service.LecturadorPortalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/lecturador")
@RequiredArgsConstructor
public class LecturadorPortalController {

    private final LecturadorPortalService lecturadorPortalService;

    @GetMapping("/suministros/{codigoSuministro}")
    public ResponseEntity<SuministroLecturadorResponse> buscarSuministro(
            @PathVariable String codigoSuministro
    ) {
        return ResponseEntity.ok(lecturadorPortalService.buscarSuministroPorCodigo(codigoSuministro));
    }
}