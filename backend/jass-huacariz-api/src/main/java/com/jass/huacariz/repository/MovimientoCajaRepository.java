package com.jass.huacariz.repository;

import com.jass.huacariz.entity.MovimientoCaja;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.math.BigDecimal;
import java.util.List;

public interface MovimientoCajaRepository extends JpaRepository<MovimientoCaja, Integer> {

    List<MovimientoCaja> findByEstadoOrderByFechaMovimientoDesc(String estado);

    List<MovimientoCaja> findAllByOrderByFechaMovimientoDesc();

    Integer countByEstado(String estado);

    @Query("""
            SELECT COALESCE(SUM(m.monto), 0)
            FROM MovimientoCaja m
            WHERE m.estado = 'ACTIVO'
            AND m.tipoMovimiento = 'EGRESO'
            """)
    BigDecimal totalEgresosActivos();

    @Query("""
            SELECT COALESCE(SUM(m.monto), 0)
            FROM MovimientoCaja m
            WHERE m.estado = 'ACTIVO'
            AND m.tipoMovimiento = 'INGRESO'
            """)
    BigDecimal totalIngresosManualesActivos();
}