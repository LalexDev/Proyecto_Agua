package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
public class SuministroResponse {

    private Integer id;
    private String codigoSuministro;
    private Integer idSector;
    private String nombreSector;
    private String direccionSuministro;
    private String referencia;
    private String aliasSuministro;
    private BigDecimal lecturaInicial;
    private Boolean estado;
}