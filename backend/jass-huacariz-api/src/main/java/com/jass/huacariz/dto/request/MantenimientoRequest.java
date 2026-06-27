package com.jass.huacariz.dto.request;

import lombok.Data;

@Data
public class MantenimientoRequest {

    private String codigoSuministro;
    private Integer anio;
    private Integer mes;
    private String observacion;

    private String idOperacionCliente;
}