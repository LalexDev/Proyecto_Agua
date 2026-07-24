package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.LecturaPendienteResponse;
import com.jass.huacariz.entity.Lectura;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.LecturaRepository;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LecturaPendienteService {

    private final SuministroRepository suministroRepository;
    private final LecturaRepository lecturaRepository;

    @Transactional(readOnly = true)
    public List<LecturaPendienteResponse> listarSuministrosSinLectura(Integer anio, Integer mes) {
        return listarSuministrosSinLectura(anio, mes, null, 2000);
    }

    @Transactional(readOnly = true)
    public List<LecturaPendienteResponse> listarSuministrosSinLectura(
            Integer anio,
            Integer mes,
            String buscar,
            Integer limit
    ) {
        validarPeriodo(anio, mes);

        String busquedaNormalizada = buscar == null ? null : buscar.trim();
        int limite = normalizarLimite(limit);

        return suministroRepository.buscarPendientesLectura(
                        anio,
                        mes,
                        busquedaNormalizada,
                        PageRequest.of(0, limite)
                )
                .stream()
                .map(suministro -> convertirAResponse(suministro, anio, mes))
                .toList();
    }


    private int normalizarLimite(Integer limit) {
        if (limit == null || limit <= 0) {
            return 200;
        }

        return Math.max(20, Math.min(limit, 5000));
    }

    private void validarPeriodo(Integer anio, Integer mes) {
        if (anio == null || anio < 2024) {
            throw new RuntimeException("Ingrese un año válido.");
        }

        if (mes == null || mes < 1 || mes > 12) {
            throw new RuntimeException("Ingrese un mes válido entre 1 y 12.");
        }
    }

    private LecturaPendienteResponse convertirAResponse(Suministro suministro, Integer anio, Integer mes) {
        return LecturaPendienteResponse.builder()
                .idSuministro(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .nombreCliente(obtenerNombreCliente(suministro))
                .dniCliente(obtenerDniCliente(suministro))
                .aliasSuministro(suministro.getAliasSuministro())
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .sector(obtenerSector(suministro))
                .estado(suministro.getEstado())
                .estadoInstalacion(obtenerEstadoInstalacion(suministro))
                .anio(anio)
                .mes(mes)
                .lecturaAnterior(obtenerLecturaAnterior(suministro))
                .build();
    }

    private BigDecimal obtenerLecturaAnterior(Suministro suministro) {
        return lecturaRepository.findTopBySuministroIdOrderByAnioDescMesDesc(suministro.getId())
                .map(Lectura::getLecturaActual)
                .orElse(suministro.getLecturaInicial() != null
                        ? suministro.getLecturaInicial()
                        : BigDecimal.ZERO)
                .setScale(3, RoundingMode.HALF_UP);
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

        String completo = (nombres + " " + apellidos).trim();

        return completo.isBlank() ? "No disponible" : completo;
    }

    private String obtenerDniCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null
                ? suministro.getCliente().getDni()
                : "-";
    }

    private String obtenerSector(Suministro suministro) {
        if (suministro == null || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null
                ? suministro.getSector().getNombre()
                : "-";
    }

    private String obtenerEstadoInstalacion(Suministro suministro) {
        if (suministro == null || suministro.getEstadoInstalacion() == null || suministro.getEstadoInstalacion().isBlank()) {
            return "PENDIENTE_INSTALACION";
        }

        return suministro.getEstadoInstalacion();
    }
}