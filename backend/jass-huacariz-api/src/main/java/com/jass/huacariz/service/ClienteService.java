package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.ClienteRequest;
import com.jass.huacariz.dto.request.SuministroRequest;
import com.jass.huacariz.dto.response.ClienteResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.entity.*;
import com.jass.huacariz.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository clienteRepository;
    private final UsuarioRepository usuarioRepository;
    private final RoleRepository roleRepository;
    private final SectorRepository sectorRepository;
    private final SuministroRepository suministroRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String PASSWORD_INICIAL_CLIENTE = "cliente123";

    @Transactional
    public ClienteResponse registrarCliente(ClienteRequest request) {

        if (clienteRepository.existsByDni(request.getDni())) {
            throw new RuntimeException("Ya existe un cliente con el DNI: " + request.getDni());
        }

        if (usuarioRepository.existsByCodigoUsuario(request.getDni())) {
            throw new RuntimeException("Ya existe un usuario con el código: " + request.getDni());
        }

        Role rolCliente = roleRepository.findByNombre("CLIENTE")
                .orElseThrow(() -> new RuntimeException("No existe el rol CLIENTE en la base de datos"));

        Usuario usuario = Usuario.builder()
                .codigoUsuario(request.getDni())
                .passwordHash(passwordEncoder.encode(PASSWORD_INICIAL_CLIENTE))
                .rol(rolCliente)
                .estado(true)
                .fechaCreacion(LocalDateTime.now())
                .build();

        usuario = usuarioRepository.save(usuario);

        Cliente cliente = Cliente.builder()
                .usuario(usuario)
                .dni(request.getDni())
                .nombres(request.getNombres())
                .apellidos(request.getApellidos())
                .telefono(request.getTelefono())
                .correo(request.getCorreo())
                .estado(request.getEstado() != null ? request.getEstado() : true)
                .fechaRegistro(LocalDateTime.now())
                .build();

        cliente = clienteRepository.save(cliente);

        for (SuministroRequest suministroRequest : request.getSuministros()) {
            Sector sector = sectorRepository.findById(suministroRequest.getIdSector())
                    .orElseThrow(() -> new RuntimeException("No existe el sector con ID: " + suministroRequest.getIdSector()));

            Suministro suministro = Suministro.builder()
                    .cliente(cliente)
                    .sector(sector)
                    .codigoSuministro(generarCodigoSuministro())
                    .direccionSuministro(suministroRequest.getDireccionSuministro())
                    .referencia(suministroRequest.getReferencia())
                    .aliasSuministro(suministroRequest.getAliasSuministro())
                    .lecturaInicial(suministroRequest.getLecturaInicial())
                    .estado(true)
                    .fechaRegistro(LocalDateTime.now())
                    .build();

            suministroRepository.save(suministro);
        }

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, usuario, suministros);
    }

    private ClienteResponse convertirAResponse(Cliente cliente, Usuario usuario, List<Suministro> suministros) {
        List<SuministroResponse> suministrosResponse = suministros.stream()
                .map(suministro -> SuministroResponse.builder()
                        .id(suministro.getId())
                        .codigoSuministro(suministro.getCodigoSuministro())
                        .idSector(suministro.getSector().getId())
                        .nombreSector(suministro.getSector().getNombre())
                        .direccionSuministro(suministro.getDireccionSuministro())
                        .referencia(suministro.getReferencia())
                        .aliasSuministro(suministro.getAliasSuministro())
                        .lecturaInicial(suministro.getLecturaInicial())
                        .estado(suministro.getEstado())
                        .build())
                .toList();

        return ClienteResponse.builder()
                .id(cliente.getId())
                .dni(cliente.getDni())
                .nombres(cliente.getNombres())
                .apellidos(cliente.getApellidos())
                .telefono(cliente.getTelefono())
                .correo(cliente.getCorreo())
                .estado(cliente.getEstado())
                .codigoUsuario(usuario.getCodigoUsuario())
                .passwordInicial(PASSWORD_INICIAL_CLIENTE)
                .suministros(suministrosResponse)
                .build();
    }

    private String generarCodigoSuministro() {
        return "SUM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}