package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class ClientePerfilResponse {

    private Integer idCliente;
    private String codigoUsuario;
    private String dni;
    private String nombres;
    private String apellidos;
    private String telefono;
    private String correo;
    private Boolean estado;
}