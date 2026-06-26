package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.ConfiguracionCobranzaRequest;
import com.jass.huacariz.dto.response.ConfiguracionCobranzaResponse;
import com.jass.huacariz.entity.ConfiguracionCobranza;
import com.jass.huacariz.repository.ConfiguracionCobranzaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class ConfiguracionCobranzaService {

    private static final Integer CONFIGURACION_ID = 1;

    private final ConfiguracionCobranzaRepository repository;

    @Transactional
    public ConfiguracionCobranzaResponse obtenerConfiguracion() {
        ConfiguracionCobranza configuracion = repository
            .findTopByOrderByFechaActualizacionDesc()
            .orElseGet(this::crearConfiguracionInicial);

        return convertirResponse(configuracion);
    }

    @Transactional
    public ConfiguracionCobranzaResponse actualizarConfiguracion(
        ConfiguracionCobranzaRequest request
    ) {
        ConfiguracionCobranza configuracion = repository
            .findTopByOrderByFechaActualizacionDesc()
            .orElseGet(this::crearConfiguracionInicial);

        configuracion.setCargoLector(
            request.getCargoLector()
        );

        configuracion.setCargoMantenimiento(
            request.getCargoMantenimiento()
        );

        configuracion.setCargoOtros(
            request.getCargoOtros()
        );

        configuracion.setDiasVencimiento(
            request.getDiasVencimiento()
        );

        configuracion.setMoraBase(
            request.getMoraBase()
        );

        ConfiguracionCobranza guardada =
            repository.save(configuracion);

        return convertirResponse(guardada);
    }

    private ConfiguracionCobranza crearConfiguracionInicial() {
        ConfiguracionCobranza configuracion =
            ConfiguracionCobranza.builder()
                .id(CONFIGURACION_ID)
                .cargoLector(new BigDecimal("3.00"))
                .cargoMantenimiento(new BigDecimal("3.00"))
                .cargoOtros(new BigDecimal("0.25"))
                .diasVencimiento(15)
                .moraBase(new BigDecimal("2.00"))
                .build();

        return repository.save(configuracion);
    }

    private ConfiguracionCobranzaResponse convertirResponse(
        ConfiguracionCobranza configuracion
    ) {
        return ConfiguracionCobranzaResponse.builder()
            .id(configuracion.getId())
            .cargoLector(configuracion.getCargoLector())
            .cargoMantenimiento(
                configuracion.getCargoMantenimiento()
            )
            .cargoOtros(configuracion.getCargoOtros())
            .diasVencimiento(
                configuracion.getDiasVencimiento()
            )
            .moraBase(configuracion.getMoraBase())
            .fechaActualizacion(
                configuracion.getFechaActualizacion()
            )
            .build();
    }
}