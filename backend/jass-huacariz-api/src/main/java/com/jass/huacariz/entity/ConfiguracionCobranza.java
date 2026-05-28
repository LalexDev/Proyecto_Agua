package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "configuracion_cobranza")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConfiguracionCobranza {

    @Id
    private Integer id;

    @Column(name = "cargo_lector", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoLector;

    @Column(name = "cargo_mantenimiento", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoMantenimiento;

    @Column(name = "cargo_otros", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoOtros;

    @Column(name = "dias_vencimiento", nullable = false)
    private Integer diasVencimiento;

    @Column(name = "mora_base", nullable = false, precision = 10, scale = 2)
    private BigDecimal moraBase;

    @Column(name = "fecha_actualizacion", nullable = false)
    private LocalDateTime fechaActualizacion;
}