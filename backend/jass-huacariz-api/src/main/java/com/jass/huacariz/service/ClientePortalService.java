package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.CambiarPasswordRequest;
import com.jass.huacariz.dto.request.PagoRequest;
import com.jass.huacariz.dto.response.ClientePerfilResponse;
import com.jass.huacariz.dto.response.PagoResponse;
import com.jass.huacariz.dto.response.ReciboResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.entity.Cliente;
import com.jass.huacariz.entity.Pago;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.entity.Usuario;
import com.jass.huacariz.repository.ClienteRepository;
import com.jass.huacariz.repository.PagoRepository;
import com.jass.huacariz.repository.ReciboRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ClientePortalService {

    private final ClienteRepository clienteRepository;
    private final ReciboRepository reciboRepository;
    private final PagoRepository pagoRepository;
    private final PasswordEncoder passwordEncoder;

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

        return cliente.getSuministros()
                .stream()
                .map(this::convertirSuministroAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReciboResponse> listarMisRecibos() {
        Cliente cliente = obtenerClienteAutenticado();

        return reciboRepository.findAll()
                .stream()
                .filter(recibo -> perteneceAlCliente(cliente, recibo))
                .map(this::convertirReciboAResponse)
                .toList();
    }

    @Transactional
    public PagoResponse pagarMiRecibo(Integer reciboId, PagoRequest request) {
        Cliente cliente = obtenerClienteAutenticado();

        Recibo recibo = reciboRepository.findById(reciboId)
                .orElseThrow(() -> new RuntimeException("No existe el recibo con ID: " + reciboId));

        if (!perteneceAlCliente(cliente, recibo)) {
            throw new RuntimeException("No tienes permiso para pagar este recibo.");
        }

        if ("PAGADO".equalsIgnoreCase(recibo.getEstadoRecibo())) {
            throw new RuntimeException("El recibo ya se encuentra pagado.");
        }

        Pago pago = Pago.builder()
                .recibo(recibo)
                .metodoPago(request.getMetodoPago())
                .codigoOperacion(request.getCodigoOperacion())
                .monto(recibo.getTotal())
                .estadoPago("PAGADO")
                .fechaPago(LocalDateTime.now())
                .build();

        recibo.setEstadoRecibo("PAGADO");

        pagoRepository.save(pago);
        reciboRepository.save(recibo);

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

    @Transactional
    public String cambiarMiPassword(CambiarPasswordRequest request) {
        Cliente cliente = obtenerClienteAutenticado();
        Usuario usuario = cliente.getUsuario();

        if (request.getPasswordActual() == null || request.getPasswordActual().isBlank()) {
            throw new RuntimeException("Ingrese su contraseña actual.");
        }

        if (request.getNuevaPassword() == null || request.getNuevaPassword().isBlank()) {
            throw new RuntimeException("Ingrese la nueva contraseña.");
        }

        if (request.getConfirmarPassword() == null || request.getConfirmarPassword().isBlank()) {
            throw new RuntimeException("Confirme la nueva contraseña.");
        }

        if (!request.getNuevaPassword().equals(request.getConfirmarPassword())) {
            throw new RuntimeException("La nueva contraseña y la confirmación no coinciden.");
        }

        if (request.getNuevaPassword().length() < 6) {
            throw new RuntimeException("La nueva contraseña debe tener al menos 6 caracteres.");
        }

        if (!passwordEncoder.matches(request.getPasswordActual(), usuario.getPasswordHash())) {
            throw new RuntimeException("La contraseña actual es incorrecta.");
        }

        usuario.setPasswordHash(passwordEncoder.encode(request.getNuevaPassword()));

        return "Contraseña actualizada correctamente.";
    }

    private Cliente obtenerClienteAutenticado() {
        String codigoUsuario = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return clienteRepository.findByUsuarioCodigoUsuario(codigoUsuario)
                .orElseThrow(() -> new RuntimeException("No existe cliente asociado al usuario autenticado."));
    }

    private boolean perteneceAlCliente(Cliente cliente, Recibo recibo) {
        return cliente.getSuministros()
                .stream()
                .anyMatch(suministro -> suministro.getId().equals(recibo.getSuministro().getId()));
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