package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.SectorRequest;
import com.jass.huacariz.dto.response.SectorResponse;
import com.jass.huacariz.entity.Sector;
import com.jass.huacariz.repository.SectorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SectorService {

    private final SectorRepository sectorRepository;

    @Transactional(readOnly = true)
    public List<SectorResponse> listarSectores() {
        return sectorRepository.findAll()
                .stream()
                .map(this::convertirAResponse)
                .toList();
    }

    @Transactional
    public SectorResponse registrarSector(SectorRequest request) {
        if (sectorRepository.existsByNombre(request.getNombre())) {
            throw new RuntimeException("Ya existe un sector con el nombre: " + request.getNombre());
        }

        Sector sector = Sector.builder()
                .nombre(request.getNombre())
                .descripcion(request.getDescripcion())
                .estado(request.getEstado() != null ? request.getEstado() : true)
                .build();

        sector = sectorRepository.save(sector);

        return convertirAResponse(sector);
    }

    private SectorResponse convertirAResponse(Sector sector) {
        return SectorResponse.builder()
                .id(sector.getId())
                .nombre(sector.getNombre())
                .descripcion(sector.getDescripcion())
                .estado(sector.getEstado())
                .build();
    }
}