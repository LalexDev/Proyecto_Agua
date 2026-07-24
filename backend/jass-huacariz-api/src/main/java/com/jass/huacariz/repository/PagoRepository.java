package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Pago;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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

    @Query("""
            SELECT p
            FROM Pago p
            JOIN FETCH p.recibo r
            JOIN FETCH r.suministro s
            JOIN FETCH s.cliente c
            WHERE (:anio IS NULL OR r.anio = :anio)
              AND (:mes IS NULL OR r.mes = :mes)
              AND (:estado IS NULL OR :estado = '' OR UPPER(p.estadoPago) = UPPER(:estado))
              AND (
                  :buscar IS NULL OR :buscar = '' OR
                  LOWER(r.codigoRecibo) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(s.codigoSuministro) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(p.metodoPago, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(p.codigoOperacion, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(p.estadoPago, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(c.dni) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(CONCAT(COALESCE(c.nombres, ''), ' ', COALESCE(c.apellidos, ''))) LIKE LOWER(CONCAT('%', :buscar, '%'))
              )
            ORDER BY p.fechaPago DESC, p.id DESC
            """)
    List<Pago> buscarPagosOptimizado(
            @Param("anio") Integer anio,
            @Param("mes") Integer mes,
            @Param("estado") String estado,
            @Param("buscar") String buscar,
            Pageable pageable
    );
}
