package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.SuministroLecturadorResponse;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LecturadorPortalService {

    private final SuministroRepository suministroRepository;

    @Transactional(readOnly = true)
    public SuministroLecturadorResponse buscarSuministroPorCodigo(String codigoSuministro) {
        Suministro suministro = suministroRepository.findByCodigoSuministro(codigoSuministro.trim().toUpperCase())
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + codigoSuministro));

        return SuministroLecturadorResponse.builder()
                .id(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .nombreSector(suministro.getSector().getNombre())
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(suministro.getLecturaInicial())
                .estado(suministro.getEstado())
                .build();
    }
}