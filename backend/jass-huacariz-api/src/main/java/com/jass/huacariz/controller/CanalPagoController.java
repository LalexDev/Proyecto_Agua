package com.jass.huacariz.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jass.huacariz.dto.request.CanalPagoRequest;
import com.jass.huacariz.dto.response.CanalPagoResponse;
import com.jass.huacariz.service.CanalPagoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/canales-pago")
@RequiredArgsConstructor
public class CanalPagoController {

    private final CanalPagoService canalPagoService;
    private final ObjectMapper objectMapper;

    @GetMapping
    public ResponseEntity<List<CanalPagoResponse>> listar() {
        return ResponseEntity.ok(canalPagoService.listar());
    }

    @GetMapping("/activos")
    public ResponseEntity<List<CanalPagoResponse>> listarActivos() {
        return ResponseEntity.ok(canalPagoService.listarActivos());
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CanalPagoResponse> crear(
            @RequestParam("datos") String datos,
            @RequestParam(value = "qr", required = false) MultipartFile qr
    ) throws Exception {

        CanalPagoRequest request =
                objectMapper.readValue(datos, CanalPagoRequest.class);

        return ResponseEntity.ok(
                canalPagoService.crear(request, qr)
        );
    }

    @PutMapping(
            value = "/{id}",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<CanalPagoResponse> actualizar(
            @PathVariable Integer id,
            @RequestParam("datos") String datos,
            @RequestParam(value = "qr", required = false) MultipartFile qr
    ) throws Exception {

        CanalPagoRequest request =
                objectMapper.readValue(datos, CanalPagoRequest.class);

        return ResponseEntity.ok(
                canalPagoService.actualizar(id, request, qr)
        );
    }
}