package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.ClienteRequest;
import com.jass.huacariz.dto.request.SuministroRequest;
import com.jass.huacariz.dto.response.ClienteResponse;
import com.jass.huacariz.dto.response.SuministroResponse;
import com.jass.huacariz.entity.Cliente;
import com.jass.huacariz.entity.Role;
import com.jass.huacariz.entity.Sector;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.entity.Usuario;
import com.jass.huacariz.repository.ClienteRepository;
import com.jass.huacariz.repository.LecturaRepository;
import com.jass.huacariz.repository.RoleRepository;
import com.jass.huacariz.repository.SectorRepository;
import com.jass.huacariz.repository.SuministroRepository;
import com.jass.huacariz.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository clienteRepository;
    private final UsuarioRepository usuarioRepository;
    private final RoleRepository roleRepository;
    private final SectorRepository sectorRepository;
    private final SuministroRepository suministroRepository;
    private final LecturaRepository lecturaRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String PASSWORD_INICIAL_CLIENTE = "cliente123";
    private static final String INSTALADO = "INSTALADO";
    private static final String PENDIENTE_INSTALACION = "PENDIENTE_INSTALACION";

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
                .debeCambiarPassword(true)
                .fechaCreacion(LocalDateTime.now())
                .build();

        usuario = usuarioRepository.save(usuario);

        Cliente cliente = Cliente.builder()
                .usuario(usuario)
                .dni(request.getDni())
                .nombres(request.getNombres())
                .apellidos(request.getApellidos())
                .telefono(limpiarOpcional(request.getTelefono()))
                .correo(limpiarOpcional(request.getCorreo()))
                .estado(request.getEstado() != null ? request.getEstado() : true)
                .fechaRegistro(LocalDateTime.now())
                .build();

        cliente = clienteRepository.save(cliente);

        for (SuministroRequest suministroRequest : request.getSuministros()) {
            crearSuministroParaCliente(cliente, suministroRequest);
        }

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, usuario, suministros);
    }

    @Transactional(readOnly = true)
    public List<ClienteResponse> listarClientes() {
        List<Cliente> clientes = clienteRepository.findAllWithUsuario();

        if (clientes.isEmpty()) {
            return List.of();
        }

        List<Integer> clienteIds = clientes.stream()
                .map(Cliente::getId)
                .toList();

        Map<Integer, List<Suministro>> suministrosPorCliente = suministroRepository
                .findByClienteIdInWithSector(clienteIds)
                .stream()
                .collect(Collectors.groupingBy(suministro -> suministro.getCliente().getId()));

        return clientes.stream()
                .map(cliente -> convertirAResponse(
                        cliente,
                        cliente.getUsuario(),
                        suministrosPorCliente.getOrDefault(cliente.getId(), List.of())
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public ClienteResponse obtenerClientePorId(Integer id) {
        Cliente cliente = clienteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + id));

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, cliente.getUsuario(), suministros);
    }

    @Transactional(readOnly = true)
    public ClienteResponse obtenerClientePorDni(String dni) {
        Cliente cliente = clienteRepository.findByDni(dni)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con DNI: " + dni));

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, cliente.getUsuario(), suministros);
    }

    @Transactional
    public ClienteResponse actualizarCliente(Integer clienteId, ClienteRequest request) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        String nuevoDni = limpiarTexto(request.getDni());
        String nombres = limpiarTexto(request.getNombres());
        String apellidos = limpiarTexto(request.getApellidos());

        if (nuevoDni == null || nuevoDni.length() != 8) {
            throw new RuntimeException("Ingrese un DNI válido de 8 dígitos.");
        }

        if (nombres == null || nombres.isBlank()) {
            throw new RuntimeException("Los nombres son obligatorios.");
        }

        if (apellidos == null || apellidos.isBlank()) {
            throw new RuntimeException("Los apellidos son obligatorios.");
        }

        Optional<Cliente> clienteConDni = clienteRepository.findByDni(nuevoDni);

        if (clienteConDni.isPresent() && !clienteConDni.get().getId().equals(cliente.getId())) {
            throw new RuntimeException("Ya existe otro cliente con el DNI: " + nuevoDni);
        }

        Usuario usuario = cliente.getUsuario();

        if (usuario != null && !nuevoDni.equals(usuario.getCodigoUsuario())) {
            Optional<Usuario> usuarioConCodigo = usuarioRepository.findByCodigoUsuario(nuevoDni);

            if (usuarioConCodigo.isPresent() && !usuarioConCodigo.get().getId().equals(usuario.getId())) {
                throw new RuntimeException("Ya existe otro usuario con el código: " + nuevoDni);
            }

            usuario.setCodigoUsuario(nuevoDni);
            usuarioRepository.save(usuario);
        }

        cliente.setDni(nuevoDni);
        cliente.setNombres(nombres);
        cliente.setApellidos(apellidos);
        cliente.setTelefono(limpiarTexto(request.getTelefono()));
        cliente.setCorreo(limpiarTexto(request.getCorreo()));

        if (request.getEstado() != null) {
            cliente.setEstado(request.getEstado());

            if (usuario != null) {
                usuario.setEstado(request.getEstado());
                usuarioRepository.save(usuario);
            }
        }

        cliente = clienteRepository.save(cliente);

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, cliente.getUsuario(), suministros);
    }

    @Transactional(readOnly = true)
    public List<SuministroResponse> listarSuministrosPorCliente(Integer clienteId) {
        if (!clienteRepository.existsById(clienteId)) {
            throw new RuntimeException("No existe el cliente con ID: " + clienteId);
        }

        return suministroRepository.findByClienteId(clienteId)
                .stream()
                .map(this::convertirSuministroAResponse)
                .toList();
    }

    @Transactional
    public SuministroResponse agregarSuministro(Integer clienteId, SuministroRequest request) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        if (!Boolean.TRUE.equals(cliente.getEstado())) {
            throw new RuntimeException("No se puede agregar suministro porque el cliente está desactivado.");
        }

        Suministro suministro = crearSuministroParaCliente(cliente, request);

        return convertirSuministroAResponse(suministro);
    }

    @Transactional
    public SuministroResponse actualizarSuministro(
            Integer clienteId,
            Integer suministroId,
            SuministroRequest request
    ) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        Suministro suministro = obtenerSuministroDelCliente(cliente, suministroId);

        Sector sector = sectorRepository.findById(request.getIdSector())
                .orElseThrow(() -> new RuntimeException("No existe el sector con ID: " + request.getIdSector()));

        boolean tieneLecturas = lecturaRepository.existsBySuministroId(suministro.getId());

        BigDecimal lecturaNueva = request.getLecturaInicial() != null
                ? request.getLecturaInicial()
                : BigDecimal.ZERO;

        if (tieneLecturas && suministro.getLecturaInicial() != null
                && lecturaNueva.compareTo(suministro.getLecturaInicial()) != 0) {
            throw new RuntimeException("No se puede cambiar la lectura inicial porque el suministro ya tiene lecturas registradas.");
        }

        suministro.setSector(sector);
        suministro.setDireccionSuministro(request.getDireccionSuministro());
        suministro.setReferencia(request.getReferencia());
        suministro.setAliasSuministro(request.getAliasSuministro());

        if (!tieneLecturas) {
            suministro.setLecturaInicial(lecturaNueva);
        }

        suministro = suministroRepository.save(suministro);

        return convertirSuministroAResponse(suministro);
    }

    @Transactional
    public void eliminarSuministro(Integer clienteId, Integer suministroId) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        Suministro suministro = obtenerSuministroDelCliente(cliente, suministroId);

        List<Suministro> suministrosCliente = suministroRepository.findByClienteId(cliente.getId());

        if (suministrosCliente.size() <= 1) {
            throw new RuntimeException("No se puede eliminar el único suministro del cliente. Puede suspenderlo si ya no se usa.");
        }

        if (lecturaRepository.existsBySuministroId(suministro.getId())) {
            throw new RuntimeException("No se puede eliminar este suministro porque ya tiene lecturas o recibos. Debe suspenderlo.");
        }

        suministroRepository.delete(suministro);
    }

    @Transactional
    public ClienteResponse cambiarEstadoCliente(Integer clienteId, Boolean estado) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        boolean estadoFinal = Boolean.TRUE.equals(estado);

        cliente.setEstado(estadoFinal);

        Usuario usuario = cliente.getUsuario();

        if (usuario != null) {
            usuario.setEstado(estadoFinal);
            usuarioRepository.save(usuario);
        }

        List<Suministro> suministros = suministroRepository.findByClienteId(cliente.getId());

        for (Suministro suministro : suministros) {
            suministro.setEstado(estadoFinal);

            if (suministro.getEstadoInstalacion() == null || suministro.getEstadoInstalacion().isBlank()) {
                suministro.setEstadoInstalacion(PENDIENTE_INSTALACION);
            }

            suministroRepository.save(suministro);
        }

        cliente = clienteRepository.save(cliente);

        suministros = suministroRepository.findByClienteId(cliente.getId());

        return convertirAResponse(cliente, cliente.getUsuario(), suministros);
    }

    @Transactional
    public SuministroResponse cambiarEstadoSuministro(Integer clienteId, Integer suministroId, Boolean estado) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        Suministro suministro = obtenerSuministroDelCliente(cliente, suministroId);

        if (!Boolean.TRUE.equals(cliente.getEstado())) {
            throw new RuntimeException("No se puede modificar el suministro porque el cliente está desactivado.");
        }

        if (Boolean.TRUE.equals(estado)) {
            suministro.setEstado(true);
            suministro.setEstadoInstalacion(INSTALADO);
        } else {
            suministro.setEstado(true);
            suministro.setEstadoInstalacion(PENDIENTE_INSTALACION);
        }

        suministro = suministroRepository.save(suministro);

        return convertirSuministroAResponse(suministro);
    }

    @Transactional
    public SuministroResponse cambiarEstadoInstalacionSuministro(
            Integer clienteId,
            Integer suministroId,
            String estadoInstalacion
    ) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        Suministro suministro = obtenerSuministroDelCliente(cliente, suministroId);

        if (!Boolean.TRUE.equals(cliente.getEstado())) {
            throw new RuntimeException("No se puede modificar el suministro porque el cliente está desactivado.");
        }

        String estadoFinal = estadoInstalacion == null ? "" : estadoInstalacion.trim().toUpperCase();

        if (!estadoFinal.equals(INSTALADO) && !estadoFinal.equals(PENDIENTE_INSTALACION)) {
            throw new RuntimeException("Estado de instalación no válido. Use INSTALADO o PENDIENTE_INSTALACION.");
        }

        suministro.setEstado(true);
        suministro.setEstadoInstalacion(estadoFinal);

        suministro = suministroRepository.save(suministro);

        return convertirSuministroAResponse(suministro);
    }

    @Transactional
    public String restablecerPasswordCliente(Integer clienteId) {
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("No existe el cliente con ID: " + clienteId));

        Usuario usuario = cliente.getUsuario();

        if (usuario == null) {
            throw new RuntimeException("El cliente no tiene usuario asociado.");
        }

        usuario.setPasswordHash(passwordEncoder.encode(PASSWORD_INICIAL_CLIENTE));
        usuario.setDebeCambiarPassword(true);
        usuarioRepository.save(usuario);

        return PASSWORD_INICIAL_CLIENTE;
    }

    private Suministro crearSuministroParaCliente(Cliente cliente, SuministroRequest request) {
        Sector sector = sectorRepository.findById(request.getIdSector())
                .orElseThrow(() -> new RuntimeException("No existe el sector con ID: " + request.getIdSector()));

        Suministro suministro = Suministro.builder()
                .cliente(cliente)
                .sector(sector)
                .codigoSuministro(generarCodigoSuministro())
                .direccionSuministro(request.getDireccionSuministro())
                .referencia(request.getReferencia())
                .aliasSuministro(request.getAliasSuministro())
                .lecturaInicial(request.getLecturaInicial() != null ? request.getLecturaInicial() : BigDecimal.ZERO)
                .estado(true)
                .estadoInstalacion(PENDIENTE_INSTALACION)
                .fechaRegistro(LocalDateTime.now())
                .build();

        return suministroRepository.save(suministro);
    }

    private Suministro obtenerSuministroDelCliente(Cliente cliente, Integer suministroId) {
        Suministro suministro = suministroRepository.findById(suministroId)
                .orElseThrow(() -> new RuntimeException("No existe el suministro con ID: " + suministroId));

        if (!suministro.getCliente().getId().equals(cliente.getId())) {
            throw new RuntimeException("El suministro no pertenece al cliente seleccionado.");
        }

        return suministro;
    }

    private ClienteResponse convertirAResponse(Cliente cliente, Usuario usuario, List<Suministro> suministros) {
        List<SuministroResponse> suministrosResponse = suministros.stream()
                .map(this::convertirSuministroAResponse)
                .toList();

        return ClienteResponse.builder()
                .id(cliente.getId())
                .dni(cliente.getDni())
                .nombres(cliente.getNombres())
                .apellidos(cliente.getApellidos())
                .telefono(cliente.getTelefono())
                .correo(cliente.getCorreo())
                .estado(cliente.getEstado())
                .codigoUsuario(usuario != null ? usuario.getCodigoUsuario() : cliente.getDni())
                .passwordInicial(PASSWORD_INICIAL_CLIENTE)
                .suministros(suministrosResponse)
                .build();
    }

    private SuministroResponse convertirSuministroAResponse(Suministro suministro) {
        return SuministroResponse.builder()
                .id(suministro.getId())
                .codigoSuministro(suministro.getCodigoSuministro())
                .idSector(suministro.getSector().getId())
                .nombreSector(suministro.getSector().getNombre())
                .direccionSuministro(suministro.getDireccionSuministro())
                .referencia(suministro.getReferencia())
                .aliasSuministro(suministro.getAliasSuministro())
                .lecturaInicial(suministro.getLecturaInicial())
                .estado(suministro.getEstado())
                .estadoInstalacion(
                        suministro.getEstadoInstalacion() != null && !suministro.getEstadoInstalacion().isBlank()
                                ? suministro.getEstadoInstalacion()
                                : PENDIENTE_INSTALACION
                )
                .build();
    }

    private String generarCodigoSuministro() {
        return "SUM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private String limpiarTexto(String value) {
        return value == null ? null : value.trim();
    }

    private String limpiarOpcional(String valor) {
    if (valor == null || valor.trim().isBlank()) {
        return null;
    }

    return valor.trim();
    }
}