package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Recibo;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ReciboRepository extends JpaRepository<Recibo, Integer> {

    Optional<Recibo> findByCodigoRecibo(String codigoRecibo);

    List<Recibo> findBySuministroId(Integer suministroId);

    List<Recibo> findByEstadoRecibo(String estadoRecibo);

    List<Recibo> findByEstadoReciboAndFechaVencimientoBefore(String estadoRecibo, LocalDate fechaVencimiento);

    Optional<Recibo> findByLecturaId(Integer lecturaId);

    @Query("""
            SELECT r
            FROM Recibo r
            JOIN FETCH r.suministro s
            JOIN FETCH s.cliente c
            JOIN FETCH s.sector sec
            LEFT JOIN FETCH r.lectura l
            WHERE (:anio IS NULL OR r.anio = :anio)
              AND (:mes IS NULL OR r.mes = :mes)
              AND (:estado IS NULL OR :estado = '' OR UPPER(r.estadoRecibo) = UPPER(:estado))
              AND (
                  :buscar IS NULL OR :buscar = '' OR
                  LOWER(r.codigoRecibo) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(s.codigoSuministro) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(s.aliasSuministro, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(s.direccionSuministro, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(c.dni) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(CONCAT(COALESCE(c.nombres, ''), ' ', COALESCE(c.apellidos, ''))) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(sec.nombre) LIKE LOWER(CONCAT('%', :buscar, '%'))
              )
            ORDER BY r.anio DESC, r.mes DESC, r.id DESC
            """)
    List<Recibo> buscarRecibosOptimizado(
            @Param("anio") Integer anio,
            @Param("mes") Integer mes,
            @Param("estado") String estado,
            @Param("buscar") String buscar,
            Pageable pageable
    );
}
