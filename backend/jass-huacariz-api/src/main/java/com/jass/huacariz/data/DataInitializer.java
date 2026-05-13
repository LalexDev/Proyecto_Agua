package com.jass.huacariz.data;

import com.jass.huacariz.entity.Role;
import com.jass.huacariz.entity.Usuario;
import com.jass.huacariz.repository.RoleRepository;
import com.jass.huacariz.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private final RoleRepository roleRepository;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    @Bean
    public CommandLineRunner inicializarDatos() {
        return args -> {
            Role adminRole = obtenerOCrearRol("ADMIN");
            obtenerOCrearRol("CLIENTE");
            Role lecturadorRole = obtenerOCrearRol("LECTURADOR");

            crearUsuarioSiNoExiste("ADMIN001", "admin123", adminRole);
            crearUsuarioSiNoExiste("LECTOR001", "lector123", lecturadorRole);
        };
    }

    private Role obtenerOCrearRol(String nombre) {
        return roleRepository.findByNombre(nombre)
                .orElseGet(() -> roleRepository.save(
                        Role.builder()
                                .nombre(nombre)
                                .build()
                ));
    }

    private void crearUsuarioSiNoExiste(String codigoUsuario, String password, Role role) {
        if (!usuarioRepository.existsByCodigoUsuario(codigoUsuario)) {
            Usuario usuario = Usuario.builder()
                    .codigoUsuario(codigoUsuario)
                    .passwordHash(passwordEncoder.encode(password))
                    .rol(role)
                    .estado(true)
                    .fechaCreacion(LocalDateTime.now())
                    .build();

            usuarioRepository.save(usuario);
        }
    }
}