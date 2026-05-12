package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.TarifaRequest;
import com.jass.huacariz.dto.response.TarifaResponse;
import com.jass.huacariz.entity.Tarifa;
import com.jass.huacariz.repository.TarifaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TarifaService {

    private final TarifaRepository tarifaRepository;

    @Transactional(readOnly = true)
    public List<TarifaResponse> listarTarifas() {
        return tarifaRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TarifaResponse> listarTarifasActivas() {
        return tarifaRepository.findByEstadoTrue()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional
    public TarifaResponse registrarTarifa(TarifaRequest request) {
        Tarifa tarifa = Tarifa.builder()
                .nombre(request.getNombre())
                .consumoDesde(request.getConsumoDesde())
                .consumoHasta(request.getConsumoHasta())
                .precioM3(request.getPrecioM3())
                .estado(request.getEstado() != null ? request.getEstado() : true)
                .build();

        tarifa = tarifaRepository.save(tarifa);

        return convertirAResponse(tarifa);
    }

    private TarifaResponse convertirAResponse(Tarifa tarifa) {
        return TarifaResponse.builder()
                .id(tarifa.getId())
                .nombre(tarifa.getNombre())
                .consumoDesde(tarifa.getConsumoDesde())
                .consumoHasta(tarifa.getConsumoHasta())
                .precioM3(tarifa.getPrecioM3())
                .estado(tarifa.getEstado())
                .build();
    }
}