package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.CanalPagoRequest;
import com.jass.huacariz.dto.response.CanalPagoResponse;
import com.jass.huacariz.entity.CanalPago;
import com.jass.huacariz.repository.CanalPagoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CanalPagoService {

    private static final long TAMANIO_MAXIMO_QR = 3L * 1024L * 1024L;

    private final CanalPagoRepository repository;

    @Transactional(readOnly = true)
    public List<CanalPagoResponse> listar() {
        return repository.findAll()
                .stream()
                .map(this::convertir)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CanalPagoResponse> listarActivos() {
        return repository.findByEstadoTrue()
                .stream()
                .map(this::convertir)
                .toList();
    }

    @Transactional
    public CanalPagoResponse crear(
            CanalPagoRequest request,
            MultipartFile qr
    ) {
        validarRequest(request);

        String metodo = normalizar(request.getMetodoPago()).toUpperCase(Locale.ROOT);

        if (esBilletera(metodo) && (qr == null || qr.isEmpty())) {
            throw new RuntimeException("Debe subir una imagen QR para Yape o Plin.");
        }

        CanalPago canal = CanalPago.builder()
                .metodoPago(metodo)
                .titular(normalizar(request.getTitular()))
                .numero(esBilletera(metodo) ? normalizarOpcional(request.getNumero()) : null)
                .banco(esTransferencia(metodo) ? normalizarOpcional(request.getBanco()) : null)
                .cuenta(esTransferencia(metodo) ? normalizarOpcional(request.getCuenta()) : null)
                .cci(esTransferencia(metodo) ? normalizarOpcional(request.getCci()) : null)
                .descripcion(normalizarOpcional(request.getDescripcion()))
                .qrUrl(null)
                .estado(request.getEstado() != null ? request.getEstado() : true)
                .fechaActualizacion(LocalDateTime.now())
                .build();

        CanalPago guardado = repository.save(canal);

        if (esBilletera(metodo)) {
            String qrUrl = guardarQr(qr, guardado.getId());
            guardado.setQrUrl(qrUrl);
            guardado.setFechaActualizacion(LocalDateTime.now());
            guardado = repository.save(guardado);
        }

        return convertir(guardado);
    }

    @Transactional
    public CanalPagoResponse actualizar(
            Integer id,
            CanalPagoRequest request,
            MultipartFile qr
    ) {
        CanalPago canal = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Canal de pago no encontrado."));

        validarRequest(request);

        String metodo = normalizar(request.getMetodoPago()).toUpperCase(Locale.ROOT);

        canal.setMetodoPago(metodo);
        canal.setTitular(normalizar(request.getTitular()));
        canal.setDescripcion(normalizarOpcional(request.getDescripcion()));
        canal.setEstado(request.getEstado() != null ? request.getEstado() : canal.getEstado());
        canal.setFechaActualizacion(LocalDateTime.now());

        if (esBilletera(metodo)) {
            canal.setNumero(normalizarOpcional(request.getNumero()));
            canal.setBanco(null);
            canal.setCuenta(null);
            canal.setCci(null);

            boolean noTieneQrGuardado = canal.getQrUrl() == null || canal.getQrUrl().isBlank();
            boolean noSubioQrNuevo = qr == null || qr.isEmpty();

            if (noTieneQrGuardado && noSubioQrNuevo) {
                throw new RuntimeException("Debe subir una imagen QR para Yape o Plin.");
            }

            if (qr != null && !qr.isEmpty()) {
                eliminarArchivoAnterior(canal.getQrUrl());

                String qrUrl = guardarQr(qr, canal.getId());
                canal.setQrUrl(qrUrl);
            }
        }

        if (esTransferencia(metodo)) {
            canal.setNumero(null);
            canal.setBanco(normalizarOpcional(request.getBanco()));
            canal.setCuenta(normalizarOpcional(request.getCuenta()));
            canal.setCci(normalizarOpcional(request.getCci()));

            eliminarArchivoAnterior(canal.getQrUrl());
            canal.setQrUrl(null);
        }

        CanalPago actualizado = repository.save(canal);

        return convertir(actualizado);
    }

    private void validarRequest(CanalPagoRequest request) {
        if (request == null) {
            throw new RuntimeException("Los datos del canal son obligatorios.");
        }

        if (request.getMetodoPago() == null || request.getMetodoPago().isBlank()) {
            throw new RuntimeException("El método de pago es obligatorio.");
        }

        if (request.getTitular() == null || request.getTitular().isBlank()) {
            throw new RuntimeException("El titular es obligatorio.");
        }

        String metodo = request.getMetodoPago().trim().toUpperCase(Locale.ROOT);

        if (!esBilletera(metodo) && !esTransferencia(metodo)) {
            throw new RuntimeException("Método de pago no permitido.");
        }

        if (esBilletera(metodo)
                && (request.getNumero() == null || request.getNumero().isBlank())) {
            throw new RuntimeException("El número de celular es obligatorio para Yape o Plin.");
        }

        if (esTransferencia(metodo)) {
            if (request.getBanco() == null || request.getBanco().isBlank()) {
                throw new RuntimeException("El banco es obligatorio para transferencia.");
            }

            boolean sinCuenta = request.getCuenta() == null || request.getCuenta().isBlank();
            boolean sinCci = request.getCci() == null || request.getCci().isBlank();

            if (sinCuenta && sinCci) {
                throw new RuntimeException("Ingrese al menos una cuenta o un CCI.");
            }
        }
    }

    private boolean esBilletera(String metodo) {
        return "YAPE".equalsIgnoreCase(metodo)
                || "PLIN".equalsIgnoreCase(metodo);
    }

    private boolean esTransferencia(String metodo) {
        return "TRANSFERENCIA".equalsIgnoreCase(metodo);
    }

    private String guardarQr(
            MultipartFile archivo,
            Integer canalId
    ) {
        validarImagen(archivo);

        try {
            Path carpeta = Paths.get("uploads", "canales-pago")
                    .toAbsolutePath()
                    .normalize();

            Files.createDirectories(carpeta);

            String extension = obtenerExtension(archivo);
            String nombreArchivo =
                    "qr-canal-" + canalId + "-" + UUID.randomUUID() + extension;

            Path destino = carpeta.resolve(nombreArchivo).normalize();

            Files.copy(
                    archivo.getInputStream(),
                    destino,
                    StandardCopyOption.REPLACE_EXISTING
            );

            return "/uploads/canales-pago/" + nombreArchivo;

        } catch (IOException e) {
            throw new RuntimeException(
                    "No se pudo guardar la imagen QR: " + e.getMessage()
            );
        }
    }

    private void validarImagen(MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) {
            throw new RuntimeException("La imagen QR está vacía.");
        }

        if (archivo.getSize() > TAMANIO_MAXIMO_QR) {
            throw new RuntimeException("La imagen QR no debe superar los 3 MB.");
        }

        String contentType = archivo.getContentType();

        if (contentType == null) {
            throw new RuntimeException("No se pudo identificar el tipo de imagen.");
        }

        boolean permitido =
                "image/jpeg".equalsIgnoreCase(contentType)
                        || "image/png".equalsIgnoreCase(contentType)
                        || "image/webp".equalsIgnoreCase(contentType);

        if (!permitido) {
            throw new RuntimeException(
                    "Solo se permiten imágenes JPG, PNG o WEBP."
            );
        }
    }

    private String obtenerExtension(MultipartFile archivo) {
        String contentType = archivo.getContentType();

        if ("image/png".equalsIgnoreCase(contentType)) {
            return ".png";
        }

        if ("image/webp".equalsIgnoreCase(contentType)) {
            return ".webp";
        }

        return ".jpg";
    }

    private void eliminarArchivoAnterior(String qrUrl) {
        if (qrUrl == null || qrUrl.isBlank()) {
            return;
        }

        try {
            String rutaRelativa = qrUrl.startsWith("/")
                    ? qrUrl.substring(1)
                    : qrUrl;

            Path archivoAnterior = Paths.get(rutaRelativa)
                    .toAbsolutePath()
                    .normalize();

            Files.deleteIfExists(archivoAnterior);

        } catch (Exception ignored) {
            // Si el archivo anterior no existe, no se interrumpe la actualización.
        }
    }

    private String normalizar(String valor) {
        return valor == null ? "" : valor.trim();
    }

    private String normalizarOpcional(String valor) {
        if (valor == null) {
            return null;
        }

        String limpio = valor.trim();
        return limpio.isEmpty() ? null : limpio;
    }

    private CanalPagoResponse convertir(CanalPago canal) {
        return CanalPagoResponse.builder()
                .id(canal.getId())
                .metodoPago(canal.getMetodoPago())
                .titular(canal.getTitular())
                .numero(canal.getNumero())
                .banco(canal.getBanco())
                .cuenta(canal.getCuenta())
                .cci(canal.getCci())
                .descripcion(canal.getDescripcion())
                .qrUrl(canal.getQrUrl())
                .estado(canal.getEstado())
                .build();
    }
}