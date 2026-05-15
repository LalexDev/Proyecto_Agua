package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.entity.Pago;
import com.jass.huacariz.repository.PagoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PagoService {

    private final PagoRepository pagoRepository;

    @Transactional(readOnly = true)
    public List<PagoResponse> listarPagos() {
        return pagoRepository.findAll()
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
        return pagoRepository.findByReciboSuministroCodigoSuministro(codigoSuministro.trim().toUpperCase())
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    private PagoResponse convertirAResponse(Pago pago) {
        return PagoResponse.builder()
                .id(pago.getId())
                .idRecibo(pago.getRecibo().getId())
                .codigoRecibo(pago.getRecibo().getCodigoRecibo())
                .metodoPago(pago.getMetodoPago())
                .codigoOperacion(pago.getCodigoOperacion())
                .monto(pago.getMonto())
                .estadoPago(pago.getEstadoPago())
                .fechaPago(pago.getFechaPago())
                .build();
    }
}