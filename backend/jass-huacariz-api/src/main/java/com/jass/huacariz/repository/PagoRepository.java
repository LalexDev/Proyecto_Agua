package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Pago;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Query;
import java.math.BigDecimal;

public interface PagoRepository extends JpaRepository<Pago, Integer> {

    List<Pago> findByEstadoPago(String estadoPago);

    Optional<Pago> findByReciboId(Integer reciboId);

    List<Pago> findByReciboSuministroCodigoSuministro(String codigoSuministro);

    List<Pago> findByEstadoPagoOrderByFechaPagoDesc(String estadoPago);

    List<Pago> findByEstadoPagoInOrderByFechaPagoDesc(List<String> estados);

    List<Pago> findByEstadoPagoAndFechaEstadoPagoBefore(
            String estadoPago,
            LocalDateTime fechaLimite
    );

    boolean existsByCodigoOperacionIgnoreCaseAndEstadoPagoIn(
            String codigoOperacion,
            List<String> estados
    );
    @Query("""
            SELECT COALESCE(SUM(p.monto), 0)
            FROM Pago p
            WHERE UPPER(p.estadoPago) IN ('PAGADO', 'PAGADO_CONFIRMADO', 'CONFIRMADO')
            """)
    BigDecimal totalPagosConfirmados();
}