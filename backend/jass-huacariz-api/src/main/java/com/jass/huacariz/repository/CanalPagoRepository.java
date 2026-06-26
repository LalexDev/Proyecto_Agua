package com.jass.huacariz.repository;

import com.jass.huacariz.entity.CanalPago;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CanalPagoRepository extends JpaRepository<CanalPago, Integer> {

    List<CanalPago> findByEstadoTrue();

    Optional<CanalPago> findByMetodoPagoIgnoreCase(String metodoPago);

}