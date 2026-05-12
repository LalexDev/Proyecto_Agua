package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "suministros")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Suministro {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cliente_id", nullable = false)
    private Cliente cliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sector_id", nullable = false)
    private Sector sector;

    @Column(name = "codigo_suministro", nullable = false, unique = true, length = 30)
    private String codigoSuministro;

    @Column(name = "direccion_suministro", nullable = false, length = 180)
    private String direccionSuministro;

    @Column(name = "referencia", length = 180)
    private String referencia;

    @Column(name = "alias_suministro", length = 100)
    private String aliasSuministro;

    @Column(name = "lectura_inicial", nullable = false, precision = 10, scale = 3)
    private BigDecimal lecturaInicial;

    @Column(name = "estado", nullable = false)
    private Boolean estado = true;

    @Column(name = "fecha_registro", nullable = false)
    private LocalDateTime fechaRegistro;
}