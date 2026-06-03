package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Sector;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SectorRepository extends JpaRepository<Sector, Integer> {

    boolean existsByNombreIgnoreCase(String nombre);

    List<Sector> findByEstadoTrueOrderByNombreAsc();

    List<Sector> findAllByOrderByNombreAsc();
}