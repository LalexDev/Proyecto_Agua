package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {

    Optional<Usuario> findByCodigoUsuario(String codigoUsuario);

    boolean existsByCodigoUsuario(String codigoUsuario);
}