package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.CanalPagoRequest;
import com.jass.huacariz.dto.response.CanalPagoResponse;
import com.jass.huacariz.entity.CanalPago;
import com.jass.huacariz.repository.CanalPagoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CanalPagoService {

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
    public CanalPagoResponse actualizar(Integer id, CanalPagoRequest request){

        CanalPago canal = repository.findById(id)

                .orElseThrow(() -> new RuntimeException("Canal no encontrado"));

        canal.setTitular(request.getTitular());

        canal.setNumero(request.getNumero());

        canal.setBanco(request.getBanco());

        canal.setCuenta(request.getCuenta());

        canal.setCci(request.getCci());

        canal.setDescripcion(request.getDescripcion());

        canal.setQrUrl(request.getQrUrl());

        canal.setEstado(request.getEstado());

        canal.setFechaActualizacion(LocalDateTime.now());

        repository.save(canal);

        return convertir(canal);

    }

    private CanalPagoResponse convertir(CanalPago canal){

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