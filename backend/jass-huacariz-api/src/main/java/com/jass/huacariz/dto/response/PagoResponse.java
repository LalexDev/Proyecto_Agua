package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class PagoResponse {

    private Integer id;
    private Integer idRecibo;
    private String codigoRecibo;
    private String metodoPago;
    private String codigoOperacion;
    private BigDecimal monto;
    private String estadoPago;
    private LocalDateTime fechaPago;
    private String comprobanteUrl;
}