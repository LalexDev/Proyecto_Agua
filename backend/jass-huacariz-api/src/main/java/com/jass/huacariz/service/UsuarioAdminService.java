package com.jass.huacariz.service;

import com.jass.huacariz.dto.request.LecturadorRequest;
import com.jass.huacariz.dto.response.LecturadorResponse;
import com.jass.huacariz.entity.Lecturador;
import com.jass.huacariz.entity.Role;
import com.jass.huacariz.entity.Usuario;
import com.jass.huacariz.repository.LecturadorRepository;
import com.jass.huacariz.repository.RoleRepository;
import com.jass.huacariz.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UsuarioAdminService {

    private final UsuarioRepository usuarioRepository;
    private final RoleRepository roleRepository;
    private final LecturadorRepository lecturadorRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<LecturadorResponse> listarLecturadores() {
        return lecturadorRepository.findAllByOrderByNombresAscApellidosAsc()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public LecturadorResponse obtenerLecturadorPorId(Integer id) {
        Lecturador lecturador = buscarLecturador(id);
        return toResponse(lecturador);
    }

    @Transactional
    public LecturadorResponse registrarLecturador(LecturadorRequest request) {
        validarLecturador(request, true);

        String codigoUsuario = request.getCodigoUsuario().trim().toLowerCase();
        String dni = request.getDni().trim();

        if (usuarioRepository.existsByCodigoUsuario(codigoUsuario)) {
            throw new RuntimeException("Ya existe un usuario con el código: " + codigoUsuario);
        }

        if (lecturadorRepository.existsByDni(dni)) {
            throw new RuntimeException("Ya existe un lecturador registrado con el DNI: " + dni);
        }

        Role rolLecturador = roleRepository.findByNombre("LECTURADOR")
                .orElseGet(() -> roleRepository.save(
                        Role.builder()
                                .nombre("LECTURADOR")
                                .build()
                ));

        String passwordInicial = request.getPassword().trim();
        Boolean estado = request.getEstado() == null ? true : request.getEstado();

        Usuario usuario = Usuario.builder()
                .codigoUsuario(codigoUsuario)
                .passwordHash(passwordEncoder.encode(passwordInicial))
                .rol(rolLecturador)
                .estado(estado)
                .fechaCreacion(LocalDateTime.now())
                .build();

        usuario = usuarioRepository.save(usuario);

        Lecturador lecturador = Lecturador.builder()
                .dni(dni)
                .nombres(request.getNombres().trim())
                .apellidos(request.getApellidos().trim())
                .telefono(limpiarTexto(request.getTelefono()))
                .correo(limpiarTexto(request.getCorreo()))
                .sectorAsignado(limpiarTexto(request.getSectorAsignado()))
                .estado(estado)
                .fechaCreacion(LocalDateTime.now())
                .usuario(usuario)
                .build();

        lecturador = lecturadorRepository.save(lecturador);

        return toResponse(lecturador, passwordInicial);
    }

    @Transactional
    public LecturadorResponse actualizarLecturador(Integer id, LecturadorRequest request) {
        validarLecturador(request, false);

        Lecturador lecturador = buscarLecturador(id);
        Usuario usuario = lecturador.getUsuario();

        String dni = request.getDni().trim();
        String codigoUsuario = request.getCodigoUsuario().trim().toLowerCase();

        if (lecturadorRepository.existsByDniAndIdNot(dni, id)) {
            throw new RuntimeException("Ya existe otro lecturador con el DNI: " + dni);
        }

        usuarioRepository.findByCodigoUsuario(codigoUsuario)
                .ifPresent(usuarioExistente -> {
                    if (!usuarioExistente.getId().equals(usuario.getId())) {
                        throw new RuntimeException("Ya existe otro usuario con el código: " + codigoUsuario);
                    }
                });

        Boolean estado = request.getEstado() == null ? true : request.getEstado();

        usuario.setCodigoUsuario(codigoUsuario);
        usuario.setEstado(estado);

        if (request.getPassword() != null && !request.getPassword().trim().isBlank()) {
            if (request.getPassword().trim().length() < 6) {
                throw new RuntimeException("La nueva contraseña debe tener mínimo 6 caracteres.");
            }

            usuario.setPasswordHash(passwordEncoder.encode(request.getPassword().trim()));
        }

        usuarioRepository.save(usuario);

        lecturador.setDni(dni);
        lecturador.setNombres(request.getNombres().trim());
        lecturador.setApellidos(request.getApellidos().trim());
        lecturador.setTelefono(limpiarTexto(request.getTelefono()));
        lecturador.setCorreo(limpiarTexto(request.getCorreo()));
        lecturador.setSectorAsignado(limpiarTexto(request.getSectorAsignado()));
        lecturador.setEstado(estado);

        lecturador = lecturadorRepository.save(lecturador);

        return toResponse(lecturador);
    }

    @Transactional
    public LecturadorResponse cambiarEstadoLecturador(Integer id, Boolean estado) {
        Lecturador lecturador = buscarLecturador(id);

        Boolean estadoFinal = estado == null ? true : estado;

        lecturador.setEstado(estadoFinal);

        if (lecturador.getUsuario() != null) {
            lecturador.getUsuario().setEstado(estadoFinal);
            usuarioRepository.save(lecturador.getUsuario());
        }

        lecturador = lecturadorRepository.save(lecturador);

        return toResponse(lecturador);
    }

    @Transactional
    public void eliminarLecturador(Integer id) {
        Lecturador lecturador = buscarLecturador(id);
        Usuario usuario = lecturador.getUsuario();

        lecturadorRepository.delete(lecturador);
        lecturadorRepository.flush();

        if (usuario != null) {
            usuarioRepository.delete(usuario);
        }
    }

    private Lecturador buscarLecturador(Integer id) {
        return lecturadorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No existe el lecturador con ID: " + id));
    }

    private LecturadorResponse toResponse(Lecturador lecturador) {
        return toResponse(lecturador, null);
    }

    private LecturadorResponse toResponse(Lecturador lecturador, String passwordInicial) {
        Usuario usuario = lecturador.getUsuario();

        return LecturadorResponse.builder()
                .id(lecturador.getId())
                .dni(lecturador.getDni())
                .nombres(lecturador.getNombres())
                .apellidos(lecturador.getApellidos())
                .telefono(lecturador.getTelefono())
                .correo(lecturador.getCorreo())
                .codigoUsuario(usuario != null ? usuario.getCodigoUsuario() : "")
                .rol(usuario != null && usuario.getRol() != null ? usuario.getRol().getNombre() : "LECTURADOR")
                .estado(lecturador.getEstado())
                .sectorAsignado(lecturador.getSectorAsignado())
                .passwordInicial(passwordInicial)
                .build();
    }

    private void validarLecturador(LecturadorRequest request, boolean validarPassword) {
        if (request == null) {
            throw new RuntimeException("Los datos del lecturador son obligatorios.");
        }

        if (request.getDni() == null || request.getDni().trim().length() != 8) {
            throw new RuntimeException("Ingrese un DNI válido de 8 dígitos.");
        }

        if (request.getNombres() == null || request.getNombres().trim().isBlank()) {
            throw new RuntimeException("Ingrese los nombres del lecturador.");
        }

        if (request.getApellidos() == null || request.getApellidos().trim().isBlank()) {
            throw new RuntimeException("Ingrese los apellidos del lecturador.");
        }

        if (request.getCodigoUsuario() == null || request.getCodigoUsuario().trim().isBlank()) {
            throw new RuntimeException("Ingrese el usuario de acceso del lecturador.");
        }

        if (validarPassword) {
            if (request.getPassword() == null || request.getPassword().trim().length() < 6) {
                throw new RuntimeException("La contraseña inicial debe tener mínimo 6 caracteres.");
            }
        }
    }

    private String limpiarTexto(String valor) {
        return valor == null ? "" : valor.trim();
    }
}