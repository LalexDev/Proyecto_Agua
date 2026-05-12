package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SectorRequest {

    @NotBlank(message = "El nombre del sector es obligatorio")
    private String nombre;

    private String descripcion;

    private Boolean estado = true;
}