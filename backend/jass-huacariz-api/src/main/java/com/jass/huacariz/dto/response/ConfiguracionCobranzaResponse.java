package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class ConfiguracionCobranzaResponse {

    private Integer id;
    private BigDecimal cargoLector;
    private BigDecimal cargoMantenimiento;
    private BigDecimal cargoOtros;
    private Integer diasVencimiento;
    private BigDecimal moraBase;
    private LocalDateTime fechaActualizacion;
}