package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.PagoRequest;
import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.entity.Pago;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.PagoRepository;
import com.jass.huacariz.repository.ReciboRepository;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.jass.huacariz.entity.ConfiguracionCobranza;
import com.jass.huacariz.repository.ConfiguracionCobranzaRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReciboService {

    private final ReciboRepository reciboRepository;
    private final SuministroRepository suministroRepository;
    private final PagoRepository pagoRepository;
    private final ConfiguracionCobranzaRepository configuracionCobranzaRepository;

    @Transactional
    public List<ReciboResponse> listarRecibos() {
        actualizarVencidosConMora();

        return reciboRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional
    public List<ReciboResponse> listarRecibosPendientes() {
        actualizarVencidosConMora();

        return reciboRepository.findByEstadoRecibo("PENDIENTE")
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ReciboResponse obtenerPorCodigoRecibo(String codigoRecibo) {
        Recibo recibo = reciboRepository.findByCodigoRecibo(codigoRecibo)
                .orElseThrow(() -> new RuntimeException("No existe el recibo con código: " + codigoRecibo));

        return convertirAResponse(recibo);
    }

    @Transactional(readOnly = true)
    public List<ReciboResponse> listarRecibosPorSuministro(String codigoSuministro) {
        Suministro suministro = suministroRepository.findByCodigoSuministro(codigoSuministro.trim().toUpperCase())
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + codigoSuministro));

        return reciboRepository.findBySuministroId(suministro.getId())
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional
    public PagoResponse pagarRecibo(Integer reciboId, PagoRequest request) {
        Recibo recibo = reciboRepository.findById(reciboId)
                .orElseThrow(() -> new RuntimeException("No existe el recibo con ID: " + reciboId));

        if ("PAGADO".equalsIgnoreCase(recibo.getEstadoRecibo())) {
            throw new RuntimeException("El recibo ya se encuentra pagado");
        }

        recibo.setEstadoRecibo("PAGADO");
        reciboRepository.save(recibo);

        Pago pago = Pago.builder()
                .recibo(recibo)
                .metodoPago(request.getMetodoPago())
                .codigoOperacion(request.getCodigoOperacion())
                .monto(recibo.getTotal())
                .estadoPago("PAGADO")
                .fechaPago(LocalDateTime.now())
                .build();

        pago = pagoRepository.save(pago);

        return PagoResponse.builder()
                .id(pago.getId())
                .idRecibo(recibo.getId())
                .codigoRecibo(recibo.getCodigoRecibo())
                .metodoPago(pago.getMetodoPago())
                .codigoOperacion(pago.getCodigoOperacion())
                .monto(pago.getMonto())
                .estadoPago(pago.getEstadoPago())
                .fechaPago(pago.getFechaPago())
                .build();
    }
    private void actualizarVencidosConMora() {
        ConfiguracionCobranza config = configuracionCobranzaRepository
                .findTopByOrderByIdDesc()
                .orElse(null);

        BigDecimal moraBase = config != null && config.getMoraBase() != null
                ? config.getMoraBase()
                : BigDecimal.ZERO;

        List<Recibo> vencidos = reciboRepository.findByEstadoRecibo("PENDIENTE")
                .stream()
                .filter(recibo -> recibo.getFechaVencimiento() != null)
                .filter(recibo -> recibo.getFechaVencimiento().isBefore(LocalDate.now()))
                .toList();

        for (Recibo recibo : vencidos) {
            BigDecimal mora = valorSeguro(moraBase);

            BigDecimal totalConMora = valorSeguro(recibo.getSubtotalAgua())
                    .add(valorSeguro(recibo.getCargoMantenimiento()))
                    .add(valorSeguro(recibo.getCargoLector()))
                    .add(valorSeguro(recibo.getCargoOtros()))
                    .add(mora)
                    .setScale(2, RoundingMode.HALF_UP);

            recibo.setEstadoRecibo("VENCIDO");
            recibo.setMora(mora);
            recibo.setTotal(totalConMora);
        }

        reciboRepository.saveAll(vencidos);
    }

    private ReciboResponse convertirAResponse(Recibo recibo) {
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
                .telefonoCliente(obtenerTelefonoCliente(suministro))
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


    private String obtenerTelefonoCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "";
        }

        return suministro.getCliente().getTelefono() != null
                ? suministro.getCliente().getTelefono()
                : "";
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

    private String generarCodigoBarras(Recibo recibo) {
        String codigoRecibo = recibo.getCodigoRecibo() == null ? "" : recibo.getCodigoRecibo();
        String codigoSuministro = recibo.getSuministro() == null ? "" : recibo.getSuministro().getCodigoSuministro();

        return codigoRecibo + "-" + codigoSuministro;
    }
}