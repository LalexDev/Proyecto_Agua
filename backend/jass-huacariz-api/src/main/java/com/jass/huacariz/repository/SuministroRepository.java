package com.jass.huacariz.repository;

import com.jass.huacariz.entity.Suministro;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SuministroRepository extends JpaRepository<Suministro, Integer> {

    Optional<Suministro> findByCodigoSuministro(String codigoSuministro);

    List<Suministro> findByClienteId(Integer clienteId);

    boolean existsByCodigoSuministro(String codigoSuministro);

    @EntityGraph(attributePaths = {"cliente", "sector"})
    @Query("SELECT s FROM Suministro s WHERE s.cliente.id IN :clienteIds ORDER BY s.cliente.id ASC, s.id ASC")
    List<Suministro> findByClienteIdInWithSector(@Param("clienteIds") List<Integer> clienteIds);

    @Query("""
            SELECT s
            FROM Suministro s
            JOIN FETCH s.cliente c
            JOIN FETCH s.sector sec
            WHERE s.estado = true
              AND NOT EXISTS (
                  SELECT 1
                  FROM Lectura l
                  WHERE l.suministro.id = s.id
                    AND l.anio = :anio
                    AND l.mes = :mes
              )
              AND (
                  :buscar IS NULL OR :buscar = '' OR
                  LOWER(s.codigoSuministro) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(s.aliasSuministro, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(s.direccionSuministro, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(COALESCE(s.referencia, '')) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(c.dni) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(CONCAT(COALESCE(c.nombres, ''), ' ', COALESCE(c.apellidos, ''))) LIKE LOWER(CONCAT('%', :buscar, '%')) OR
                  LOWER(sec.nombre) LIKE LOWER(CONCAT('%', :buscar, '%'))
              )
            ORDER BY sec.nombre ASC, c.apellidos ASC, c.nombres ASC, s.codigoSuministro ASC
            """)
    List<Suministro> buscarPendientesLectura(
            @Param("anio") Integer anio,
            @Param("mes") Integer mes,
            @Param("buscar") String buscar,
            Pageable pageable
    );
}
