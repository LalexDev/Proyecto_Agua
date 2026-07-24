package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.entity.Pago;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.repository.PagoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class PagoService {

    private static final String ESTADO_REVISION = "PAGO_EN_REVISION";
    private static final String ESTADO_CONFIRMADO = "PAGADO_CONFIRMADO";
    private static final String ESTADO_PAGADO = "PAGADO";
    private static final String ESTADO_RECHAZADO = "RECHAZADO";

    private final PagoRepository pagoRepository;

    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagos() {
        return pagoRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagos(String estado) {
        if (estado == null || estado.isBlank() || "TODOS".equalsIgnoreCase(estado)) {
            return listarPagos();
        }

        String estadoNormalizado = estado.trim().toUpperCase(Locale.ROOT);

        validarEstadoPago(estadoNormalizado);

        return pagoRepository.findByEstadoPagoOrderByFechaPagoDesc(estadoNormalizado)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }


    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagosOptimizado(
            String estado,
            Integer anio,
            Integer mes,
            String buscar,
            Integer limit
    ) {
        String estadoNormalizado = null;

        if (estado != null && !estado.isBlank() && !"TODOS".equalsIgnoreCase(estado)) {
            estadoNormalizado = estado.trim().toUpperCase(Locale.ROOT);
            validarEstadoPago(estadoNormalizado);
        }

        String busquedaNormalizada = buscar == null ? null : buscar.trim();
        int limite = normalizarLimite(limit);

        return pagoRepository.buscarPagosOptimizado(
                        anio,
                        mes,
                        estadoNormalizado,
                        busquedaNormalizada,
                        PageRequest.of(0, limite)
                )
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PagoResponse obtenerPagoPorId(Integer id) {
        Pago pago = pagoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el pago con ID: " + id));

        return convertirAResponse(pago);
    }

    @Transactional(readOnly = true)
    public PagoResponse obtenerPagoPorRecibo(Integer reciboId) {
        Pago pago = pagoRepository.findByReciboId(reciboId)
                .orElseThrow(() -> new RuntimeException("No existe pago registrado para el recibo ID: " + reciboId));

        return convertirAResponse(pago);
    }

    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagosPorSuministro(String codigoSuministro) {
        return pagoRepository.findByReciboSuministroCodigoSuministro(
                        codigoSuministro.trim().toUpperCase(Locale.ROOT)
                )
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagosEnRevision() {
        return pagoRepository.findByEstadoPagoOrderByFechaPagoDesc(ESTADO_REVISION)
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional
    public PagoResponse aprobarPago(Integer id) {
        Pago pago = pagoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el pago con ID: " + id));

        if (!ESTADO_REVISION.equalsIgnoreCase(pago.getEstadoPago())) {
            throw new RuntimeException("Solo se puede aprobar un pago en revisión.");
        }

        Recibo recibo = pago.getRecibo();

        pago.setEstadoPago(ESTADO_CONFIRMADO);
        pago.setFechaEstadoPago(LocalDateTime.now());

        recibo.setEstadoRecibo("PAGADO");

        Pago actualizado = pagoRepository.save(pago);

        return convertirAResponse(actualizado);
    }

    @Transactional
    public PagoResponse rechazarPago(Integer id) {
        Pago pago = pagoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el pago con ID: " + id));

        if (!ESTADO_REVISION.equalsIgnoreCase(pago.getEstadoPago())) {
            throw new RuntimeException("Solo se puede rechazar un pago en revisión.");
        }

        Recibo recibo = pago.getRecibo();

        pago.setEstadoPago(ESTADO_RECHAZADO);
        pago.setFechaEstadoPago(LocalDateTime.now());

        recibo.setEstadoRecibo("PENDIENTE");

        Pago actualizado = pagoRepository.save(pago);

        return convertirAResponse(actualizado);
    }

    /**
     * Limpia automáticamente pagos rechazados después de 7 días.
     * Se ejecuta todos los días a las 2:00 a. m.
     */
    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void eliminarPagosRechazadosAntiguos() {
        LocalDateTime fechaLimite = LocalDateTime.now().minusDays(7);

        List<Pago> rechazadosAntiguos =
                pagoRepository.findByEstadoPagoAndFechaEstadoPagoBefore(
                        ESTADO_RECHAZADO,
                        fechaLimite
                );

        for (Pago pago : rechazadosAntiguos) {
            eliminarComprobante(pago.getComprobanteUrl());
        }

        pagoRepository.deleteAll(rechazadosAntiguos);
    }

    private void eliminarComprobante(String comprobanteUrl) {
        if (comprobanteUrl == null || comprobanteUrl.isBlank()) {
            return;
        }

        try {
            String rutaRelativa = comprobanteUrl.startsWith("/")
                    ? comprobanteUrl.substring(1)
                    : comprobanteUrl;

            Path archivo = Paths.get(rutaRelativa)
                    .toAbsolutePath()
                    .normalize();

            Files.deleteIfExists(archivo);

        } catch (Exception ignored) {
            // No detenemos la limpieza si el archivo ya no existe.
        }
    }


    private int normalizarLimite(Integer limit) {
        if (limit == null || limit <= 0) {
            return 200;
        }

        return Math.max(20, Math.min(limit, 500));
    }

    private void validarEstadoPago(String estado) {
        boolean valido =
                ESTADO_REVISION.equals(estado)
                        || ESTADO_CONFIRMADO.equals(estado)
                        || ESTADO_PAGADO.equals(estado)
                        || ESTADO_RECHAZADO.equals(estado);

        if (!valido) {
            throw new RuntimeException("Estado de pago no permitido: " + estado);
        }
    }

    private PagoResponse convertirAResponse(Pago pago) {
        return PagoResponse.builder()
                .id(pago.getId())
                .idRecibo(pago.getRecibo().getId())
                .codigoRecibo(pago.getRecibo().getCodigoRecibo())
                .metodoPago(pago.getMetodoPago())
                .codigoOperacion(pago.getCodigoOperacion())
                .comprobanteUrl(pago.getComprobanteUrl())
                .monto(pago.getMonto())
                .estadoPago(pago.getEstadoPago())
                .fechaPago(pago.getFechaPago())
                .build();
    }
}