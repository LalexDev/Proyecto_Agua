package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
public class TarifaResponse {

    private Integer id;
    private String nombre;
    private BigDecimal consumoDesde;
    private BigDecimal consumoHasta;
    private BigDecimal precioM3;
    private Boolean estado;
}