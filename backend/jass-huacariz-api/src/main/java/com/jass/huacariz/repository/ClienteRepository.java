package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ClienteRepository extends JpaRepository<Cliente, Integer> {

    Optional<Cliente> findByDni(String dni);

    Optional<Cliente> findByUsuarioCodigoUsuario(String codigoUsuario);

    boolean existsByDni(String dni);
}