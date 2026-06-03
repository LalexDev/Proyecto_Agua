package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.SectorRequest;
import com.jass.huacariz.dto.response.SectorResponse;
import com.jass.huacariz.entity.Sector;
import com.jass.huacariz.repository.SectorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SectorService {

    private final SectorRepository sectorRepository;

    public List<SectorResponse> listarSectores() {
        return sectorRepository.findAllByOrderByNombreAsc()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<SectorResponse> listarSectoresActivos() {
        return sectorRepository.findByEstadoTrueOrderByNombreAsc()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public SectorResponse registrarSector(SectorRequest request) {
        String nombre = normalizarNombre(request.getNombre());

        if (sectorRepository.existsByNombreIgnoreCase(nombre)) {
            throw new RuntimeException("Ya existe un sector con ese nombre.");
        }

        Sector sector = Sector.builder()
                .nombre(nombre)
                .descripcion(limpiar(request.getDescripcion()))
                .estado(request.getEstado() == null ? true : request.getEstado())
                .build();

        return toResponse(sectorRepository.save(sector));
    }

    public SectorResponse actualizarSector(Integer id, SectorRequest request) {
        Sector sector = sectorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el sector seleccionado."));

        String nombre = normalizarNombre(request.getNombre());

        if (!sector.getNombre().equalsIgnoreCase(nombre)
                && sectorRepository.existsByNombreIgnoreCase(nombre)) {
            throw new RuntimeException("Ya existe otro sector con ese nombre.");
        }

        sector.setNombre(nombre);
        sector.setDescripcion(limpiar(request.getDescripcion()));
        sector.setEstado(request.getEstado() == null ? sector.getEstado() : request.getEstado());

        return toResponse(sectorRepository.save(sector));
    }

    public SectorResponse cambiarEstado(Integer id, Boolean estado) {
        Sector sector = sectorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el sector seleccionado."));

        sector.setEstado(Boolean.TRUE.equals(estado));

        return toResponse(sectorRepository.save(sector));
    }

    private SectorResponse toResponse(Sector sector) {
        return SectorResponse.builder()
                .id(sector.getId())
                .nombre(sector.getNombre())
                .descripcion(sector.getDescripcion())
                .estado(sector.getEstado())
                .build();
    }

    private String normalizarNombre(String valor) {
        return valor == null ? "" : valor.trim().toUpperCase();
    }

    private String limpiar(String valor) {
        return valor == null ? "" : valor.trim();
    }
}