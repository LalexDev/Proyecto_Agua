package com.jass.huacariz.repository;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.entity.Lectura;
import com.jass.huacariz.entity.Recibo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.Comparator;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class AdminLecturaRepository {

    @PersistenceContext
    private EntityManager entityManager;

    public List<HistorialLecturaResponse> listarHistorial() {
        List<Lectura> lecturas = entityManager.createQuery(
                """
                SELECT l
                FROM Lectura l
                JOIN FETCH l.suministro s
                JOIN FETCH s.cliente c
                JOIN FETCH s.sector sec
                ORDER BY l.anio DESC, l.mes DESC, l.id DESC
                """,
                Lectura.class
        ).getResultList();

        return lecturas.stream()
                .map(this::convertir)
                .sorted(
                        Comparator
                                .comparing(HistorialLecturaResponse::getAnio, Comparator.nullsLast(Comparator.reverseOrder()))
                                .thenComparing(HistorialLecturaResponse::getMes, Comparator.nullsLast(Comparator.reverseOrder()))
                                .thenComparing(HistorialLecturaResponse::getIdLectura, Comparator.nullsLast(Comparator.reverseOrder()))
                )
                .toList();
    }

    private HistorialLecturaResponse convertir(Lectura lectura) {
        Recibo recibo = buscarReciboPorLectura(lectura);

        String nombreCliente = "";
        if (lectura.getSuministro() != null && lectura.getSuministro().getCliente() != null) {
            String nombres = lectura.getSuministro().getCliente().getNombres() != null
                    ? lectura.getSuministro().getCliente().getNombres()
                    : "";

            String apellidos = lectura.getSuministro().getCliente().getApellidos() != null
                    ? lectura.getSuministro().getCliente().getApellidos()
                    : "";

            nombreCliente = (nombres + " " + apellidos).trim();
        }

        String dniCliente = lectura.getSuministro() != null
                && lectura.getSuministro().getCliente() != null
                && lectura.getSuministro().getCliente().getDni() != null
                ? lectura.getSuministro().getCliente().getDni()
                : "-";

        String sector = lectura.getSuministro() != null
                && lectura.getSuministro().getSector() != null
                && lectura.getSuministro().getSector().getNombre() != null
                ? lectura.getSuministro().getSector().getNombre()
                : "-";

        String codigoSuministro = lectura.getSuministro() != null
                ? lectura.getSuministro().getCodigoSuministro()
                : "-";

        return new HistorialLecturaResponse(
                lectura.getId(),
                codigoSuministro,
                lectura.getSuministro() != null ? lectura.getSuministro().getAliasSuministro() : "-",
                lectura.getSuministro() != null ? lectura.getSuministro().getDireccionSuministro() : "-",
                nombreCliente.isBlank() ? "No disponible" : nombreCliente,
                dniCliente,
                sector,
                lectura.getAnio(),
                lectura.getMes(),
                lectura.getLecturaAnterior(),
                lectura.getLecturaActual(),
                lectura.getConsumoM3(),
                recibo != null ? recibo.getCodigoRecibo() : "-",
                recibo != null ? recibo.getTotal() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getEstadoRecibo() : "PENDIENTE",
                lectura.getFechaLectura(),

                lectura.getCambioMedidor(),
                lectura.getLecturaInicialNuevoMedidor(),
                lectura.getObservacionCambioMedidor(),
                lectura.getConsumoInusual(),

                recibo != null ? recibo.getSubtotalAgua() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getCargoMantenimiento() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getCargoLector() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getCargoOtros() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getMora() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getTotal() : java.math.BigDecimal.ZERO,
                recibo != null ? recibo.getFechaEmision() : null,
                recibo != null ? recibo.getFechaVencimiento() : null,
                recibo != null ? generarCodigoBarras(recibo) : "-"
        );
    }

    private Recibo buscarReciboPorLectura(Lectura lectura) {
        List<Recibo> recibos = entityManager.createQuery(
                        """
                        SELECT r
                        FROM Recibo r
                        WHERE r.lectura.id = :lecturaId
                        """,
                        Recibo.class
                )
                .setParameter("lecturaId", lectura.getId())
                .getResultList();

        return recibos.isEmpty() ? null : recibos.get(0);
    }

    private String generarCodigoBarras(Recibo recibo) {
        if (recibo == null) {
            return "-";
        }

        String codigoRecibo = recibo.getCodigoRecibo() != null ? recibo.getCodigoRecibo() : "";
        String codigoSuministro = recibo.getSuministro() != null && recibo.getSuministro().getCodigoSuministro() != null
                ? recibo.getSuministro().getCodigoSuministro()
                : "";

        return codigoRecibo + "-" + codigoSuministro;
    }
}