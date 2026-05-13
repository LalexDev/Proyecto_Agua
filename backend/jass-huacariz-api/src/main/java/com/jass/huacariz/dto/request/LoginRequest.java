package com.jass.huacariz.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {

    @NotBlank(message = "El código de usuario es obligatorio")
    private String codigoUsuario;

    @NotBlank(message = "La contraseña es obligatoria")
    private String password;
}