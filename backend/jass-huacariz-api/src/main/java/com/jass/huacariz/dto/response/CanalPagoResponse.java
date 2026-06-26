package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class CanalPagoResponse {

    private Integer id;

    private String metodoPago;

    private String titular;

    private String numero;

    private String banco;

    private String cuenta;

    private String cci;

    private String descripcion;

    private String qrUrl;

    private Boolean estado;

}