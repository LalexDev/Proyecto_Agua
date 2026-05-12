package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Suministro;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SuministroRepository extends JpaRepository<Suministro, Integer> {

    Optional<Suministro> findByCodigoSuministro(String codigoSuministro);

    List<Suministro> findByClienteId(Integer clienteId);

    boolean existsByCodigoSuministro(String codigoSuministro);
}