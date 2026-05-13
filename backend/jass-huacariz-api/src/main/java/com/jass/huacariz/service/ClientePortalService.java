package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.ClientePerfilResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.entity.Cliente;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.ClienteRepository;
import com.jass.huacariz.repository.ReciboRepository;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ClientePortalService {

    private final ClienteRepository clienteRepository;
    private final SuministroRepository suministroRepository;
    private final ReciboRepository reciboRepository;

    @Transactional(readOnly = true)
    public ClientePerfilResponse obtenerMiPerfil() {
        Cliente cliente = obtenerClienteAutenticado();

        return ClientePerfilResponse.builder()
                .idCliente(cliente.getId())
                .codigoUsuario(cliente.getUsuario().getCodigoUsuario())
                .dni(cliente.getDni())
                .nombres(cliente.getNombres())
                .apellidos(cliente.getApellidos())
                .telefono(cliente.getTelefono())
                .correo(cliente.getCorreo())
                .estado(cliente.getEstado())
                .build();
    }

    @Transactional(readOnly = true)
    public List<SuministroResponse> listarMisSuministros() {
        Cliente cliente = obtenerClienteAutenticado();

        return suministroRepository.findByClienteId(cliente.getId())
                .stream()
                .map(this::convertirSuministroAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReciboResponse> listarMisRecibos() {
        Cliente cliente = obtenerClienteAutenticado();

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());
        List<ReciboResponse> recibosResponse = new ArrayList<>();

        for (Suministro suministro : suministros) {
            List<Recibo> recibos = reciboRepository.findBySuministroId(suministro.getId());

            recibos.stream()
                    .map(this::convertirReciboAResponse)
                    .forEach(recibosResponse::add);
        }

        return recibosResponse;
    }

    private Cliente obtenerClienteAutenticado() {
        String codigoUsuario = SecurityContextHolder.getContext().getAuthentication().getName();

        return clienteRepository.findByUsuarioCodigoUsuario(codigoUsuario)
                .orElseThrow(() -> new RuntimeException("No existe cliente asociado al usuario autenticado"));
    }

    private SuministroResponse convertirSuministroAResponse(Suministro suministro) {
        return SuministroResponse.builder()
                .id(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .idSector(suministro.getSector().getId())
                .nombreSector(suministro.getSector().getNombre())
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(suministro.getLecturaInicial())
                .estado(suministro.getEstado())
                .build();
    }

    private ReciboResponse convertirReciboAResponse(Recibo recibo) {
        return ReciboResponse.builder()
                .id(recibo.getId())
                .codigoRecibo(recibo.getCodigoRecibo())
                .codigoSuministro(recibo.getSuministro().getCodigoSuministro())
                .direccionSuministro(recibo.getSuministro().getDireccionSuministro())
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