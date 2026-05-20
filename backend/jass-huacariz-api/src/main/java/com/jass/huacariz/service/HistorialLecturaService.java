package com.jass.huacariz.service;

import com.jass.huacariz.dto.response.HistorialLecturaResponse;
import com.jass.huacariz.repository.AdminLecturaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class HistorialLecturaService {

    private final AdminLecturaRepository adminLecturaRepository;

    public List<HistorialLecturaResponse> listarHistorial() {
        return adminLecturaRepository.listarHistorial();
    }
}