package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SectorResponse {

    private Integer id;
    private String nombre;
    private String descripcion;
    private Boolean estado;
}