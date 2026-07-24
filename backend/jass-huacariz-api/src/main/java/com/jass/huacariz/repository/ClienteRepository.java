package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Cliente;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ClienteRepository extends JpaRepository<Cliente, Integer> {

    Optional<Cliente> findByDni(String dni);

    Optional<Cliente> findByUsuarioCodigoUsuario(String codigoUsuario);

    boolean existsByDni(String dni);

    @EntityGraph(attributePaths = {"usuario"})
    @Query("SELECT c FROM Cliente c ORDER BY c.id DESC")
    List<Cliente> findAllWithUsuario();
}
