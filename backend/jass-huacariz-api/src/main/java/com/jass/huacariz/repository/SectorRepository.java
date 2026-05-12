package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Sector;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SectorRepository extends JpaRepository<Sector, Integer> {

    boolean existsByNombre(String nombre);
}