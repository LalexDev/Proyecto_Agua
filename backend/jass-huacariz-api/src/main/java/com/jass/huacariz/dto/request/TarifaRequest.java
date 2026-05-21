package com.jass.huacariz.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TarifaRequest {

    @NotBlank(message = "El nombre de la tarifa es obligatorio")
    @JsonAlias({"nombreTarifa"})
    private String nombre;

    @NotNull(message = "El consumo desde es obligatorio")
    @DecimalMin(value = "0.0", inclusive = true, message = "El consumo desde no puede ser negativo")
    private BigDecimal consumoDesde;

    private BigDecimal consumoHasta;

    @NotNull(message = "El precio por m3 es obligatorio")
    @DecimalMin(value = "0.01", inclusive = true, message = "El precio por m3 debe ser mayor a cero")
    private BigDecimal precioM3;

    private Boolean estado;
}