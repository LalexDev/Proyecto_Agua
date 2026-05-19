package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
public class SuministroLecturadorResponse {

    private Integer id;
    private String codigoSuministro;
    private String nombreSector;
    private String direccionSuministro;
    private String referencia;
    private String aliasSuministro;
    private BigDecimal lecturaInicial;
    private Boolean estado;
}