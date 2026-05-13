package com.jass.huacariz.security;

import com.jass.huacariz.entity.Usuario;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generarToken(Usuario usuario) {
        Date ahora = new Date();
        Date expiracionToken = new Date(ahora.getTime() + expiration);

        return Jwts.builder()
                .subject(usuario.getCodigoUsuario())
                .claim("rol", usuario.getRol().getNombre())
                .issuedAt(ahora)
                .expiration(expiracionToken)
                .signWith(getSigningKey())
                .compact();
    }

    public String obtenerCodigoUsuario(String token) {
        return obtenerClaims(token).getSubject();
    }

    public boolean tokenValido(String token, Usuario usuario) {
        String codigoUsuario = obtenerCodigoUsuario(token);
        return codigoUsuario.equals(usuario.getCodigoUsuario()) && !tokenExpirado(token);
    }

    private boolean tokenExpirado(String token) {
        return obtenerClaims(token).getExpiration().before(new Date());
    }

    private Claims obtenerClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getExpiration() {
        return expiration;
    }
}