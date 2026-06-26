package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.SuministroLecturadorResponse;
import com.jass.huacariz.entity.Lectura;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.LecturaRepository;
import com.jass.huacariz.repository.SuministroRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LecturadorPortalService {

    private final SuministroRepository suministroRepository;
    private final LecturaRepository lecturaRepository;

    private static final String INSTALADO = "INSTALADO";
    private static final String PENDIENTE_INSTALACION =
            "PENDIENTE_INSTALACION";

    @Transactional(readOnly = true)
    public SuministroLecturadorResponse
    buscarSuministroPorCodigo(
            String codigoSuministro
    ) {
        Suministro suministro = suministroRepository
                .findByCodigoSuministro(
                        codigoSuministro
                                .trim()
                                .toUpperCase()
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "No existe el suministro con código: "
                                        + codigoSuministro
                        )
                );

        return convertirRespuesta(suministro);
    }

    /**
     * Catálogo utilizado por Flutter para trabajar sin conexión.
     *
     * La aplicación descarga esta información cuando tiene conexión
     * y la guarda localmente en SQLite.
     */
    @Transactional(readOnly = true)
    public List<SuministroLecturadorResponse>
    listarSuministrosOffline() {

        return suministroRepository
                .findAll()
                .stream()
                .sorted(
                        Comparator.comparing(
                                Suministro::getCodigoSuministro,
                                Comparator.nullsLast(
                                        String.CASE_INSENSITIVE_ORDER
                                )
                        )
                )
                .map(this::convertirRespuesta)
                .toList();
    }

    private SuministroLecturadorResponse convertirRespuesta(
            Suministro suministro
    ) {
        String estadoInstalacion =
                obtenerEstadoInstalacion(suministro);

        boolean suministroActivo =
                Boolean.TRUE.equals(
                        suministro.getEstado()
                );

        boolean clienteActivo =
                suministro.getCliente() != null
                        && Boolean.TRUE.equals(
                        suministro
                                .getCliente()
                                .getEstado()
                );

        boolean estaActivo =
                suministroActivo && clienteActivo;

        boolean instalado =
                INSTALADO.equalsIgnoreCase(
                        estadoInstalacion
                );

        boolean pendienteInstalacion =
                PENDIENTE_INSTALACION.equalsIgnoreCase(
                        estadoInstalacion
                );

        boolean permiteRegistrarLectura =
                estaActivo && instalado;

        boolean permiteGenerarMantenimiento =
                estaActivo
                        && (
                        instalado
                                || pendienteInstalacion
                );

        Lectura ultimaLectura = lecturaRepository
                .findTopBySuministroIdOrderByAnioDescMesDesc(
                        suministro.getId()
                )
                .orElse(null);

        BigDecimal lecturaAnterior =
                obtenerLecturaAnterior(
                        suministro,
                        ultimaLectura
                );

        Integer anioUltimaLectura =
                ultimaLectura == null
                        ? null
                        : ultimaLectura.getAnio();

        Integer mesUltimaLectura =
                ultimaLectura == null
                        ? null
                        : ultimaLectura.getMes();

        return SuministroLecturadorResponse
                .builder()
                .id(suministro.getId())
                .codigoSuministro(
                        suministro.getCodigoSuministro()
                )
                .nombreSector(
                        obtenerNombreSector(suministro)
                )
                .direccionSuministro(
                        suministro.getDireccionSuministro()
                )
                .referencia(
                        suministro.getReferencia()
                )
                .aliasSuministro(
                        suministro.getAliasSuministro()
                )
                .lecturaInicial(
                        suministro.getLecturaInicial()
                )
                .lecturaAnterior(lecturaAnterior)
                .anioUltimaLectura(anioUltimaLectura)
                .mesUltimaLectura(mesUltimaLectura)
                .estado(estaActivo)
                .estadoInstalacion(
                        estadoInstalacion
                )
                .permiteRegistrarLectura(
                        permiteRegistrarLectura
                )
                .permiteGenerarMantenimiento(
                        permiteGenerarMantenimiento
                )
                .mensajeEstado(
                        obtenerMensajeEstado(
                                estaActivo,
                                estadoInstalacion
                        )
                )
                .nombreCliente(
                        obtenerNombreCliente(suministro)
                )
                .dniCliente(
                        obtenerDniCliente(suministro)
                )
                .build();
    }

    private BigDecimal obtenerLecturaAnterior(
            Suministro suministro,
            Lectura ultimaLectura
    ) {
        if (ultimaLectura != null
                && ultimaLectura.getLecturaActual() != null) {

            return ultimaLectura.getLecturaActual();
        }

        if (suministro.getLecturaInicial() != null) {
            return suministro.getLecturaInicial();
        }

        return BigDecimal.ZERO;
    }

    private String obtenerEstadoInstalacion(
            Suministro suministro
    ) {
        if (suministro == null
                || suministro.getEstadoInstalacion() == null
                || suministro.getEstadoInstalacion().isBlank()) {

            return PENDIENTE_INSTALACION;
        }

        return suministro
                .getEstadoInstalacion()
                .trim()
                .toUpperCase();
    }

    private String obtenerMensajeEstado(
            boolean estaActivo,
            String estadoInstalacion
    ) {
        if (!estaActivo) {
            return "El cliente o suministro se encuentra "
                    + "desactivado. No se puede registrar lectura "
                    + "ni generar mantenimiento.";
        }

        if (INSTALADO.equalsIgnoreCase(
                estadoInstalacion
        )) {
            return "Suministro instalado. Puede registrar "
                    + "lectura normal o generar mantenimiento "
                    + "si no hubo consumo.";
        }

        if (PENDIENTE_INSTALACION.equalsIgnoreCase(
                estadoInstalacion
        )) {
            return "Este suministro aún no está instalado "
                    + "o fue suspendido. Solo se puede generar "
                    + "recibo por mantenimiento.";
        }

        return "Estado de suministro pendiente de revisión.";
    }

    private String obtenerNombreSector(
            Suministro suministro
    ) {
        if (suministro == null
                || suministro.getSector() == null) {
            return "-";
        }

        return suministro.getSector().getNombre() != null
                ? suministro.getSector().getNombre()
                : "-";
    }

    private String obtenerNombreCliente(
            Suministro suministro
    ) {
        if (suministro == null
                || suministro.getCliente() == null) {
            return "No disponible";
        }

        String nombres =
                suministro.getCliente().getNombres() != null
                        ? suministro.getCliente().getNombres()
                        : "";

        String apellidos =
                suministro.getCliente().getApellidos() != null
                        ? suministro.getCliente().getApellidos()
                        : "";

        String nombreCompleto =
                (nombres + " " + apellidos).trim();

        return nombreCompleto.isEmpty()
                ? "No disponible"
                : nombreCompleto;
    }

    private String obtenerDniCliente(
            Suministro suministro
    ) {
        if (suministro == null
                || suministro.getCliente() == null) {
            return "-";
        }

        return suministro.getCliente().getDni() != null
                ? suministro.getCliente().getDni()
                : "-";
    }
}