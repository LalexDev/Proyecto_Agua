package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class SuministroRequest {

    @NotNull(message = "El sector es obligatorio")
    private Integer idSector;

    @NotBlank(message = "La dirección del suministro es obligatoria")
    private String direccionSuministro;

    private String referencia;

    private String aliasSuministro;

    @NotNull(message = "La lectura inicial es obligatoria")
    @DecimalMin(value = "0.000", message = "La lectura inicial no puede ser negativa")
    private BigDecimal lecturaInicial;
}