package com.jass.huacariz.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class HistorialLecturaResponse {

    private Integer idLectura;
    private String codigoSuministro;
    private String aliasSuministro;
    private String direccionSuministro;
    private String cliente;
    private String dniCliente;
    private String sector;
    private Integer anio;
    private Integer mes;
    private BigDecimal lecturaAnterior;
    private BigDecimal lecturaActual;
    private BigDecimal consumoM3;
    private String codigoRecibo;
    private BigDecimal totalRecibo;
    private String estadoRecibo;
    private LocalDateTime fechaRegistro;

    private BigDecimal subtotalAgua;
    private BigDecimal cargoMantenimiento;
    private BigDecimal cargoLector;
    private BigDecimal cargoOtros;
    private BigDecimal mora;
    private BigDecimal total;
    private LocalDateTime fechaEmision;
    private LocalDate fechaVencimiento;
    private String codigoBarras;

    public HistorialLecturaResponse() {
    }

    public HistorialLecturaResponse(
            Integer idLectura,
            String codigoSuministro,
            String aliasSuministro,
            String direccionSuministro,
            String cliente,
            String dniCliente,
            String sector,
            Integer anio,
            Integer mes,
            BigDecimal lecturaAnterior,
            BigDecimal lecturaActual,
            BigDecimal consumoM3,
            String codigoRecibo,
            BigDecimal totalRecibo,
            String estadoRecibo,
            LocalDateTime fechaRegistro,
            BigDecimal subtotalAgua,
            BigDecimal cargoMantenimiento,
            BigDecimal cargoLector,
            BigDecimal cargoOtros,
            BigDecimal mora,
            BigDecimal total,
            LocalDateTime fechaEmision,
            LocalDate fechaVencimiento,
            String codigoBarras
    ) {
        this.idLectura = idLectura;
        this.codigoSuministro = codigoSuministro;
        this.aliasSuministro = aliasSuministro;
        this.direccionSuministro = direccionSuministro;
        this.cliente = cliente;
        this.dniCliente = dniCliente;
        this.sector = sector;
        this.anio = anio;
        this.mes = mes;
        this.lecturaAnterior = lecturaAnterior;
        this.lecturaActual = lecturaActual;
        this.consumoM3 = consumoM3;
        this.codigoRecibo = codigoRecibo;
        this.totalRecibo = totalRecibo;
        this.estadoRecibo = estadoRecibo;
        this.fechaRegistro = fechaRegistro;
        this.subtotalAgua = subtotalAgua;
        this.cargoMantenimiento = cargoMantenimiento;
        this.cargoLector = cargoLector;
        this.cargoOtros = cargoOtros;
        this.mora = mora;
        this.total = total;
        this.fechaEmision = fechaEmision;
        this.fechaVencimiento = fechaVencimiento;
        this.codigoBarras = codigoBarras;
    }

    public Integer getIdLectura() { return idLectura; }
    public void setIdLectura(Integer idLectura) { this.idLectura = idLectura; }

    public String getCodigoSuministro() { return codigoSuministro; }
    public void setCodigoSuministro(String codigoSuministro) { this.codigoSuministro = codigoSuministro; }

    public String getAliasSuministro() { return aliasSuministro; }
    public void setAliasSuministro(String aliasSuministro) { this.aliasSuministro = aliasSuministro; }

    public String getDireccionSuministro() { return direccionSuministro; }
    public void setDireccionSuministro(String direccionSuministro) { this.direccionSuministro = direccionSuministro; }

    public String getCliente() { return cliente; }
    public void setCliente(String cliente) { this.cliente = cliente; }

    public String getDniCliente() { return dniCliente; }
    public void setDniCliente(String dniCliente) { this.dniCliente = dniCliente; }

    public String getSector() { return sector; }
    public void setSector(String sector) { this.sector = sector; }

    public Integer getAnio() { return anio; }
    public void setAnio(Integer anio) { this.anio = anio; }

    public Integer getMes() { return mes; }
    public void setMes(Integer mes) { this.mes = mes; }

    public BigDecimal getLecturaAnterior() { return lecturaAnterior; }
    public void setLecturaAnterior(BigDecimal lecturaAnterior) { this.lecturaAnterior = lecturaAnterior; }

    public BigDecimal getLecturaActual() { return lecturaActual; }
    public void setLecturaActual(BigDecimal lecturaActual) { this.lecturaActual = lecturaActual; }

    public BigDecimal getConsumoM3() { return consumoM3; }
    public void setConsumoM3(BigDecimal consumoM3) { this.consumoM3 = consumoM3; }

    public String getCodigoRecibo() { return codigoRecibo; }
    public void setCodigoRecibo(String codigoRecibo) { this.codigoRecibo = codigoRecibo; }

    public BigDecimal getTotalRecibo() { return totalRecibo; }
    public void setTotalRecibo(BigDecimal totalRecibo) { this.totalRecibo = totalRecibo; }

    public String getEstadoRecibo() { return estadoRecibo; }
    public void setEstadoRecibo(String estadoRecibo) { this.estadoRecibo = estadoRecibo; }

    public LocalDateTime getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(LocalDateTime fechaRegistro) { this.fechaRegistro = fechaRegistro; }

    public BigDecimal getSubtotalAgua() { return subtotalAgua; }
    public void setSubtotalAgua(BigDecimal subtotalAgua) { this.subtotalAgua = subtotalAgua; }

    public BigDecimal getCargoMantenimiento() { return cargoMantenimiento; }
    public void setCargoMantenimiento(BigDecimal cargoMantenimiento) { this.cargoMantenimiento = cargoMantenimiento; }

    public BigDecimal getCargoLector() { return cargoLector; }
    public void setCargoLector(BigDecimal cargoLector) { this.cargoLector = cargoLector; }

    public BigDecimal getCargoOtros() { return cargoOtros; }
    public void setCargoOtros(BigDecimal cargoOtros) { this.cargoOtros = cargoOtros; }

    public BigDecimal getMora() { return mora; }
    public void setMora(BigDecimal mora) { this.mora = mora; }

    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }

    public LocalDateTime getFechaEmision() { return fechaEmision; }
    public void setFechaEmision(LocalDateTime fechaEmision) { this.fechaEmision = fechaEmision; }

    public LocalDate getFechaVencimiento() { return fechaVencimiento; }
    public void setFechaVencimiento(LocalDate fechaVencimiento) { this.fechaVencimiento = fechaVencimiento; }

    public String getCodigoBarras() { return codigoBarras; }
    public void setCodigoBarras(String codigoBarras) { this.codigoBarras = codigoBarras; }
}