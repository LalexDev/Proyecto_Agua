package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class LecturaRequest {

    @NotBlank(message = "El código de suministro es obligatorio")
    private String codigoSuministro;

    @NotNull(message = "El año es obligatorio")
    @Min(value = 2024, message = "El año no es válido")
    private Integer anio;

    @NotNull(message = "El mes es obligatorio")
    @Min(value = 1, message = "El mes debe ser entre 1 y 12")
    @Max(value = 12, message = "El mes debe ser entre 1 y 12")
    private Integer mes;

    @NotNull(message = "La lectura actual es obligatoria")
    @DecimalMin(value = "0.000", message = "La lectura actual no puede ser negativa")
    private BigDecimal lecturaActual;

    private String observacion;

    private String idOperacionCliente;
}