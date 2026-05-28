package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class ReciboResponse {

    private Integer id;
    private String codigoRecibo;

    private String codigoSuministro;
    private String direccionSuministro;
    private String aliasSuministro;
    private String sector;

    private String nombreCliente;
    private String dniCliente;

    private Integer anio;
    private Integer mes;

    private BigDecimal consumoM3;
    private BigDecimal subtotalAgua;
    private BigDecimal cargoMantenimiento;
    private BigDecimal cargoLector;
    private BigDecimal cargoOtros;
    private BigDecimal mora;
    private BigDecimal total;

    private String estadoRecibo;
    private LocalDateTime fechaEmision;
    private LocalDate fechaVencimiento;

    private String codigoBarras;
}