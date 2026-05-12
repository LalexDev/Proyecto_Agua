package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "recibos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Recibo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lectura_id", nullable = false, unique = true)
    private Lectura lectura;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suministro_id", nullable = false)
    private Suministro suministro;

    @Column(name = "codigo_recibo", nullable = false, unique = true, length = 40)
    private String codigoRecibo;

    @Column(name = "anio", nullable = false)
    private Integer anio;

    @Column(name = "mes", nullable = false)
    private Integer mes;

    @Column(name = "consumo_m3", nullable = false, precision = 10, scale = 3)
    private BigDecimal consumoM3;

    @Column(name = "subtotal_agua", nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotalAgua;

    @Column(name = "cargo_mantenimiento", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoMantenimiento;

    @Column(name = "cargo_lector", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoLector;

    @Column(name = "mora", nullable = false, precision = 10, scale = 2)
    private BigDecimal mora;

    @Column(name = "total", nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Column(name = "estado_recibo", nullable = false, length = 20)
    private String estadoRecibo;

    @Column(name = "fecha_emision", nullable = false)
    private LocalDateTime fechaEmision;

    @Column(name = "fecha_vencimiento")
    private LocalDate fechaVencimiento;
}