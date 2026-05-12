package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Pago;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PagoRepository extends JpaRepository<Pago, Integer> {

    List<Pago> findByReciboId(Integer reciboId);

    List<Pago> findByEstadoPago(String estadoPago);
}