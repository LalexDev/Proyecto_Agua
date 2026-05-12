package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "lecturas",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_lectura_suministro_periodo", columnNames = {"suministro_id", "anio", "mes"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Lectura {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suministro_id", nullable = false)
    private Suministro suministro;

    @Column(name = "anio", nullable = false)
    private Integer anio;

    @Column(name = "mes", nullable = false)
    private Integer mes;

    @Column(name = "lectura_anterior", nullable = false, precision = 10, scale = 3)
    private BigDecimal lecturaAnterior;

    @Column(name = "lectura_actual", nullable = false, precision = 10, scale = 3)
    private BigDecimal lecturaActual;

    @Column(name = "consumo_m3", nullable = false, precision = 10, scale = 3)
    private BigDecimal consumoM3;

    @Column(name = "fecha_lectura", nullable = false)
    private LocalDateTime fechaLectura;

    @Column(name = "observacion", length = 255)
    private String observacion;
}