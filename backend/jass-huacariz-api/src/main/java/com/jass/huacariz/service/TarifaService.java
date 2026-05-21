package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.TarifaRequest;
import com.jass.huacariz.dto.response.TarifaResponse;
import com.jass.huacariz.entity.Tarifa;
import com.jass.huacariz.repository.TarifaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TarifaService {

    private final TarifaRepository tarifaRepository;

    @Transactional(readOnly = true)
    public List<TarifaResponse> listarTarifas() {
        return tarifaRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public TarifaResponse obtenerTarifaPorId(Integer id) {
        Tarifa tarifa = tarifaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe la tarifa con ID: " + id));

        return convertirAResponse(tarifa);
    }

    @Transactional
    public TarifaResponse registrarTarifa(TarifaRequest request) {
        validarTarifa(request);

        Tarifa tarifa = new Tarifa();
        tarifa.setNombre(request.getNombre().trim());
        tarifa.setConsumoDesde(request.getConsumoDesde());
        tarifa.setConsumoHasta(request.getConsumoHasta());
        tarifa.setPrecioM3(request.getPrecioM3());
        tarifa.setEstado(request.getEstado() != null ? request.getEstado() : true);

        asignarFechaRegistroSiExiste(tarifa);

        tarifa = tarifaRepository.save(tarifa);

        return convertirAResponse(tarifa);
    }

    @Transactional
    public TarifaResponse actualizarTarifa(Integer id, TarifaRequest request) {
        validarTarifa(request);

        Tarifa tarifa = tarifaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe la tarifa con ID: " + id));

        tarifa.setNombre(request.getNombre().trim());
        tarifa.setConsumoDesde(request.getConsumoDesde());
        tarifa.setConsumoHasta(request.getConsumoHasta());
        tarifa.setPrecioM3(request.getPrecioM3());
        tarifa.setEstado(request.getEstado() != null ? request.getEstado() : tarifa.getEstado());

        tarifa = tarifaRepository.save(tarifa);

        return convertirAResponse(tarifa);
    }

    @Transactional
    public TarifaResponse cambiarEstadoTarifa(Integer id, Boolean estado) {
        Tarifa tarifa = tarifaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe la tarifa con ID: " + id));

        tarifa.setEstado(estado);
        tarifa = tarifaRepository.save(tarifa);

        return convertirAResponse(tarifa);
    }

    @Transactional
    public void eliminarTarifa(Integer id) {
        Tarifa tarifa = tarifaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe la tarifa con ID: " + id));

        tarifa.setEstado(false);
        tarifaRepository.save(tarifa);
    }

    private void validarTarifa(TarifaRequest request) {
        if (request.getNombre() == null || request.getNombre().trim().isEmpty()) {
            throw new RuntimeException("Ingrese el nombre de la tarifa.");
        }

        if (request.getConsumoDesde() == null) {
            throw new RuntimeException("Ingrese el consumo desde.");
        }

        if (request.getConsumoDesde().doubleValue() < 0) {
            throw new RuntimeException("El consumo desde no puede ser negativo.");
        }

        if (request.getConsumoHasta() != null &&
                request.getConsumoHasta().doubleValue() < request.getConsumoDesde().doubleValue()) {
            throw new RuntimeException("El consumo hasta no puede ser menor al consumo desde.");
        }

        if (request.getPrecioM3() == null || request.getPrecioM3().doubleValue() <= 0) {
            throw new RuntimeException("El precio por m³ debe ser mayor a cero.");
        }
    }

    private TarifaResponse convertirAResponse(Tarifa tarifa) {
        return TarifaResponse.builder()
                .id(tarifa.getId())
                .nombreTarifa(tarifa.getNombre())
                .nombre(tarifa.getNombre())
                .consumoDesde(tarifa.getConsumoDesde())
                .consumoHasta(tarifa.getConsumoHasta())
                .precioM3(tarifa.getPrecioM3())
                .estado(tarifa.getEstado())
                .build();
    }

    private void asignarFechaRegistroSiExiste(Tarifa tarifa) {
        try {
            Method metodo = Tarifa.class.getMethod("setFechaRegistro", LocalDateTime.class);
            metodo.invoke(tarifa, LocalDateTime.now());
        } catch (Exception ignored) {
        }
    }
}