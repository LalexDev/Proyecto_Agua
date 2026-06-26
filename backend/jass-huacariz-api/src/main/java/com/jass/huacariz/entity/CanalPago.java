package com.jass.huacariz.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "canales_pago")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CanalPago {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "metodo_pago", nullable = false, length = 50)
    private String metodoPago;

    @Column(name = "titular", nullable = false, length = 120)
    private String titular;

    @Column(name = "numero", length = 80)
    private String numero;

    @Column(name = "banco", length = 100)
    private String banco;

    @Column(name = "cuenta", length = 100)
    private String cuenta;

    @Column(name = "cci", length = 120)
    private String cci;

    @Column(name = "descripcion", length = 255)
    private String descripcion;

    @Column(name = "qr_url", length = 255)
    private String qrUrl;

    @Column(name = "estado", nullable = false)
    private Boolean estado;

    @Column(name = "fecha_actualizacion", nullable = false)
    private LocalDateTime fechaActualizacion;
}