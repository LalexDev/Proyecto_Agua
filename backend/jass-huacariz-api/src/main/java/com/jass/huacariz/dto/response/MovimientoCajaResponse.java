package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class MovimientoCajaResponse {

    private Integer id;
    private String tipoMovimiento;
    private String categoria;
    private String descripcion;
    private BigDecimal monto;
    private String responsable;
    private String comprobanteUrl;
    private LocalDateTime fechaMovimiento;
    private String estado;
}