package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Integer> {

    Optional<Role> findByNombre(String nombre);

    boolean existsByNombre(String nombre);
}