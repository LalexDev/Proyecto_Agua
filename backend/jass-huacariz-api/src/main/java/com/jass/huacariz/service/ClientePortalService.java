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
import org.springframework.web.multipart.MultipartFile;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

import java.math.BigDecimal;
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
public PagoResponse pagarMiRecibo(
        Integer reciboId,
        String metodoPago,
        String codigoOperacion,
        MultipartFile comprobante
) {
    Cliente cliente = obtenerClienteAutenticado();

    Recibo recibo = reciboRepository.findById(reciboId)
            .orElseThrow(() -> new RuntimeException("No existe el recibo con ID: " + reciboId));

    if (!perteneceAlCliente(cliente, recibo)) {
        throw new RuntimeException("No tienes permiso para pagar este recibo.");
    }

    if ("PAGADO".equalsIgnoreCase(recibo.getEstadoRecibo())) {
        throw new RuntimeException("El recibo ya se encuentra pagado.");
    }

    if ("PAGO_EN_REVISION".equalsIgnoreCase(recibo.getEstadoRecibo())) {
        throw new RuntimeException("Este recibo ya tiene un pago enviado para revisión.");
    }

    if (metodoPago == null || metodoPago.isBlank()) {
        throw new RuntimeException("Seleccione un método de pago.");
    }

    if (codigoOperacion == null || codigoOperacion.isBlank()) {
        throw new RuntimeException("Ingrese el código de operación.");
    }

    if (comprobante == null || comprobante.isEmpty()) {
        throw new RuntimeException("Debe subir una captura del comprobante.");
    }

    String codigoLimpio = codigoOperacion.trim();

    boolean codigoDuplicado = pagoRepository.existsByCodigoOperacionIgnoreCaseAndEstadoPagoIn(
            codigoLimpio,
            List.of("PAGO_EN_REVISION", "PAGADO_CONFIRMADO", "PAGADO")
    );

    if (codigoDuplicado) {
        throw new RuntimeException("Este código de operación ya fue registrado.");
    }

    String comprobanteUrl = guardarComprobante(comprobante);

    Pago pago = Pago.builder()
            .recibo(recibo)
            .metodoPago(metodoPago.trim())
            .codigoOperacion(codigoLimpio)
            .comprobanteUrl(comprobanteUrl)
            .monto(valorSeguro(recibo.getTotal()))
            .estadoPago("PAGO_EN_REVISION")
            .fechaPago(LocalDateTime.now())
            .build();

    recibo.setEstadoRecibo("PAGO_EN_REVISION");

    pagoRepository.save(pago);
    reciboRepository.save(recibo);

    return PagoResponse.builder()
            .id(pago.getId())
            .idRecibo(recibo.getId())
            .codigoRecibo(recibo.getCodigoRecibo())
            .metodoPago(pago.getMetodoPago())
            .codigoOperacion(pago.getCodigoOperacion())
            .comprobanteUrl(pago.getComprobanteUrl())
            .monto(pago.getMonto())
            .estadoPago(pago.getEstadoPago())
            .fechaPago(pago.getFechaPago())
            .build();
}


private String guardarComprobante(MultipartFile archivo) {
    try {
        String contentType = archivo.getContentType();

        if (contentType == null ||
                (!contentType.equalsIgnoreCase("image/jpeg") &&
                 !contentType.equalsIgnoreCase("image/png") &&
                 !contentType.equalsIgnoreCase("image/webp"))) {
            throw new RuntimeException("Solo se permiten imágenes JPG, PNG o WEBP.");
        }

        long maxSize = 3 * 1024 * 1024;

        if (archivo.getSize() > maxSize) {
            throw new RuntimeException("La imagen no debe superar los 3 MB.");
        }

        String extension = switch (contentType.toLowerCase()) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };

        Path carpeta = Paths.get("uploads", "comprobantes");

        if (!Files.exists(carpeta)) {
            Files.createDirectories(carpeta);
        }

        String nombreArchivo = "comprobante-" + UUID.randomUUID() + extension;
        Path destino = carpeta.resolve(nombreArchivo);

        Files.copy(archivo.getInputStream(), destino);

        return "/uploads/comprobantes/" + nombreArchivo;

    } catch (Exception e) {
        throw new RuntimeException("No se pudo guardar el comprobante: " + e.getMessage());
    }
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
                .idSector(suministro.getSector() != null ? suministro.getSector().getId() : null)
                .nombreSector(suministro.getSector() != null ? suministro.getSector().getNombre() : "-")
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(valorSeguro(suministro.getLecturaInicial()))
                .estado(suministro.getEstado())
                .estadoInstalacion(obtenerEstadoInstalacionSeguro(suministro))
                .build();
    }

    private String obtenerEstadoInstalacionSeguro(Suministro suministro) {
        if (suministro == null) {
            return "PENDIENTE_INSTALACION";
        }

        if (suministro.getEstadoInstalacion() != null && !suministro.getEstadoInstalacion().isBlank()) {
            return suministro.getEstadoInstalacion();
        }

        if (Boolean.FALSE.equals(suministro.getEstado())) {
            return "SUSPENDIDO";
        }

        return "PENDIENTE_INSTALACION";
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
                .consumoM3(valorSeguro(recibo.getConsumoM3()))
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
        return valor != null ? valor : BigDecimal.ZERO;
    }

    private String generarCodigoBarras(Recibo recibo) {
        String codigoRecibo = recibo.getCodigoRecibo() != null
                ? recibo.getCodigoRecibo()
                : "SIN-RECIBO";

        String codigoSuministro = recibo.getSuministro() != null &&
                recibo.getSuministro().getCodigoSuministro() != null
                ? recibo.getSuministro().getCodigoSuministro()
                : "SIN-SUMINISTRO";

        return codigoRecibo + "-" + codigoSuministro;
    }
}