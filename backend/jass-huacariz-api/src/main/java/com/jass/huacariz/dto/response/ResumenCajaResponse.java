package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
public class ResumenCajaResponse {

    private BigDecimal totalEgresos;
    private BigDecimal totalIngresosManuales;
    private Integer movimientosActivos;
}