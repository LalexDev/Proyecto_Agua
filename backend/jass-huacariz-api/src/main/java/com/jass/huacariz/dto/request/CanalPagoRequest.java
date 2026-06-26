package com.jass.huacariz.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CanalPagoRequest {

    private String titular;

    private String numero;

    private String banco;

    private String cuenta;

    private String cci;

    private String descripcion;

    private String qrUrl;

    private Boolean estado;

}