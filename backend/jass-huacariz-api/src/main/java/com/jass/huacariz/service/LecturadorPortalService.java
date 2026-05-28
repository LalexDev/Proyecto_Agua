package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.SuministroLecturadorResponse;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LecturadorPortalService {

    private final SuministroRepository suministroRepository;

    private static final String INSTALADO = "INSTALADO";
    private static final String PENDIENTE_INSTALACION = "PENDIENTE_INSTALACION";

    @Transactional(readOnly = true)
    public SuministroLecturadorResponse buscarSuministroPorCodigo(String codigoSuministro) {
        Suministro suministro = suministroRepository
                .findByCodigoSuministro(codigoSuministro.trim().toUpperCase())
                .orElseThrow(() -> new RuntimeException("No existe el suministro con código: " + codigoSuministro));

        String estadoInstalacion = obtenerEstadoInstalacion(suministro);

        boolean suministroActivo = Boolean.TRUE.equals(suministro.getEstado());
        boolean clienteActivo = suministro.getCliente() != null && Boolean.TRUE.equals(suministro.getCliente().getEstado());
        boolean estaActivo = suministroActivo && clienteActivo;

        boolean instalado = INSTALADO.equalsIgnoreCase(estadoInstalacion);
        boolean pendienteInstalacion = PENDIENTE_INSTALACION.equalsIgnoreCase(estadoInstalacion);

        boolean permiteRegistrarLectura = estaActivo && instalado;
        boolean permiteGenerarMantenimiento = estaActivo && (instalado || pendienteInstalacion);

        return SuministroLecturadorResponse.builder()
                .id(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .nombreSector(obtenerNombreSector(suministro))
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(suministro.getLecturaInicial())
                .estado(estaActivo)
                .estadoInstalacion(estadoInstalacion)
                .permiteRegistrarLectura(permiteRegistrarLectura)
                .permiteGenerarMantenimiento(permiteGenerarMantenimiento)
                .mensajeEstado(obtenerMensajeEstado(estaActivo, estadoInstalacion))
                .nombreCliente(obtenerNombreCliente(suministro))
                .dniCliente(obtenerDniCliente(suministro))
                .build();
    }

    private String obtenerEstadoInstalacion(Suministro suministro) {
        if (suministro == null || suministro.getEstadoInstalacion() == null || suministro.getEstadoInstalacion().isBlank()) {
            return PENDIENTE_INSTALACION;
        }

        return suministro.getEstadoInstalacion().trim().toUpperCase();
    }

    private String obtenerMensajeEstado(boolean estaActivo, String estadoInstalacion) {
        if (!estaActivo) {
            return "El cliente o suministro se encuentra desactivado. No se puede registrar lectura ni generar mantenimiento.";
        }

        if (INSTALADO.equalsIgnoreCase(estadoInstalacion)) {
            return "Suministro instalado. Puede registrar lectura normal o generar mantenimiento si no hubo consumo.";
        }

        if (PENDIENTE_INSTALACION.equalsIgnoreCase(estadoInstalacion)) {
            return "Este suministro aún no está instalado o fue suspendido. Solo se puede generar recibo por mantenimiento.";
        }

        return "Estado de suministro pendiente de revisión.";
    }

    private String obtenerNombreSector(Suministro suministro) {
        if (suministro == null || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null
                ? suministro.getSector().getNombre()
                : "-";
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

        String nombreCompleto = (nombres + " " + apellidos).trim();

        return nombreCompleto.isEmpty() ? "No disponible" : nombreCompleto;
    }

    private String obtenerDniCliente(Suministro suministro) {
        if (suministro == null || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null
                ? suministro.getCliente().getDni()
                : "-";
    }
}