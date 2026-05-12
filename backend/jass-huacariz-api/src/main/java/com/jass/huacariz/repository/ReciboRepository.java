package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Recibo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReciboRepository extends JpaRepository<Recibo, Integer> {

    Optional<Recibo> findByCodigoRecibo(String codigoRecibo);

    List<Recibo> findBySuministroId(Integer suministroId);

    List<Recibo> findByEstadoRecibo(String estadoRecibo);
}