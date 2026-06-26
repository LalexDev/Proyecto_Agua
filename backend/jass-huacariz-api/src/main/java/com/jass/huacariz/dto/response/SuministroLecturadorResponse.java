package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
public class SuministroLecturadorResponse {

    private Integer id;
    private String codigoSuministro;

    private String nombreSector;
    private String direccionSuministro;
    private String referencia;
    private String aliasSuministro;

    private BigDecimal lecturaInicial;

    // Última lectura registrada en el servidor.
    private BigDecimal lecturaAnterior;
    private Integer anioUltimaLectura;
    private Integer mesUltimaLectura;

    private Boolean estado;

    private String estadoInstalacion;
    private Boolean permiteRegistrarLectura;
    private Boolean permiteGenerarMantenimiento;
    private String mensajeEstado;

    private String nombreCliente;
    private String dniCliente;
}