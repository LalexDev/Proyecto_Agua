package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "tarifas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tarifa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "consumo_desde", nullable = false, precision = 10, scale = 3)
    private BigDecimal consumoDesde;

    @Column(name = "consumo_hasta", precision = 10, scale = 3)
    private BigDecimal consumoHasta;

    @Column(name = "precio_m3", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioM3;

    @Column(name = "estado", nullable = false)
    private Boolean estado = true;
}