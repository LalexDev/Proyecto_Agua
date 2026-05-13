package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PagoRequest {

    @NotBlank(message = "El método de pago es obligatorio")
    private String metodoPago;

    private String codigoOperacion;
}