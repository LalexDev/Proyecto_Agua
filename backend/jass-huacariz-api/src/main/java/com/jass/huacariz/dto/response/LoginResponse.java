package com.jass.huacariz.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class LoginResponse {

    private String token;
    private String tipoToken;
    private String codigoUsuario;
    private String rol;
    private Long expiracion;
    private String mensaje;
}