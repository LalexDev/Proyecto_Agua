package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@Data
public class ReciboResponse {

    private Integer id;
    private String codigoRecibo;

    private String codigoSuministro;
    private String direccionSuministro;
    private String aliasSuministro;
    private String sector;

    private String nombreCliente;
    private String dniCliente;
    private String telefonoCliente;

    private Integer anio;
    private Integer mes;

    private BigDecimal consumoM3;
    private Boolean cambioMedidor;
    private BigDecimal lecturaInicialNuevoMedidor;
    private String observacionCambioMedidor;
    private Boolean consumoInusual;
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