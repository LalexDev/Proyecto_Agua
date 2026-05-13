package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.LecturaRequest;
import com.jass.huacariz.dto.response.LecturaResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.entity.*;
import com.jass.huacariz.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LecturaService {

    private final LecturaRepository lecturaRepository;
    private final SuministroRepository suministroRepository;
    private final TarifaRepository tarifaRepository;
    private final ReciboRepository reciboRepository;

    private static final BigDecimal CARGO_LECTOR = new BigDecimal("1.00");
    private static final BigDecimal CARGO_MANTENIMIENTO_CERO_CONSUMO = new BigDecimal("3.00");
    private static final BigDecimal MORA_INICIAL = new BigDecimal("0.00");

    @Transactional
    public LecturaResponse registrarLectura(LecturaRequest request) {

        Suministro suministro = suministroRepository.findByCodigoSuministro(request.getCodigoSuministro())
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + request.getCodigoSuministro()));

        if (lecturaRepository.existsBySuministroIdAndAnioAndMes(suministro.getId(), request.getAnio(), request.getMes())) {
            throw new RuntimeException("Ya existe una lectura registrada para este suministro en el periodo indicado");
        }

        BigDecimal lecturaAnterior = obtenerLecturaAnterior(suministro);

        if (request.getLecturaActual().compareTo(lecturaAnterior) < 0) {
            throw new RuntimeException("La lectura actual no puede ser menor a la lectura anterior");
        }

        BigDecimal consumo = request.getLecturaActual().subtract(lecturaAnterior);

        Lectura lectura = Lectura.builder()
                .suministro(suministro)
                .anio(request.getAnio())
                .mes(request.getMes())
                .lecturaAnterior(lecturaAnterior)
                .lecturaActual(request.getLecturaActual())
                .consumoM3(consumo)
                .fechaLectura(LocalDateTime.now())
                .observacion(request.getObservacion())
                .build();

        lectura = lecturaRepository.save(lectura);

        Recibo recibo = generarRecibo(lectura, suministro, consumo);

        return convertirAResponse(lectura, recibo);
    }

    @Transactional(readOnly = true)
    public List<LecturaResponse> listarLecturas() {
        return lecturaRepository.findAll()
                .stream()
                .map(lectura -> {
                    Recibo recibo = reciboRepository.findAll()
                            .stream()
                            .filter(r -> r.getLectura().getId().equals(lectura.getId()))
                            .findFirst()
                            .orElse(null);

                    return convertirAResponse(lectura, recibo);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<LecturaResponse> listarLecturasPorSuministro(Integer suministroId) {
        return lecturaRepository.findBySuministroId(suministroId)
                .stream()
                .map(lectura -> {
                    Recibo recibo = reciboRepository.findAll()
                            .stream()
                            .filter(r -> r.getLectura().getId().equals(lectura.getId()))
                            .findFirst()
                            .orElse(null);

                    return convertirAResponse(lectura, recibo);
                })
                .toList();
    }

    private BigDecimal obtenerLecturaAnterior(Suministro suministro) {
        return lecturaRepository.findTopBySuministroIdOrderByAnioDescMesDesc(suministro.getId())
                .map(Lectura::getLecturaActual)
                .orElse(suministro.getLecturaInicial());
    }

    private Recibo generarRecibo(Lectura lectura, Suministro suministro, BigDecimal consumo) {
        BigDecimal precioM3 = obtenerPrecioPorConsumo(consumo);
        BigDecimal subtotalAgua = consumo.multiply(precioM3);

        BigDecimal cargoMantenimiento = consumo.compareTo(BigDecimal.ZERO) == 0
                ? CARGO_MANTENIMIENTO_CERO_CONSUMO
                : BigDecimal.ZERO;

        BigDecimal total = subtotalAgua
                .add(cargoMantenimiento)
                .add(CARGO_LECTOR)
                .add(MORA_INICIAL);

        Recibo recibo = Recibo.builder()
                .lectura(lectura)
                .suministro(suministro)
                .codigoRecibo(generarCodigoRecibo())
                .anio(lectura.getAnio())
                .mes(lectura.getMes())
                .consumoM3(consumo)
                .subtotalAgua(subtotalAgua)
                .cargoMantenimiento(cargoMantenimiento)
                .cargoLector(CARGO_LECTOR)
                .mora(MORA_INICIAL)
                .total(total)
                .estadoRecibo("PENDIENTE")
                .fechaEmision(LocalDateTime.now())
                .fechaVencimiento(LocalDate.now().plusDays(15))
                .build();

        return reciboRepository.save(recibo);
    }

    private BigDecimal obtenerPrecioPorConsumo(BigDecimal consumo) {
        List<Tarifa> tarifas = tarifaRepository.findByEstadoTrueOrderByConsumoDesdeAsc();

        return tarifas.stream()
                .filter(tarifa -> consumo.compareTo(tarifa.getConsumoDesde()) >= 0)
                .filter(tarifa -> tarifa.getConsumoHasta() == null || consumo.compareTo(tarifa.getConsumoHasta()) <= 0)
                .findFirst()
                .map(Tarifa::getPrecioM3)
                .orElseThrow(() -> new RuntimeException("No existe una tarifa activa para el consumo: " + consumo));
    }

    private LecturaResponse convertirAResponse(Lectura lectura, Recibo recibo) {
        return LecturaResponse.builder()
                .id(lectura.getId())
                .codigoSuministro(lectura.getSuministro().getCodigoSuministro())
                .direccionSuministro(lectura.getSuministro().getDireccionSuministro())
                .anio(lectura.getAnio())
                .mes(lectura.getMes())
                .lecturaAnterior(lectura.getLecturaAnterior())
                .lecturaActual(lectura.getLecturaActual())
                .consumoM3(lectura.getConsumoM3())
                .fechaLectura(lectura.getFechaLectura())
                .observacion(lectura.getObservacion())
                .recibo(recibo != null ? convertirReciboAResponse(recibo) : null)
                .build();
    }

    private ReciboResponse convertirReciboAResponse(Recibo recibo) {
        return ReciboResponse.builder()
                .id(recibo.getId())
                .codigoRecibo(recibo.getCodigoRecibo())
                .anio(recibo.getAnio())
                .mes(recibo.getMes())
                .consumoM3(recibo.getConsumoM3())
                .subtotalAgua(recibo.getSubtotalAgua())
                .cargoMantenimiento(recibo.getCargoMantenimiento())
                .cargoLector(recibo.getCargoLector())
                .mora(recibo.getMora())
                .total(recibo.getTotal())
                .estadoRecibo(recibo.getEstadoRecibo())
                .fechaEmision(recibo.getFechaEmision())
                .fechaVencimiento(recibo.getFechaVencimiento())
                .build();
    }

    private String generarCodigoRecibo() {
        return "REC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}