package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.LecturaRequest;
import com.jass.huacariz.dto.request.MantenimientoRequest;
import com.jass.huacariz.dto.response.LecturaResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.entity.ConfiguracionCobranza;
import com.jass.huacariz.entity.Lectura;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.entity.Tarifa;
import com.jass.huacariz.repository.ConfiguracionCobranzaRepository;
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
    private final ConfiguracionCobranzaRepository configuracionCobranzaRepository;

    private static final Integer CONFIGURACION_COBRANZA_ID = 1;
    private static final BigDecimal MORA_INICIAL = new BigDecimal("0.00");
    private static final BigDecimal CONSUMO_MINIMO_COBRABLE = new BigDecimal("1.000");
    private static final BigDecimal LIMITE_CONSUMO_INUSUAL = new BigDecimal("100.000");

    @Transactional
    public LecturaResponse registrarLectura(LecturaRequest request) {
        LecturaResponse operacionExistente = buscarOperacionExistente(request.getIdOperacionCliente());
        if (operacionExistente != null) {
            return operacionExistente;
        }

        Suministro suministro = suministroRepository.findByCodigoSuministro(
                        request.getCodigoSuministro().trim().toUpperCase()
                )
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + request.getCodigoSuministro()));

        validarSuministroParaLectura(suministro);

        if (lecturaRepository.existsBySuministroIdAndAnioAndMes(suministro.getId(), request.getAnio(), request.getMes())) {
            throw new RuntimeException("Ya existe una lectura registrada para este suministro en el periodo indicado.");
        }

        BigDecimal lecturaAnterior = obtenerLecturaAnterior(suministro);
        BigDecimal lecturaActual = request.getLecturaActual().setScale(3, RoundingMode.HALF_UP);

        boolean esCambioMedidor = Boolean.TRUE.equals(request.getCambioMedidor());

        BigDecimal lecturaBaseParaConsumo;

        if (esCambioMedidor) {
            if (request.getLecturaInicialNuevoMedidor() == null) {
                throw new RuntimeException("Debe ingresar la lectura inicial del nuevo medidor.");
            }

            BigDecimal lecturaInicialNuevoMedidor = request.getLecturaInicialNuevoMedidor()
                    .setScale(3, RoundingMode.HALF_UP);

            if (lecturaInicialNuevoMedidor.compareTo(BigDecimal.ZERO) < 0) {
                throw new RuntimeException("La lectura inicial del nuevo medidor no puede ser negativa.");
            }

            if (lecturaActual.compareTo(lecturaInicialNuevoMedidor) < 0) {
                throw new RuntimeException("La lectura actual no puede ser menor a la lectura inicial del nuevo medidor.");
            }

            String observacionCambio = request.getObservacionCambioMedidor();

            if (observacionCambio == null || observacionCambio.trim().isBlank()) {
                throw new RuntimeException("Debe ingresar una observación por el cambio de medidor.");
            }

            lecturaBaseParaConsumo = lecturaInicialNuevoMedidor;
        } else {
            if (lecturaActual.compareTo(lecturaAnterior) < 0) {
                throw new RuntimeException("La lectura actual no puede ser menor a la lectura anterior. Si hubo cambio de medidor, marque la opción Cambio de medidor.");
            }

            lecturaBaseParaConsumo = lecturaAnterior;
        }

        BigDecimal consumo = lecturaActual
                .subtract(lecturaBaseParaConsumo)
                .setScale(3, RoundingMode.HALF_UP);

        if (consumo.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("El consumo calculado no puede ser negativo.");
        }

        boolean consumoInusual = consumo.compareTo(LIMITE_CONSUMO_INUSUAL) > 0;

        Lectura lectura = Lectura.builder()
                .suministro(suministro)
                .anio(request.getAnio())
                .mes(request.getMes())
                .lecturaAnterior(lecturaAnterior)
                .lecturaActual(lecturaActual)
                .consumoM3(consumo)
                .fechaLectura(LocalDateTime.now())
                .observacion(request.getObservacion())
                .cambioMedidor(esCambioMedidor)
                .lecturaInicialNuevoMedidor(
                        esCambioMedidor
                                ? request.getLecturaInicialNuevoMedidor().setScale(3, RoundingMode.HALF_UP)
                                : null
                )
                .observacionCambioMedidor(
                        esCambioMedidor
                                ? request.getObservacionCambioMedidor().trim()
                                : null
                )
                .consumoInusual(consumoInusual)
                .idOperacionCliente(normalizarIdOperacion(request.getIdOperacionCliente()))
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

        LecturaResponse operacionExistente = buscarOperacionExistente(request.getIdOperacionCliente());
        if (operacionExistente != null) {
            return operacionExistente;
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

        String observacion = request.getObservacion() == null || request.getObservacion().trim().isBlank()
                ? obtenerObservacionMantenimiento(suministro)
                : request.getObservacion().trim();

        Lectura lectura = Lectura.builder()
                .suministro(suministro)
                .anio(request.getAnio())
                .mes(request.getMes())
                .lecturaAnterior(lecturaAnterior)
                .lecturaActual(lecturaAnterior)
                .consumoM3(BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP))
                .fechaLectura(LocalDateTime.now())
                .observacion(observacion)
                .idOperacionCliente(normalizarIdOperacion(request.getIdOperacionCliente()))
                .build();

        lectura = lecturaRepository.save(lectura);

        Recibo recibo = generarReciboSinConsumoOMantenimiento(lectura, suministro);

        return convertirAResponse(lectura, recibo);
    }

    @Transactional(readOnly = true)
    public List<LecturaResponse> listarLecturas() {
        return lecturaRepository.findAll()
                .stream()
                .map(lectura -> {
                    Recibo recibo = reciboRepository
                            .findByLecturaId(lectura.getId())
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
                    Recibo recibo = reciboRepository
                            .findByLecturaId(lectura.getId())
                            .orElse(null);

                    return convertirAResponse(lectura, recibo);
                })
                .toList();
    }

    private Recibo generarReciboLecturaNormal(
            Lectura lectura,
            Suministro suministro,
            BigDecimal consumo
    ) {
        ConfiguracionCobranza configuracion = obtenerConfiguracionCobranza();

        BigDecimal consumoSeguro = consumo == null
                ? BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP)
                : consumo.setScale(3, RoundingMode.HALF_UP);

        /*
         * INSTALADO:
         * - Si consumo >= 1 m³: agua por tramos + lector + otros.
         * - Si consumo < 1 m³: solo lector + otros.
         * - Nunca cobra mantenimiento.
         */
        BigDecimal subtotalAgua = calcularSubtotalAguaPorTramos(consumoSeguro);
        BigDecimal cargoMantenimiento = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        BigDecimal cargoLector = valorSeguro(configuracion.getCargoLector());
        BigDecimal cargoOtros = valorSeguro(configuracion.getCargoOtros());
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
                .consumoM3(consumoSeguro)
                .subtotalAgua(subtotalAgua)
                .cargoMantenimiento(cargoMantenimiento)
                .cargoLector(cargoLector)
                .cargoOtros(cargoOtros)
                .mora(mora)
                .total(total)
                .estadoRecibo("PENDIENTE")
                .fechaEmision(LocalDateTime.now())
                .fechaVencimiento(calcularFechaVencimiento(configuracion))
                .build();

        return reciboRepository.save(recibo);
    }

    private Recibo generarReciboSinConsumoOMantenimiento(
            Lectura lectura,
            Suministro suministro
    ) {
        ConfiguracionCobranza configuracion = obtenerConfiguracionCobranza();

        BigDecimal subtotalAgua = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        BigDecimal consumo = BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP);

        BigDecimal cargoMantenimiento;
        BigDecimal cargoLector;
        BigDecimal cargoOtros;
        BigDecimal mora = MORA_INICIAL.setScale(2, RoundingMode.HALF_UP);

        if (esSuministroInstalado(suministro)) {
            /*
             * Instalado con consumo cero:
             * cobra lector + otros.
             */
            cargoMantenimiento = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
            cargoLector = valorSeguro(configuracion.getCargoLector());
            cargoOtros = valorSeguro(configuracion.getCargoOtros());
        } else {
            /*
             * Pendiente de instalación:
             * solo cobra mantenimiento.
             * No cobra lector ni otros cargos.
             */
            cargoMantenimiento = valorSeguro(configuracion.getCargoMantenimiento());
            cargoLector = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
            cargoOtros = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }

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
                .fechaVencimiento(calcularFechaVencimiento(configuracion))
                .build();

        return reciboRepository.save(recibo);
    }

    private BigDecimal calcularSubtotalAguaPorTramos(BigDecimal consumo) {
        if (consumo == null || consumo.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }

        BigDecimal consumoTotal = consumo.setScale(3, RoundingMode.HALF_UP);

        /*
         * Regla JASS:
         * Si el consumo es menor a 1 m³, no se cobra agua.
         * Solo se cobrarán lector + otros desde generarReciboLecturaNormal().
         */
        if (consumoTotal.compareTo(CONSUMO_MINIMO_COBRABLE) < 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }

        List<Tarifa> tarifas = tarifaRepository.findByEstadoTrueOrderByConsumoDesdeAsc();

        if (tarifas == null || tarifas.isEmpty()) {
            throw new RuntimeException("No existen tarifas activas para calcular el consumo de agua.");
        }

        BigDecimal subtotal = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        BigDecimal inicioTramoAnterior = BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP);

        for (Tarifa tarifa : tarifas) {
            BigDecimal finTramo = tarifa.getConsumoHasta();
            BigDecimal precioM3 = valorSeguro(tarifa.getPrecioM3());

            BigDecimal limiteAplicable = finTramo == null
                    ? consumoTotal
                    : consumoTotal.min(finTramo.setScale(3, RoundingMode.HALF_UP));

            if (consumoTotal.compareTo(inicioTramoAnterior) <= 0) {
                break;
            }

            BigDecimal consumoDelTramo = limiteAplicable
                    .subtract(inicioTramoAnterior)
                    .setScale(3, RoundingMode.HALF_UP);

            if (consumoDelTramo.compareTo(BigDecimal.ZERO) > 0) {
                subtotal = subtotal.add(
                        consumoDelTramo.multiply(precioM3).setScale(2, RoundingMode.HALF_UP)
                );
            }

            if (finTramo == null || consumoTotal.compareTo(finTramo) <= 0) {
                break;
            }

            inicioTramoAnterior = finTramo.setScale(3, RoundingMode.HALF_UP);
        }

        return subtotal.setScale(2, RoundingMode.HALF_UP);
    }

    private void validarSuministroParaLectura(Suministro suministro) {
        if (!Boolean.TRUE.equals(suministro.getEstado())) {
            throw new RuntimeException("El suministro se encuentra inactivo o suspendido. No se puede registrar lectura.");
        }

        if (!esSuministroInstalado(suministro)) {
            throw new RuntimeException("Este suministro aún no está instalado. No se puede registrar lectura normal. Genere recibo básico por mantenimiento.");
        }
    }

    private String obtenerObservacionMantenimiento(Suministro suministro) {
        if (esSuministroInstalado(suministro)) {
            return "Recibo generado por consumo cero. Suministro instalado sin consumo registrado.";
        }

        return "Recibo generado por mantenimiento. Suministro pendiente de instalación.";
    }

    private BigDecimal obtenerLecturaAnterior(Suministro suministro) {
        return lecturaRepository.findTopBySuministroIdOrderByAnioDescMesDesc(suministro.getId())
                .map(Lectura::getLecturaActual)
                .orElse(suministro.getLecturaInicial() != null
                        ? suministro.getLecturaInicial()
                        : BigDecimal.ZERO)
                .setScale(3, RoundingMode.HALF_UP);
    }

    private ConfiguracionCobranza obtenerConfiguracionCobranza() {
        return configuracionCobranzaRepository.findById(CONFIGURACION_COBRANZA_ID)
                .or(() -> configuracionCobranzaRepository.findTopByOrderByIdDesc())
                .orElseThrow(() -> new RuntimeException("No existe configuración de cobranza. Registre la configuración desde el panel de tarifas."));
    }

    private LocalDate calcularFechaVencimiento(ConfiguracionCobranza configuracion) {
        int dias = configuracion != null && configuracion.getDiasVencimiento() != null
                ? configuracion.getDiasVencimiento()
                : 15;

        return LocalDate.now().plusDays(dias);
    }

    private boolean esSuministroInstalado(Suministro suministro) {
        if (suministro == null || suministro.getEstadoInstalacion() == null) {
            return false;
        }

        return "INSTALADO".equalsIgnoreCase(suministro.getEstadoInstalacion().trim());
    }

    private LecturaResponse buscarOperacionExistente(String idOperacionCliente) {
        String idNormalizado = normalizarIdOperacion(idOperacionCliente);
        if (idNormalizado == null) {
            return null;
        }

        return lecturaRepository.findByIdOperacionCliente(idNormalizado)
                .map(lectura -> convertirAResponse(
                        lectura,
                        reciboRepository.findByLecturaId(lectura.getId()).orElse(null)
                ))
                .orElse(null);
    }

    private String normalizarIdOperacion(String idOperacionCliente) {
        if (idOperacionCliente == null || idOperacionCliente.trim().isBlank()) {
            return null;
        }
        return idOperacionCliente.trim();
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
                .cambioMedidor(lectura.getCambioMedidor())
                .lecturaInicialNuevoMedidor(lectura.getLecturaInicialNuevoMedidor())
                .observacionCambioMedidor(lectura.getObservacionCambioMedidor())
                .consumoInusual(lectura.getConsumoInusual())
                .idOperacionCliente(lectura.getIdOperacionCliente())
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
                .cambioMedidor(recibo.getLectura() != null ? recibo.getLectura().getCambioMedidor() : false)
                .lecturaInicialNuevoMedidor(recibo.getLectura() != null ? recibo.getLectura().getLecturaInicialNuevoMedidor() : null)
                .observacionCambioMedidor(recibo.getLectura() != null ? recibo.getLectura().getObservacionCambioMedidor() : null)
                .consumoInusual(recibo.getLectura() != null ? recibo.getLectura().getConsumoInusual() : false)
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

        String nombres = suministro.getCliente().getNombres() != null ? suministro.getCliente().getNombres() : "";
        String apellidos = suministro.getCliente().getApellidos() != null ? suministro.getCliente().getApellidos() : "";

        String completo = (nombres + " " + apellidos).trim();

        return completo.isEmpty() ? "No disponible" : completo;
    }

    private String obtenerDniCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null ? suministro.getCliente().getDni() : "-";
    }

    private String obtenerSector(Suministro suministro) {
        if (suministro == null || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null ? suministro.getSector().getNombre() : "-";
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