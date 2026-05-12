package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class TarifaRequest {

    @NotBlank(message = "El nombre de la tarifa es obligatorio")
    private String nombre;

    @NotNull(message = "El consumo desde es obligatorio")
    @DecimalMin(value = "0.000", message = "El consumo desde no puede ser negativo")
    private BigDecimal consumoDesde;

    private BigDecimal consumoHasta;

    @NotNull(message = "El precio por m3 es obligatorio")
    @DecimalMin(value = "0.00", message = "El precio por m3 no puede ser negativo")
    private BigDecimal precioM3;

    private Boolean estado = true;
}