package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Pago;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PagoRepository extends JpaRepository<Pago, Integer> {

    List<Pago> findByEstadoPago(String estadoPago);

    Optional<Pago> findByReciboId(Integer reciboId);

    List<Pago> findByReciboSuministroCodigoSuministro(String codigoSuministro);
}