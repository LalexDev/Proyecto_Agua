package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.LoginRequest;
import com.jass.huacariz.dto.response.LoginResponse;
import com.jass.huacariz.entity.Usuario;
import com.jass.huacariz.repository.UsuarioRepository;
import com.jass.huacariz.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Usuario usuario = usuarioRepository.findByCodigoUsuario(request.getCodigoUsuario())
                .orElseThrow(() -> new RuntimeException("Usuario o contraseña incorrectos"));

        if (!Boolean.TRUE.equals(usuario.getEstado())) {
            throw new RuntimeException("El usuario se encuentra inactivo");
        }

        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new RuntimeException("Usuario o contraseña incorrectos");
        }

        String token = jwtService.generarToken(usuario);

        return LoginResponse.builder()
                .token(token)
                .tipoToken("Bearer")
                .codigoUsuario(usuario.getCodigoUsuario())
                .rol(usuario.getRol().getNombre())
                .expiracion(jwtService.getExpiration())
                .mensaje("Login exitoso")
                .build();
    }
}