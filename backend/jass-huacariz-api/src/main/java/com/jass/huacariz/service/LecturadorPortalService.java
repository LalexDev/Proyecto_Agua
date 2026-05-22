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
        Suministro suministro = suministroRepository
                .findByCodigoSuministro(codigoSuministro.trim().toUpperCase())
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + codigoSuministro));

        return SuministroLecturadorResponse.builder()
                .id(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .nombreSector(obtenerNombreSector(suministro))
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(suministro.getLecturaInicial())
                .estado(suministro.getEstado())
                .nombreCliente(obtenerNombreCliente(suministro))
                .dniCliente(obtenerDniCliente(suministro))
                .build();
    }

    private String obtenerNombreSector(Suministro suministro) {
        if (suministro == null || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null
                ? suministro.getSector().getNombre()
                : "-";
    }

    private String obtenerNombreCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "No disponible";
        }

        String nombres = suministro.getCliente().getNombres() != null
                ? suministro.getCliente().getNombres()
                : "";

        String apellidos = suministro.getCliente().getApellidos() != null
                ? suministro.getCliente().getApellidos()
                : "";

        String nombreCompleto = (nombres + " " + apellidos).trim();

        return nombreCompleto.isEmpty() ? "No disponible" : nombreCompleto;
    }

    private String obtenerDniCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null
                ? suministro.getCliente().getDni()
                : "-";
    }
}