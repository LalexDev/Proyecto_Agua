package com.jass.huacariz.repository;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.entity.Lectura;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface AdminLecturaRepository extends JpaRepository<Lectura, Integer> {

    @Query("""
        SELECT new com.jass.huacariz.dto.response.HistorialLecturaResponse(
            l.id,
            s.codigoSuministro,
            s.aliasSuministro,
            s.direccionSuministro,
            CONCAT(c.nombres, ' ', c.apellidos),
            c.dni,
            sec.nombre,
            l.anio,
            l.mes,
            l.lecturaAnterior,
            l.lecturaActual,
            l.consumoM3,
            r.codigoRecibo,
            r.total,
            r.estadoRecibo,
            l.fechaLectura
        )
        FROM Lectura l
        JOIN l.suministro s
        JOIN s.cliente c
        JOIN s.sector sec
        LEFT JOIN Recibo r ON r.lectura = l
        ORDER BY l.fechaLectura DESC
    """)
    List<HistorialLecturaResponse> listarHistorial();
}