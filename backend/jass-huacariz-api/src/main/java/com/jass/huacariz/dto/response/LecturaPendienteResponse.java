package com.jass.huacariz.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LecturaPendienteResponse {

    private Integer idSuministro;
    private String codigoSuministro;

    private String nombreCliente;
    private String dniCliente;

    private String aliasSuministro;
    private String direccionSuministro;
    private String referencia;
    private String sector;

    private Boolean estado;
    private String estadoInstalacion;

    private Integer anio;
    private Integer mes;

    private BigDecimal lecturaAnterior;
}