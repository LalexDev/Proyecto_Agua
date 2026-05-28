package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class ConfiguracionCobranzaRequest {

    @NotNull(message = "El cargo del lector es obligatorio")
    @DecimalMin(value = "0.00", message = "El cargo del lector no puede ser negativo")
    private BigDecimal cargoLector;

    @NotNull(message = "El cargo de mantenimiento es obligatorio")
    @DecimalMin(value = "0.00", message = "El cargo de mantenimiento no puede ser negativo")
    private BigDecimal cargoMantenimiento;

    @NotNull(message = "Otros cargos es obligatorio")
    @DecimalMin(value = "0.00", message = "Otros cargos no puede ser negativo")
    private BigDecimal cargoOtros;

    @NotNull(message = "Los días de vencimiento son obligatorios")
    @Min(value = 1, message = "Los días de vencimiento deben ser mayor a cero")
    private Integer diasVencimiento;

    @NotNull(message = "La mora base es obligatoria")
    @DecimalMin(value = "0.00", message = "La mora base no puede ser negativa")
    private BigDecimal moraBase;
}