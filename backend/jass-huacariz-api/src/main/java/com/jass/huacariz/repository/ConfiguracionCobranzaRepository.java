package com.jass.huacariz.repository;

import com.jass.huacariz.entity.ConfiguracionCobranza;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ConfiguracionCobranzaRepository
        extends JpaRepository<ConfiguracionCobranza, Integer> {

    Optional<ConfiguracionCobranza> findTopByOrderByIdDesc();

    Optional<ConfiguracionCobranza>
    findTopByOrderByFechaActualizacionDesc();
}