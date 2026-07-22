package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class LecturaResponse {

    private Integer id;
    private String codigoSuministro;
    private String direccionSuministro;
    private Integer anio;
    private Integer mes;
    private BigDecimal lecturaAnterior;
    private BigDecimal lecturaActual;
    private BigDecimal consumoM3;
    private LocalDateTime fechaLectura;
    private String observacion;

    private Boolean cambioMedidor;
    private BigDecimal lecturaInicialNuevoMedidor;
    private String observacionCambioMedidor;
    private Boolean consumoInusual;

    private String idOperacionCliente;
    private ReciboResponse recibo;
}