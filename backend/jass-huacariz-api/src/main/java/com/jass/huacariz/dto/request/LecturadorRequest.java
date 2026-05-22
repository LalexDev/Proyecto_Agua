package com.jass.huacariz.dto.request;

import lombok.Data;

@Data
public class LecturadorRequest {

    private String dni;
    private String nombres;
    private String apellidos;
    private String telefono;
    private String correo;
    private String codigoUsuario;
    private String password;
    private Boolean estado;
    private String sectorAsignado;
}