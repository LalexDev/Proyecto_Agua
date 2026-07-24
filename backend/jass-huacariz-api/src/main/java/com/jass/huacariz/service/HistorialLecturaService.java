package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.repository.AdminLecturaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class HistorialLecturaService {

    private final AdminLecturaRepository adminLecturaRepository;

    public List<HistorialLecturaResponse> listarHistorial() {
        return adminLecturaRepository.listarHistorial();
    }

    public List<HistorialLecturaResponse> listarHistorialOptimizado(
            Integer anio,
            Integer mes,
            String buscar,
            Integer limit
    ) {
        int limite = normalizarLimite(limit);
        return adminLecturaRepository.listarHistorialOptimizado(anio, mes, buscar, limite);
    }

    private int normalizarLimite(Integer limit) {
        if (limit == null || limit <= 0) {
            return 200;
        }

        return Math.max(20, Math.min(limit, 500));
    }
}
