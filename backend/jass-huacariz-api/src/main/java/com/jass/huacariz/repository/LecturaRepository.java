package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Lectura;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LecturaRepository extends JpaRepository<Lectura, Integer> {

    List<Lectura> findBySuministroId(Integer suministroId);

    Optional<Lectura> findBySuministroIdAndAnioAndMes(Integer suministroId, Integer anio, Integer mes);

    boolean existsBySuministroIdAndAnioAndMes(Integer suministroId, Integer anio, Integer mes);
}