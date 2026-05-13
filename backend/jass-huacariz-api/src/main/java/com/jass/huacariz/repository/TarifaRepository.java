package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Tarifa;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TarifaRepository extends JpaRepository<Tarifa, Integer> {

    List<Tarifa> findByEstadoTrue();

    List<Tarifa> findByEstadoTrueOrderByConsumoDesdeAsc();
}