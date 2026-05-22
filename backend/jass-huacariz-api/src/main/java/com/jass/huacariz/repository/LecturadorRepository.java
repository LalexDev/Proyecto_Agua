package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Lecturador;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LecturadorRepository extends JpaRepository<Lecturador, Integer> {

    Optional<Lecturador> findByDni(String dni);

    boolean existsByDni(String dni);

    boolean existsByDniAndIdNot(String dni, Integer id);

    List<Lecturador> findAllByOrderByNombresAscApellidosAsc();
}