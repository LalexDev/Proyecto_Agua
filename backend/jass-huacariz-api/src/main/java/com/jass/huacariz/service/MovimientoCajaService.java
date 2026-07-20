package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.MovimientoCajaRequest;
import com.jass.huacariz.dto.response.MovimientoCajaResponse;
import com.jass.huacariz.dto.response.ResumenCajaResponse;
import com.jass.huacariz.entity.MovimientoCaja;
import com.jass.huacariz.repository.MovimientoCajaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import com.jass.huacariz.repository.PagoRepository;

@Service
@RequiredArgsConstructor
public class MovimientoCajaService {

    private static final String ESTADO_ACTIVO = "ACTIVO";
    private static final String ESTADO_ANULADO = "ANULADO";
    private static final String TIPO_EGRESO = "EGRESO";
    private static final String TIPO_INGRESO = "INGRESO";

    private final MovimientoCajaRepository repository;
    private final PagoRepository pagoRepository;

    @Transactional(readOnly = true)
    public List<MovimientoCajaResponse> listar() {
        return repository.findAllByOrderByFechaMovimientoDesc()
                .stream()
                .map(this::convertir)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MovimientoCajaResponse> listarActivos() {
        return repository.findByEstadoOrderByFechaMovimientoDesc(ESTADO_ACTIVO)
                .stream()
                .map(this::convertir)
                .toList();
    }

    @Transactional(readOnly = true)
    public ResumenCajaResponse resumen() {
        return ResumenCajaResponse.builder()
                .totalEgresos(repository.totalEgresosActivos())
                .totalIngresosManuales(repository.totalIngresosManualesActivos())
                .movimientosActivos(repository.countByEstado(ESTADO_ACTIVO))
                .build();
    }

    @Transactional
    public MovimientoCajaResponse crear(MovimientoCajaRequest request) {
        validar(request);

        String tipo = normalizarOpcional(request.getTipoMovimiento());

        if (tipo == null) {
            tipo = TIPO_EGRESO;
        }

        tipo = tipo.toUpperCase(Locale.ROOT);

        if (TIPO_EGRESO.equals(tipo)) {
            validarSaldoDisponible(request.getMonto());
        }
        MovimientoCaja movimiento = MovimientoCaja.builder()
                .tipoMovimiento(tipo)
                .categoria(normalizar(request.getCategoria()).toUpperCase(Locale.ROOT))
                .descripcion(normalizar(request.getDescripcion()))
                .monto(request.getMonto())
                .responsable(normalizarOpcional(request.getResponsable()))
                .comprobanteUrl(normalizarOpcional(request.getComprobanteUrl()))
                .fechaMovimiento(LocalDateTime.now())
                .estado(ESTADO_ACTIVO)
                .build();

        return convertir(repository.save(movimiento));
    }

    @Transactional
    public MovimientoCajaResponse anular(Integer id) {
        MovimientoCaja movimiento = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Movimiento de caja no encontrado."));

        if (ESTADO_ANULADO.equalsIgnoreCase(movimiento.getEstado())) {
            throw new RuntimeException("Este movimiento ya está anulado.");
        }

        movimiento.setEstado(ESTADO_ANULADO);

        return convertir(repository.save(movimiento));
    }

    private void validar(MovimientoCajaRequest request) {
        if (request == null) {
            throw new RuntimeException("Los datos del movimiento son obligatorios.");
        }

        if (request.getCategoria() == null || request.getCategoria().isBlank()) {
            throw new RuntimeException("La categoría es obligatoria.");
        }

        if (request.getDescripcion() == null || request.getDescripcion().isBlank()) {
            throw new RuntimeException("La descripción es obligatoria.");
        }

        if (request.getMonto() == null || request.getMonto().compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("El monto debe ser mayor a 0.");
        }

        String tipo = normalizarOpcional(request.getTipoMovimiento());

        if (tipo != null) {
            tipo = tipo.toUpperCase(Locale.ROOT);

            if (!TIPO_EGRESO.equals(tipo) && !TIPO_INGRESO.equals(tipo)) {
                throw new RuntimeException("Tipo de movimiento no permitido.");
            }
        }
    }

    private void validarSaldoDisponible(BigDecimal montoEgreso) {
        BigDecimal saldoDisponible = calcularSaldoDisponible();

        if (montoEgreso.compareTo(saldoDisponible) > 0) {
            throw new RuntimeException(
                    "Saldo insuficiente. Disponible: S/ "
                            + saldoDisponible
                            + ". No puede registrar un gasto/retiro de S/ "
                            + montoEgreso
            );
        }
    }

    private BigDecimal calcularSaldoDisponible() {
        BigDecimal pagosConfirmados = pagoRepository.totalPagosConfirmados();
        BigDecimal ingresosManuales = repository.totalIngresosManualesActivos();
        BigDecimal egresos = repository.totalEgresosActivos();

        return pagosConfirmados
                .add(ingresosManuales)
                .subtract(egresos);
    }
    private MovimientoCajaResponse convertir(MovimientoCaja movimiento) {
        return MovimientoCajaResponse.builder()
                .id(movimiento.getId())
                .tipoMovimiento(movimiento.getTipoMovimiento())
                .categoria(movimiento.getCategoria())
                .descripcion(movimiento.getDescripcion())
                .monto(movimiento.getMonto())
                .responsable(movimiento.getResponsable())
                .comprobanteUrl(movimiento.getComprobanteUrl())
                .fechaMovimiento(movimiento.getFechaMovimiento())
                .estado(movimiento.getEstado())
                .build();
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
}