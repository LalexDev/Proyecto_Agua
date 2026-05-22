package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LecturadorResponse {

    private Integer id;
    private String dni;
    private String nombres;
    private String apellidos;
    private String telefono;
    private String correo;
    private String codigoUsuario;
    private String rol;
    private Boolean estado;
    private String sectorAsignado;
    private String passwordInicial;
}