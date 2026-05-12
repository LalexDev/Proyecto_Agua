package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Builder
public class ClienteResponse {

    private Integer id;
    private String dni;
    private String nombres;
    private String apellidos;
    private String telefono;
    private String correo;
    private Boolean estado;
    private String codigoUsuario;
    private String passwordInicial;
    private List<SuministroResponse> suministros;
}