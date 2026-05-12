package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class SectorResponse {

    private Integer id;
    private String nombre;
    private String descripcion;
    private Boolean estado;
}