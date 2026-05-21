package com.jass.huacariz.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TarifaResponse {

    private Integer id;

    @JsonProperty("nombreTarifa")
    private String nombreTarifa;

    @JsonProperty("nombre")
    private String nombre;

    private BigDecimal consumoDesde;

    private BigDecimal consumoHasta;

    private BigDecimal precioM3;

    private Boolean estado;
}