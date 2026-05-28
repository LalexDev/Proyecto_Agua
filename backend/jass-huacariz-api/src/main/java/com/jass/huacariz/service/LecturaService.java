package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.LecturaRequest;
import com.jass.huacariz.dto.request.MantenimientoRequest;
import com.jass.huacariz.dto.response.LecturaResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.entity.Lectura;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.entity.Tarifa;
import com.jass.huacariz.repository.LecturaRepository;
import com.jass.huacariz.repository.ReciboRepository;
import com.jass.huacariz.repository.SuministroRepository;
import com.jass.huacariz.repository.TarifaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
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

    private static final BigDecimal CARGO_LECTOR_DEFAULT = new BigDecimal("1.00");
    private static final BigDecimal CARGO_MANTENIMIENTO_DEFAULT = new BigDecimal("3.00");
    private static final BigDecimal CARGO_OTROS_DEFAULT = new BigDecimal("0.20");
    private static final BigDecimal MORA_INICIAL = new BigDecimal("0.00");

    @Transactional
    public LecturaResponse registrarLectura(LecturaRequest request) {
        Suministro suministro = suministroRepository.findByCodigoSuministro(
                        request.getCodigoSuministro().trim().toUpperCase()
                )
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + request.getCodigoSuministro()));

        validarSuministroParaLectura(suministro);

        if (lecturaRepository.existsBySuministroIdAndAnioAndMes(suministro.getId(), request.getAnio(), request.getMes())) {
            throw new RuntimeException("Ya existe una lectura registrada para este suministro en el periodo indicado.");
        }

        BigDecimal lecturaAnterior = obtenerLecturaAnterior(suministro);

        if (request.getLecturaActual().compareTo(lecturaAnterior) < 0) {
            throw new RuntimeException("La lectura actual no puede ser menor a la lectura anterior.");
        }

        BigDecimal consumo = request.getLecturaActual()
                .subtract(lecturaAnterior)
                .setScale(3, RoundingMode.HALF_UP);

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

        Recibo recibo = generarReciboLecturaNormal(lectura, suministro, consumo);

        return convertirAResponse(lectura, recibo);
    }

    @Transactional
    public LecturaResponse registrarMantenimiento(MantenimientoRequest request) {
        if (request == null) {
            throw new RuntimeException("Los datos de mantenimiento son obligatorios.");
        }

        if (request.getCodigoSuministro() == null || request.getCodigoSuministro().trim().isBlank()) {
            throw new RuntimeException("Ingrese el código del suministro.");
        }

        if (request.getAnio() == null || request.getMes() == null) {
            throw new RuntimeException("Ingrese el año y mes del recibo.");
        }

        if (request.getAnio() < 2024) {
            throw new RuntimeException("Ingrese un año válido.");
        }

        if (request.getMes() < 1 || request.getMes() > 12) {
            throw new RuntimeException("Ingrese un mes válido entre 1 y 12.");
        }

        Suministro suministro = suministroRepository.findByCodigoSuministro(
                        request.getCodigoSuministro().trim().toUpperCase()
                )
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + request.getCodigoSuministro()));

        if (!Boolean.TRUE.equals(suministro.getEstado())) {
            throw new RuntimeException("El suministro se encuentra inactivo. No se puede generar recibo.");
        }

        if (lecturaRepository.existsBySuministroIdAndAnioAndMes(suministro.getId(), request.getAnio(), request.getMes())) {
            throw new RuntimeException("Ya existe una lectura o recibo registrado para este suministro en el periodo indicado.");
        }

        BigDecimal lecturaAnterior = obtenerLecturaAnterior(suministro);
        BigDecimal consumo = BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP);

        String observacion = request.getObservacion() == null || request.getObservacion().trim().isBlank()
                ? obtenerObservacionMantenimiento(suministro)
                : request.getObservacion().trim();

        Lectura lectura = Lectura.builder()
                .suministro(suministro)
                .anio(request.getAnio())
                .mes(request.getMes())
                .lecturaAnterior(lecturaAnterior)
                .lecturaActual(lecturaAnterior)
                .consumoM3(consumo)
                .fechaLectura(LocalDateTime.now())
                .observacion(observacion)
                .build();

        lectura = lecturaRepository.save(lectura);

        Recibo recibo = generarReciboSoloMantenimiento(lectura, suministro);

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

    private void validarSuministroParaLectura(Suministro suministro) {
        if (!Boolean.TRUE.equals(suministro.getEstado())) {
            throw new RuntimeException("El suministro se encuentra inactivo o suspendido. No se puede registrar lectura.");
        }

        String estadoInstalacion = suministro.getEstadoInstalacion();

        if (estadoInstalacion == null || estadoInstalacion.isBlank()) {
            estadoInstalacion = "PENDIENTE_INSTALACION";
        }

        if (!"INSTALADO".equalsIgnoreCase(estadoInstalacion)) {
            throw new RuntimeException("Este suministro aún no está instalado. No se puede registrar lectura normal. Genere recibo básico por mantenimiento.");
        }
    }

    private String obtenerObservacionMantenimiento(Suministro suministro) {
        String estadoInstalacion = suministro.getEstadoInstalacion();

        if (estadoInstalacion == null || estadoInstalacion.isBlank()) {
            estadoInstalacion = "PENDIENTE_INSTALACION";
        }

        if ("INSTALADO".equalsIgnoreCase(estadoInstalacion)) {
            return "Recibo generado por consumo cero.";
        }

        return "Recibo generado por mantenimiento. Suministro pendiente de instalación.";
    }

    private BigDecimal obtenerLecturaAnterior(Suministro suministro) {
        return lecturaRepository.findTopBySuministroIdOrderByAnioDescMesDesc(suministro.getId())
                .map(Lectura::getLecturaActual)
                .orElse(suministro.getLecturaInicial());
    }

    private Recibo generarReciboLecturaNormal(
            Lectura lectura,
            Suministro suministro,
            BigDecimal consumo
    ) {
        BigDecimal precioM3 = obtenerPrecioPorConsumo(consumo);

        BigDecimal subtotalAgua = consumo
                .multiply(precioM3)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal cargoMantenimiento = consumo.compareTo(BigDecimal.ZERO) == 0
                ? obtenerCargoMantenimiento()
                : BigDecimal.ZERO;

        cargoMantenimiento = cargoMantenimiento.setScale(2, RoundingMode.HALF_UP);

        BigDecimal cargoLector = obtenerCargoLector();
        BigDecimal cargoOtros = obtenerCargoOtros();
        BigDecimal mora = MORA_INICIAL.setScale(2, RoundingMode.HALF_UP);

        BigDecimal total = subtotalAgua
                .add(cargoMantenimiento)
                .add(cargoLector)
                .add(cargoOtros)
                .add(mora)
                .setScale(2, RoundingMode.HALF_UP);

        Recibo recibo = Recibo.builder()
                .lectura(lectura)
                .suministro(suministro)
                .codigoRecibo(generarCodigoRecibo())
                .anio(lectura.getAnio())
                .mes(lectura.getMes())
                .consumoM3(consumo)
                .subtotalAgua(subtotalAgua)
                .cargoMantenimiento(cargoMantenimiento)
                .cargoLector(cargoLector)
                .cargoOtros(cargoOtros)
                .mora(mora)
                .total(total)
                .estadoRecibo("PENDIENTE")
                .fechaEmision(LocalDateTime.now())
                .fechaVencimiento(LocalDate.now().plusDays(15))
                .build();

        return reciboRepository.save(recibo);
    }

    private Recibo generarReciboSoloMantenimiento(
            Lectura lectura,
            Suministro suministro
    ) {
        BigDecimal subtotalAgua = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        BigDecimal consumo = BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP);

        BigDecimal cargoMantenimiento = obtenerCargoMantenimiento();
        BigDecimal cargoLector = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        BigDecimal cargoOtros = obtenerCargoOtros();
        BigDecimal mora = MORA_INICIAL.setScale(2, RoundingMode.HALF_UP);

        BigDecimal total = subtotalAgua
                .add(cargoMantenimiento)
                .add(cargoLector)
                .add(cargoOtros)
                .add(mora)
                .setScale(2, RoundingMode.HALF_UP);

        Recibo recibo = Recibo.builder()
                .lectura(lectura)
                .suministro(suministro)
                .codigoRecibo(generarCodigoRecibo())
                .anio(lectura.getAnio())
                .mes(lectura.getMes())
                .consumoM3(consumo)
                .subtotalAgua(subtotalAgua)
                .cargoMantenimiento(cargoMantenimiento)
                .cargoLector(cargoLector)
                .cargoOtros(cargoOtros)
                .mora(mora)
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

    private BigDecimal obtenerCargoLector() {
        return CARGO_LECTOR_DEFAULT.setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal obtenerCargoMantenimiento() {
        return CARGO_MANTENIMIENTO_DEFAULT.setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal obtenerCargoOtros() {
        return CARGO_OTROS_DEFAULT.setScale(2, RoundingMode.HALF_UP);
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
        Suministro suministro = recibo.getSuministro();

        return ReciboResponse.builder()
                .id(recibo.getId())
                .codigoRecibo(recibo.getCodigoRecibo())
                .codigoSuministro(suministro.getCodigoSuministro())
                .direccionSuministro(suministro.getDireccionSuministro())
                .aliasSuministro(suministro.getAliasSuministro())
                .sector(obtenerSector(suministro))
                .nombreCliente(obtenerNombreCliente(suministro))
                .dniCliente(obtenerDniCliente(suministro))
                .anio(recibo.getAnio())
                .mes(recibo.getMes())
                .consumoM3(recibo.getConsumoM3())
                .subtotalAgua(valorSeguro(recibo.getSubtotalAgua()))
                .cargoMantenimiento(valorSeguro(recibo.getCargoMantenimiento()))
                .cargoLector(valorSeguro(recibo.getCargoLector()))
                .cargoOtros(valorSeguro(recibo.getCargoOtros()))
                .mora(valorSeguro(recibo.getMora()))
                .total(valorSeguro(recibo.getTotal()))
                .estadoRecibo(recibo.getEstadoRecibo())
                .fechaEmision(recibo.getFechaEmision())
                .fechaVencimiento(recibo.getFechaVencimiento())
                .codigoBarras(generarCodigoBarras(recibo))
                .build();
    }

    private String obtenerNombreCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "No disponible";
        }

        String nombres = suministro.getCliente().getNombres() != null
                ? suministro.getCliente().getNombres()
                : "";

        String apellidos = suministro.getCliente().getApellidos() != null
                ? suministro.getCliente().getApellidos()
                : "";

        String completo = (nombres + " " + apellidos).trim();

        return completo.isEmpty() ? "No disponible" : completo;
    }

    private String obtenerDniCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null
                ? suministro.getCliente().getDni()
                : "-";
    }

    private String obtenerSector(Suministro suministro) {
        if (suministro == null || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null
                ? suministro.getSector().getNombre()
                : "-";
    }

    private BigDecimal valorSeguro(BigDecimal valor) {
        return valor == null
                ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
                : valor.setScale(2, RoundingMode.HALF_UP);
    }

    private String generarCodigoRecibo() {
        return "REC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private String generarCodigoBarras(Recibo recibo) {
        String codigoRecibo = recibo.getCodigoRecibo() == null ? "" : recibo.getCodigoRecibo();
        String codigoSuministro = recibo.getSuministro() == null ? "" : recibo.getSuministro().getCodigoSuministro();

        return codigoRecibo + "-" + codigoSuministro;
    }
}