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

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReciboService {

    private final ReciboRepository reciboRepository;
    private final SuministroRepository suministroRepository;
    private final PagoRepository pagoRepository;

    @Transactional(readOnly = true)
    public List<ReciboResponse> listarRecibos() {
        return reciboRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReciboResponse> listarRecibosPendientes() {
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

    private ReciboResponse convertirAResponse(Recibo recibo) {
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
}