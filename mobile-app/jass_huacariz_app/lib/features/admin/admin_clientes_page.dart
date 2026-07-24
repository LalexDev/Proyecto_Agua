// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../core/services/cliente_service.dart';
import '../../core/services/sector_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final Color secondary = JassColors.secondary;
  final ClienteService clienteService = ClienteService();
  final SectorService sectorService = SectorService();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> sectores = [];

  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  int _idCliente(Map<String, dynamic> cliente) {
    return _intValue(
      cliente['id'] ?? cliente['idCliente'] ?? cliente['clienteId'],
    );
  }

  int _idSuministro(Map<String, dynamic> suministro) {
    return _intValue(
      suministro['id'] ??
          suministro['idSuministro'] ??
          suministro['suministroId'] ??
          suministro['id_suministro'],
    );
  }

  int _idSector(Map<String, dynamic> suministro) {
    final sector = suministro['sector'];

    if (sector is Map) {
      return _intValue(
        sector['id'] ?? sector['idSector'] ?? sector['sectorId'],
      );
    }

    return _intValue(
      suministro['idSector'] ??
          suministro['sectorId'] ??
          suministro['id_sector'],
    );
  }

  String _nombreCliente(Map<String, dynamic> cliente) {
    final nombres = _txt(cliente['nombres'], '');
    final apellidos = _txt(cliente['apellidos'], '');
    final nombreCompleto = '$nombres $apellidos'.trim();

    return nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto;
  }

  bool _estadoCliente(Map<String, dynamic> cliente) {
    final value = cliente['estado'];

    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  bool _estadoSuministro(Map<String, dynamic> suministro) {
    final value = suministro['estado'];

    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  String _estadoInstalacion(Map<String, dynamic> suministro) {
    final raw = _txt(
      suministro['estadoInstalacion'] ??
          suministro['estado_instalacion'] ??
          suministro['estadoConexion'] ??
          suministro['estadoSuministro'],
      '',
    );

    final estado = raw.toUpperCase().trim();

    if (estado.contains('PENDIENTE')) return 'PENDIENTE_INSTALACION';
    if (estado.contains('SUSPEND')) return 'SUSPENDIDO';
    if (estado.contains('INACT')) return 'SUSPENDIDO';
    if (estado.contains('INSTAL')) return 'INSTALADO';

    return _estadoSuministro(suministro) ? 'INSTALADO' : 'SUSPENDIDO';
  }

  String _estadoInstalacionTexto(Map<String, dynamic> suministro) {
    final estado = _estadoInstalacion(suministro);

    if (estado == 'INSTALADO') return 'Instalado';
    if (estado == 'PENDIENTE_INSTALACION') return 'Pendiente instalación';
    return 'Suspendido';
  }

  String _codigoSuministro(Map<String, dynamic> suministro) {
    return _txt(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
      'SUMINISTRO',
    );
  }

  String _aliasSuministro(Map<String, dynamic> suministro) {
    return _txt(
      suministro['aliasSuministro'] ??
          suministro['alias'] ??
          suministro['referenciaRapida'],
      'Casa principal',
    );
  }

  String _direccionSuministro(Map<String, dynamic> suministro) {
    return _txt(
      suministro['direccionSuministro'] ??
          suministro['direccion'] ??
          suministro['direccionCliente'],
      '-',
    );
  }

  String _sectorSuministro(Map<String, dynamic> suministro) {
    final sector = suministro['sector'];

    if (sector is Map) {
      return _txt(
        sector['nombreSector'] ?? sector['nombre'] ?? sector['descripcion'],
      );
    }

    return _txt(
      suministro['nombreSector'] ??
          suministro['sector'] ??
          suministro['sectorNombre'] ??
          suministro['descripcionSector'],
    );
  }

  double _lecturaInicial(Map<String, dynamic> suministro) {
    return _doubleValue(
      suministro['lecturaInicial'] ??
          suministro['lecturaActual'] ??
          suministro['ultimaLectura'] ??
          suministro['lecturaAnterior'],
    );
  }

  static const int _limiteInicialClientes = 50;
  static const int _limiteBusquedaClientes = 80;

  int get _limiteClientesActual {
    return busqueda.trim().isEmpty
        ? _limiteInicialClientes
        : _limiteBusquedaClientes;
  }

  List<Map<String, dynamic>> get clientesFiltrados {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return clientes;

    return clientes.where((cliente) {
      final texto =
          '''
      ${_nombreCliente(cliente)}
      ${cliente['dni']}
      ${cliente['telefono']}
      ${cliente['correo']}
      ${cliente['suministros']}
      '''
              .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get clientesVisibles {
    final filtrados = clientesFiltrados;
    return filtrados.take(_limiteClientesActual).toList(growable: false);
  }

  bool get _clientesLimitados {
    return clientesFiltrados.length > clientesVisibles.length;
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final clientesData = await clienteService.listarClientes();
      final sectoresData = await sectorService.listarSectores();

      if (!mounted) return;

      setState(() {
        clientes = clientesData;
        sectores = sectoresData;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? JassColors.danger : JassColors.success,
      ),
    );
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String textoConfirmar,
    Color? color,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? secondary,
                foregroundColor: Colors.white,
              ),
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );

    return confirmar == true;
  }

  Future<void> _cambiarEstadoCliente(
    Map<String, dynamic> cliente, {
    bool cerrarDetalle = false,
  }) async {
    final idCliente = _idCliente(cliente);
    final activoActual = _estadoCliente(cliente);
    final nuevoEstado = !activoActual;

    if (idCliente <= 0) {
      _mensaje('No se encontró el ID del cliente.', true);
      return;
    }

    final ok = await _confirmar(
      titulo: activoActual ? 'Desactivar cliente' : 'Activar cliente',
      mensaje: activoActual
          ? 'El cliente quedará inactivo, pero se conservarán sus recibos, pagos y lecturas.'
          : 'El cliente volverá a estar activo para operaciones administrativas.',
      textoConfirmar: nuevoEstado ? 'Activar' : 'Desactivar',
      color: nuevoEstado ? JassColors.success : JassColors.danger,
    );

    if (!ok) return;

    try {
      await clienteService.cambiarEstadoCliente(
        idCliente: idCliente,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      if (cerrarDetalle) Navigator.pop(context);

      _mensaje(
        nuevoEstado
            ? 'Cliente activado correctamente.'
            : 'Cliente desactivado correctamente.',
        false,
      );

      await cargarDatos();
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  Future<void> _restablecerPasswordCliente(Map<String, dynamic> cliente) async {
    final idCliente = _idCliente(cliente);

    if (idCliente <= 0) {
      _mensaje('No se encontró el ID del cliente.', true);
      return;
    }

    final ok = await _confirmar(
      titulo: 'Restablecer contraseña',
      mensaje:
          'Se restablecerá la contraseña del cliente y deberá cambiarla al iniciar sesión en la web.',
      textoConfirmar: 'Restablecer',
      color: secondary,
    );

    if (!ok) return;

    try {
      final response = await clienteService.restablecerPasswordCliente(
        idCliente,
      );

      if (!mounted) return;

      final passwordTemporal = _txt(
        response['passwordTemporal'] ??
            response['password'] ??
            response['clave'],
        'cliente123',
      );

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Contraseña restablecida',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${_nombreCliente(cliente)}'),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.jassSelectedSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.jassBorder),
                  ),
                  child: Text(
                    passwordTemporal,
                    style: TextStyle(
                      color: context.jassTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'El cliente deberá cambiarla al iniciar sesión.',
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Entendido'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  Future<List<Map<String, dynamic>>> _suministrosCliente(
    Map<String, dynamic> cliente,
  ) async {
    final idCliente = _idCliente(cliente);

    if (cliente['suministros'] is List) {
      final list = (cliente['suministros'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (list.isNotEmpty) return list;
    }

    if (idCliente <= 0) return [];

    return clienteService.listarSuministrosPorCliente(idCliente);
  }

  Future<void> _abrirDetalleCliente(Map<String, dynamic> cliente) async {
    List<Map<String, dynamic>> suministros = [];

    try {
      suministros = await _suministrosCliente(cliente);
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.jassSurface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del cliente',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _nombreCliente(cliente),
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'DNI: ${_txt(cliente['dni'])}',
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 18),
                _DetalleResumenGrid(
                  telefono: _txt(cliente['telefono']),
                  correo: _txt(cliente['correo']),
                  activo: _estadoCliente(cliente),
                  suministros: suministros.length,
                ),
                SizedBox(height: 20),
                _DetalleAccionesCliente(
                  activo: _estadoCliente(cliente),
                  onEditar: () {
                    Navigator.pop(context);
                    _abrirEditarCliente(cliente);
                  },
                  onEstado: () {
                    _cambiarEstadoCliente(cliente, cerrarDetalle: true);
                  },
                  onPassword: () => _restablecerPasswordCliente(cliente),
                  onAgregarSuministro: () {
                    Navigator.pop(context);
                    _abrirFormularioSuministro(cliente);
                  },
                ),
                SizedBox(height: 24),
                Text(
                  'Suministros del cliente',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'No elimines suministros con historial. Usa estado instalado, pendiente o suspendido.',
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                if (suministros.isEmpty)
                  Text(
                    'Este cliente no tiene suministros registrados.',
                    style: TextStyle(
                      color: context.jassTextMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...suministros.map((suministro) {
                    return _SuministroAdminCard(
                      codigo: _codigoSuministro(suministro),
                      alias: _aliasSuministro(suministro),
                      direccion: _direccionSuministro(suministro),
                      sector: _sectorSuministro(suministro),
                      lecturaInicial: _lecturaInicial(suministro),
                      activo: _estadoSuministro(suministro),
                      estadoInstalacion: _estadoInstalacion(suministro),
                      estadoTexto: _estadoInstalacionTexto(suministro),
                      onEditar: () {
                        Navigator.pop(context);
                        _abrirFormularioSuministro(
                          cliente,
                          suministro: suministro,
                        );
                      },
                      onQr: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/admin-qr-suministro',
                          arguments: {
                            'codigoSuministro': _codigoSuministro(suministro),
                          },
                        );
                      },
                      onInstalado: () => _cambiarEstadoInstalacion(
                        cliente: cliente,
                        suministro: suministro,
                        estadoInstalacion: 'INSTALADO',
                      ),
                      onPendiente: () => _cambiarEstadoInstalacion(
                        cliente: cliente,
                        suministro: suministro,
                        estadoInstalacion: 'PENDIENTE_INSTALACION',
                      ),
                      onSuspender: () => _cambiarEstadoSuministro(
                        cliente: cliente,
                        suministro: suministro,
                        estado: !_estadoSuministro(suministro),
                      ),
                    );
                  }),
                SizedBox(height: 18),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirEditarCliente(Map<String, dynamic> cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return _EditarClienteSheet(
          cliente: cliente,
          onGuardar: (payload) async {
            final idCliente = _idCliente(cliente);

            if (idCliente <= 0) {
              throw Exception('No se encontró el ID del cliente.');
            }

            await clienteService.actualizarCliente(idCliente, payload);

            if (!mounted) return;

            Navigator.pop(context);
            _mensaje('Cliente actualizado correctamente.', false);
            await cargarDatos();
          },
        );
      },
    );
  }

  void _abrirFormularioCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return _RegistrarClienteSheet(
          sectores: sectores,
          onGuardar: (payload) async {
            await clienteService.registrarCliente(payload);

            if (!mounted) return;

            Navigator.pop(context);
            _mensaje('Cliente registrado correctamente.', false);
            await cargarDatos();
          },
        );
      },
    );
  }

  void _abrirFormularioSuministro(
    Map<String, dynamic> cliente, {
    Map<String, dynamic>? suministro,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return _SuministroFormSheet(
          sectores: sectores,
          suministro: suministro,
          idSectorInicial: suministro == null ? null : _idSector(suministro),
          onGuardar: (payload) async {
            final idCliente = _idCliente(cliente);

            if (idCliente <= 0) {
              throw Exception('No se encontró el ID del cliente.');
            }

            if (suministro == null) {
              await clienteService.agregarSuministro(
                idCliente: idCliente,
                data: payload,
              );
            } else {
              final idSuministro = _idSuministro(suministro);

              if (idSuministro <= 0) {
                throw Exception('No se encontró el ID del suministro.');
              }

              await clienteService.actualizarSuministro(
                idCliente: idCliente,
                idSuministro: idSuministro,
                data: payload,
              );
            }

            if (!mounted) return;

            Navigator.pop(context);
            _mensaje(
              suministro == null
                  ? 'Suministro agregado correctamente.'
                  : 'Suministro actualizado correctamente.',
              false,
            );
            await cargarDatos();
          },
        );
      },
    );
  }

  Future<void> _cambiarEstadoInstalacion({
    required Map<String, dynamic> cliente,
    required Map<String, dynamic> suministro,
    required String estadoInstalacion,
  }) async {
    final idCliente = _idCliente(cliente);
    final idSuministro = _idSuministro(suministro);

    if (idCliente <= 0 || idSuministro <= 0) {
      _mensaje('No se encontró el ID del cliente o suministro.', true);
      return;
    }

    final texto = estadoInstalacion == 'INSTALADO'
        ? 'marcar como instalado'
        : 'marcar como pendiente de instalación';

    final ok = await _confirmar(
      titulo: 'Cambiar estado de instalación',
      mensaje: '¿Deseas $texto este suministro?',
      textoConfirmar: 'Confirmar',
      color: secondary,
    );

    if (!ok) return;

    try {
      await clienteService.cambiarEstadoInstalacionSuministro(
        idCliente: idCliente,
        idSuministro: idSuministro,
        estadoInstalacion: estadoInstalacion,
      );

      if (!mounted) return;

      Navigator.pop(context);
      _mensaje('Estado de instalación actualizado.', false);
      await cargarDatos();
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  Future<void> _cambiarEstadoSuministro({
    required Map<String, dynamic> cliente,
    required Map<String, dynamic> suministro,
    required bool estado,
  }) async {
    final idCliente = _idCliente(cliente);
    final idSuministro = _idSuministro(suministro);

    if (idCliente <= 0 || idSuministro <= 0) {
      _mensaje('No se encontró el ID del cliente o suministro.', true);
      return;
    }

    final ok = await _confirmar(
      titulo: estado ? 'Activar suministro' : 'Suspender suministro',
      mensaje: estado
          ? 'El suministro volverá a estar activo.'
          : 'El suministro quedará inactivo, pero se conservarán recibos, pagos y lecturas.',
      textoConfirmar: estado ? 'Activar' : 'Suspender',
      color: estado ? JassColors.success : JassColors.danger,
    );

    if (!ok) return;

    try {
      await clienteService.cambiarEstadoSuministro(
        idCliente: idCliente,
        idSuministro: idSuministro,
        estado: estado,
      );

      if (!mounted) return;

      Navigator.pop(context);
      _mensaje(
        estado ? 'Suministro activado.' : 'Suministro suspendido.',
        false,
      );
      await cargarDatos();
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 1) return;

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(context: context, onRefresh: cargarDatos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
        onTap: _go,
        onPlus: _abrirMenuAdmin,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 14),
                _buildSearch(),
                SizedBox(height: 16),
                if (cargando)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(error: error, onRetry: cargarDatos),
                if (!cargando && error.isEmpty && clientesFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay clientes para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty && _clientesLimitados)
                  _LimitNotice(
                    texto:
                        'Mostrando ${clientesVisibles.length} de ${clientesFiltrados.length} clientes. Usa el buscador para encontrar un cliente específico.',
                  ),
                if (!cargando && error.isEmpty)
                  ...clientesVisibles.map((cliente) {
                    final suministros = cliente['suministros'];

                    return RepaintBoundary(
                      child: _ClienteCard(
                        nombre: _nombreCliente(cliente),
                        dni: _txt(cliente['dni']),
                        telefono: _txt(cliente['telefono']),
                        correo: _txt(cliente['correo']),
                        activo: _estadoCliente(cliente),
                        cantidadSuministros: suministros is List
                            ? suministros.length
                            : 0,
                        onDetalle: () => _abrirDetalleCliente(cliente),
                        onEditar: () => _abrirEditarCliente(cliente),
                        onCambiarEstado: () => _cambiarEstadoCliente(cliente),
                      ),
                    );
                  }),
                SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de clientes',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Clientes',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: _abrirFormularioCliente,
            tooltip: 'Registrar cliente',
            icon: Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: cargarDatos,
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh_rounded, color: context.jassTextPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) {
        setState(() {
          busqueda = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar por DNI, cliente o suministro...',
        prefixIcon: Icon(Icons.search),
        filled: true,
        fillColor: context.jassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _LimitNotice extends StatelessWidget {
  final String texto;

  const _LimitNotice({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JassColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: JassColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: context.jassTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleAccionesCliente extends StatelessWidget {
  final bool activo;
  final VoidCallback onEditar;
  final VoidCallback onEstado;
  final VoidCallback onPassword;
  final VoidCallback onAgregarSuministro;

  _DetalleAccionesCliente({
    required this.activo,
    required this.onEditar,
    required this.onEstado,
    required this.onPassword,
    required this.onAgregarSuministro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEditar,
                icon: Icon(Icons.edit_outlined),
                label: Text('Editar cliente'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEstado,
                icon: Icon(
                  activo
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(activo ? 'Desactivar' : 'Activar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activo
                      ? Color(0xFFFFECEC)
                      : Color(0xFFEAF8EF),
                  foregroundColor: activo
                      ? JassColors.danger
                      : JassColors.success,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPassword,
                icon: Icon(Icons.lock_reset_rounded),
                label: Text('Restablecer contraseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.jassSelectedSurface,
                  foregroundColor: context.jassTextPrimary,
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAgregarSuministro,
                icon: Icon(Icons.add_location_alt_outlined),
                label: Text('Agregar suministro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JassColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuministroAdminCard extends StatelessWidget {
  final String codigo;
  final String alias;
  final String direccion;
  final String sector;
  final double lecturaInicial;
  final bool activo;
  final String estadoInstalacion;
  final String estadoTexto;
  final VoidCallback onEditar;
  final VoidCallback onQr;
  final VoidCallback onInstalado;
  final VoidCallback onPendiente;
  final VoidCallback onSuspender;

  _SuministroAdminCard({
    required this.codigo,
    required this.alias,
    required this.direccion,
    required this.sector,
    required this.lecturaInicial,
    required this.activo,
    required this.estadoInstalacion,
    required this.estadoTexto,
    required this.onEditar,
    required this.onQr,
    required this.onInstalado,
    required this.onPendiente,
    required this.onSuspender,
  });

  @override
  Widget build(BuildContext context) {
    final puedeMarcarInstalado = estadoInstalacion != 'INSTALADO';
    final puedeMarcarPendiente = estadoInstalacion != 'PENDIENTE_INSTALACION';

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: context.jassSelectedSurface,
                child: Icon(
                  Icons.water_drop_rounded,
                  color: JassColors.secondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo,
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      alias,
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$direccion · $sector',
                      style: TextStyle(
                        color: context.jassTextMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _SuministroEstadoChip(
                activo: activo,
                estadoInstalacion: estadoInstalacion,
                estadoTexto: estadoTexto,
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoLine(
            label: 'Lectura base',
            value: '${lecturaInicial.toStringAsFixed(3)} m³',
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniAction(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: onEditar,
              ),
              _MiniAction(
                icon: Icons.qr_code_2_rounded,
                label: 'QR',
                onTap: onQr,
              ),
              if (puedeMarcarInstalado)
                _MiniAction(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Instalado',
                  onTap: onInstalado,
                ),
              if (puedeMarcarPendiente)
                _MiniAction(
                  icon: Icons.home_repair_service_outlined,
                  label: 'Pendiente',
                  onTap: onPendiente,
                ),
              _MiniAction(
                icon: activo
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                label: activo ? 'Suspender' : 'Activar',
                danger: activo,
                onTap: onSuspender,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuministroEstadoChip extends StatelessWidget {
  final bool activo;
  final String estadoInstalacion;
  final String estadoTexto;

  _SuministroEstadoChip({
    required this.activo,
    required this.estadoInstalacion,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    if (!activo || estadoInstalacion == 'SUSPENDIDO') {
      bg = Color(0xFFFFECEC);
      fg = JassColors.danger;
      text = 'Suspendido';
    } else if (estadoInstalacion == 'PENDIENTE_INSTALACION') {
      bg = Color(0xFFFFF3DF);
      fg = JassColors.warning;
      text = 'Pendiente';
    } else {
      bg = Color(0xFFEAF8EF);
      fg = JassColors.success;
      text = estadoTexto;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: danger ? Color(0xFFFFECEC) : context.jassSelectedSurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: context.jassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: danger ? JassColors.danger : context.jassTextPrimary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: danger ? JassColors.danger : context.jassTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.jassTextMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetalleResumenGrid extends StatelessWidget {
  final String telefono;
  final String correo;
  final bool activo;
  final int suministros;

  _DetalleResumenGrid({
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.suministros,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ResumenBox(label: 'Teléfono', value: telefono),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ResumenBox(label: 'Correo', value: correo),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ResumenBox(
                label: 'Estado cliente',
                value: activo ? 'Activo' : 'Inactivo',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ResumenBox(
                label: 'Total suministros',
                value: '$suministros',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResumenBox extends StatelessWidget {
  final String label;
  final String value;

  _ResumenBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 74),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final String nombre;
  final String dni;
  final String telefono;
  final String correo;
  final bool activo;
  final int cantidadSuministros;
  final VoidCallback onDetalle;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  _ClienteCard({
    required this.nombre,
    required this.dni,
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.cantidadSuministros,
    required this.onDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.jassSelectedSurface,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'DNI: $dni',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tel: $telefono · $correo',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Suministros: $cantidadSuministros',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ClienteActionButton(
                  onPressed: onDetalle,
                  icon: Icons.visibility_outlined,
                  texto: 'Ver',
                  outlined: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ClienteActionButton(
                  onPressed: onEditar,
                  icon: Icons.edit_outlined,
                  texto: 'Editar',
                  backgroundColor: context.jassSelectedSurface,
                  foregroundColor: context.jassTextPrimary,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ClienteActionButton(
                  onPressed: onCambiarEstado,
                  icon: activo
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  texto: activo ? 'Desact.' : 'Activar',
                  backgroundColor: activo
                      ? Color(0xFFFFECEC)
                      : Color(0xFFEAF8EF),
                  foregroundColor: activo
                      ? JassColors.danger
                      : JassColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClienteActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String texto;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _ClienteActionButton({
    required this.onPressed,
    required this.icon,
    required this.texto,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(0, 44)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      backgroundColor: backgroundColor == null
          ? null
          : WidgetStateProperty.all(backgroundColor),
      foregroundColor: foregroundColor == null
          ? null
          : WidgetStateProperty.all(foregroundColor),
      elevation: WidgetStateProperty.all(0),
    );

    if (outlined) {
      return OutlinedButton(onPressed: onPressed, style: style, child: child);
    }

    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _RegistrarClienteSheet extends StatefulWidget {
  final List<Map<String, dynamic>> sectores;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _RegistrarClienteSheet({required this.sectores, required this.onGuardar});

  @override
  State<_RegistrarClienteSheet> createState() => _RegistrarClienteSheetState();
}

class _RegistrarClienteSheetState extends State<_RegistrarClienteSheet> {
  final Color secondary = JassColors.secondary;
  final dniController = TextEditingController();
  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();

  final direccionController = TextEditingController();
  final referenciaController = TextEditingController();
  final aliasController = TextEditingController();
  final lecturaInicialController = TextEditingController(text: '0');

  int? idSectorSeleccionado;
  final List<Map<String, dynamic>> suministros = [];

  bool estadoCliente = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    if (widget.sectores.isNotEmpty) {
      idSectorSeleccionado = _idSector(widget.sectores.first);
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    direccionController.dispose();
    referenciaController.dispose();
    aliasController.dispose();
    lecturaInicialController.dispose();
    super.dispose();
  }

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? JassColors.danger : JassColors.success,
      ),
    );
  }

  void agregarSuministro() {
    final direccion = direccionController.text.trim();
    final referencia = referenciaController.text.trim();
    final alias = aliasController.text.trim();
    final lectura = double.tryParse(lecturaInicialController.text.trim()) ?? 0;

    if (idSectorSeleccionado == null || idSectorSeleccionado == 0) {
      _mensaje('Selecciona un sector.', true);
      return;
    }

    if (direccion.isEmpty || alias.isEmpty) {
      _mensaje('Completa dirección y alias del suministro.', true);
      return;
    }

    setState(() {
      suministros.add({
        'idSector': idSectorSeleccionado,
        'direccionSuministro': direccion,
        'referencia': referencia,
        'aliasSuministro': alias,
        'lecturaInicial': lectura,
        'estado': true,
        'estadoInstalacion': 'INSTALADO',
      });

      direccionController.clear();
      referenciaController.clear();
      aliasController.clear();
      lecturaInicialController.text = '0';
    });
  }

  Future<void> guardarCliente() async {
    final dni = dniController.text.trim();
    final nombres = nombresController.text.trim();
    final apellidos = apellidosController.text.trim();
    final telefono = telefonoController.text.trim();
    final correo = correoController.text.trim();

    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
      _mensaje('Completa DNI, nombres y apellidos.', true);
      return;
    }

    if (suministros.isEmpty) {
      _mensaje('Agrega al menos un suministro.', true);
      return;
    }

    final payload = {
      'dni': dni,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'estado': estadoCliente,
      'suministros': suministros,
    };

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar(payload);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar cliente',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Registra los datos del cliente y uno o más suministros.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI',
              keyboardType: TextInputType.number,
            ),
            _Input(controller: nombresController, label: 'Nombres'),
            _Input(controller: apellidosController, label: 'Apellidos'),
            _Input(
              controller: telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            _Input(
              controller: correoController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownButtonFormField<bool>(
              value: estadoCliente,
              decoration: InputDecoration(
                labelText: 'Estado inicial del cliente',
                helperText: estadoCliente
                    ? 'El cliente podrá operar normalmente.'
                    : 'Se registra inactivo y no podrá operar hasta activarlo.',
                helperMaxLines: 2,
                filled: true,
                fillColor: context.jassSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(value: true, child: Text('Activo')),
                DropdownMenuItem(value: false, child: Text('Inactivo')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  estadoCliente = value;
                });
              },
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),
            Text(
              'Suministros',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            _SectorDropdown(
              sectores: widget.sectores,
              value: idSectorSeleccionado,
              onChanged: (value) {
                setState(() {
                  idSectorSeleccionado = value;
                });
              },
            ),
            _Input(
              controller: direccionController,
              label: 'Dirección del suministro',
            ),
            _Input(controller: referenciaController, label: 'Referencia'),
            _Input(controller: aliasController, label: 'Alias del suministro'),
            _Input(
              controller: lecturaInicialController,
              label: 'Lectura inicial',
              keyboardType: TextInputType.number,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: agregarSuministro,
                icon: Icon(Icons.add_location_alt_outlined),
                label: Text('Agregar suministro'),
              ),
            ),
            SizedBox(height: 12),
            if (suministros.isNotEmpty)
              ...suministros.asMap().entries.map((entry) {
                final index = entry.key;
                final suministro = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.jassSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.water_drop_rounded, color: secondary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${suministro['aliasSuministro']} · ${suministro['direccionSuministro']}',
                          style: TextStyle(
                            color: context.jassTextPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            suministros.removeAt(index);
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: JassColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarCliente,
                icon: guardando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.save_outlined),
                label: Text(
                  guardando ? 'Guardando...' : 'Guardar cliente',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuministroFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> sectores;
  final Map<String, dynamic>? suministro;
  final int? idSectorInicial;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _SuministroFormSheet({
    required this.sectores,
    required this.suministro,
    required this.idSectorInicial,
    required this.onGuardar,
  });

  @override
  State<_SuministroFormSheet> createState() => _SuministroFormSheetState();
}

class _SuministroFormSheetState extends State<_SuministroFormSheet> {
  final aliasController = TextEditingController();
  final direccionController = TextEditingController();
  final referenciaController = TextEditingController();
  final lecturaInicialController = TextEditingController(text: '0');

  int? idSectorSeleccionado;
  String estadoInstalacion = 'INSTALADO';
  bool activo = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    final suministro = widget.suministro;

    if (suministro == null) {
      if (widget.sectores.isNotEmpty) {
        idSectorSeleccionado = _idSector(widget.sectores.first);
      }
      return;
    }

    aliasController.text = _txt(
      suministro['aliasSuministro'] ??
          suministro['alias'] ??
          suministro['referenciaRapida'],
      '',
    );
    direccionController.text = _txt(
      suministro['direccionSuministro'] ??
          suministro['direccion'] ??
          suministro['direccionCliente'],
      '',
    );
    referenciaController.text = _txt(suministro['referencia'], '');
    lecturaInicialController.text = _num(
      suministro['lecturaInicial'] ??
          suministro['lecturaActual'] ??
          suministro['ultimaLectura'] ??
          suministro['lecturaAnterior'],
    ).toStringAsFixed(3);
    idSectorSeleccionado =
        widget.idSectorInicial == null || widget.idSectorInicial == 0
        ? (widget.sectores.isNotEmpty ? _idSector(widget.sectores.first) : null)
        : widget.idSectorInicial;
    activo = _estadoBool(suministro['estado']);
    estadoInstalacion = activo
        ? _estadoInstalacionFrom(suministro)
        : 'SUSPENDIDO';
  }

  @override
  void dispose() {
    aliasController.dispose();
    direccionController.dispose();
    referenciaController.dispose();
    lecturaInicialController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  bool _estadoBool(dynamic value) {
    if (value is bool) return value;
    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == 'activo' || text == '1';
  }

  String _estadoInstalacionFrom(Map<String, dynamic> suministro) {
    final raw = _txt(
      suministro['estadoInstalacion'] ??
          suministro['estado_instalacion'] ??
          suministro['estadoConexion'] ??
          suministro['estadoSuministro'],
      '',
    ).toUpperCase();

    if (raw.contains('PENDIENTE')) return 'PENDIENTE_INSTALACION';
    if (raw.contains('SUSPEND') || raw.contains('INACT')) return 'SUSPENDIDO';
    return 'INSTALADO';
  }

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  void _mensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: JassColors.danger),
    );
  }

  Future<void> guardar() async {
    final alias = aliasController.text.trim();
    final direccion = direccionController.text.trim();
    final referencia = referenciaController.text.trim();
    final lectura = double.tryParse(lecturaInicialController.text.trim()) ?? 0;

    if (idSectorSeleccionado == null || idSectorSeleccionado == 0) {
      _mensaje('Selecciona un sector.');
      return;
    }

    if (alias.isEmpty || direccion.isEmpty) {
      _mensaje('Completa alias y dirección del suministro.');
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar({
        'idSector': idSectorSeleccionado,
        'direccionSuministro': direccion,
        'referencia': referencia,
        'aliasSuministro': alias,
        'lecturaInicial': lectura,
        'estado': activo,
        'estadoInstalacion': estadoInstalacion,
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.suministro != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar suministro' : 'Agregar suministro',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'No se elimina el suministro para conservar recibos, pagos e historial.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            _SectorDropdown(
              sectores: widget.sectores,
              value: idSectorSeleccionado,
              onChanged: (value) {
                setState(() {
                  idSectorSeleccionado = value;
                });
              },
            ),
            _Input(controller: aliasController, label: 'Alias del suministro'),
            _Input(
              controller: direccionController,
              label: 'Dirección del suministro',
            ),
            _Input(controller: referenciaController, label: 'Referencia'),
            _Input(
              controller: lecturaInicialController,
              label: 'Lectura inicial / base',
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: estadoInstalacion,
              decoration: InputDecoration(
                labelText: 'Estado de instalación',
                filled: true,
                fillColor: context.jassSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'INSTALADO', child: Text('Instalado')),
                DropdownMenuItem(
                  value: 'PENDIENTE_INSTALACION',
                  child: Text('Pendiente de instalación'),
                ),
                DropdownMenuItem(
                  value: 'SUSPENDIDO',
                  child: Text('Suspendido'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  estadoInstalacion = value;
                  if (value == 'SUSPENDIDO') activo = false;
                  if (value == 'INSTALADO') activo = true;
                });
              },
            ),
            SizedBox(height: 10),
            SwitchListTile(
              value: activo,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Suministro activo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Desactívalo solo si el suministro queda suspendido.',
              ),
              onChanged: (value) {
                setState(() {
                  activo = value;
                  if (!activo) estadoInstalacion = 'SUSPENDIDO';
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: guardando ? null : () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardar,
                    icon: guardando
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save_outlined),
                    label: Text(guardando ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JassColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarClienteSheet extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _EditarClienteSheet({required this.cliente, required this.onGuardar});

  @override
  State<_EditarClienteSheet> createState() => _EditarClienteSheetState();
}

class _EditarClienteSheetState extends State<_EditarClienteSheet> {
  final Color secondary = JassColors.secondary;
  late final TextEditingController dniController;
  late final TextEditingController nombresController;
  late final TextEditingController apellidosController;
  late final TextEditingController telefonoController;
  late final TextEditingController correoController;

  bool estado = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    dniController = TextEditingController(
      text: (widget.cliente['dni'] ?? '').toString(),
    );
    nombresController = TextEditingController(
      text: (widget.cliente['nombres'] ?? '').toString(),
    );
    apellidosController = TextEditingController(
      text: (widget.cliente['apellidos'] ?? '').toString(),
    );
    telefonoController = TextEditingController(
      text: (widget.cliente['telefono'] ?? '').toString(),
    );
    correoController = TextEditingController(
      text: (widget.cliente['correo'] ?? '').toString(),
    );

    final value = widget.cliente['estado'];

    if (value is bool) {
      estado = value;
    } else {
      final text = value.toString().toLowerCase().trim();
      estado = text == 'true' || text == 'activo' || text == '1';
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final dni = dniController.text.trim();
    final nombres = nombresController.text.trim();
    final apellidos = apellidosController.text.trim();

    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa DNI, nombres y apellidos.'),
          backgroundColor: JassColors.danger,
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar({
        'dni': dni,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefonoController.text.trim(),
        'correo': correoController.text.trim(),
        'estado': estado,
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: JassColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto =
        '${nombresController.text} ${apellidosController.text}'.trim();

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar cliente',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              nombreCompleto.isEmpty
                  ? 'Actualiza los datos personales y contacto del cliente.'
                  : nombreCompleto,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI',
              keyboardType: TextInputType.number,
            ),
            _Input(controller: nombresController, label: 'Nombres'),
            _Input(controller: apellidosController, label: 'Apellidos'),
            _Input(
              controller: telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            _Input(
              controller: correoController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownButtonFormField<bool>(
              value: estado,
              decoration: InputDecoration(
                labelText: 'Estado cliente',
                filled: true,
                fillColor: context.jassSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(value: true, child: Text('Activo')),
                DropdownMenuItem(value: false, child: Text('Inactivo')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  estado = value;
                });
              },
            ),
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3DF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFD899)),
              ),
              child: Text(
                'Si cambias el DNI, también puede actualizarse el usuario de acceso del cliente en la web.',
                style: TextStyle(
                  color: JassColors.warning,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: guardando ? null : () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardar,
                    icon: guardando
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save_outlined),
                    label: Text(guardando ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectorDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> sectores;
  final int? value;
  final ValueChanged<int?> onChanged;

  _SectorDropdown({
    required this.sectores,
    required this.value,
    required this.onChanged,
  });

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _nombreSector(Map<String, dynamic> sector) {
    final value =
        sector['nombreSector'] ?? sector['nombre'] ?? sector['descripcion'];

    if (value == null) return 'Sector';

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (sectores.isEmpty) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFFFFF3DF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFFFFD899)),
        ),
        child: Text(
          'No hay sectores cargados. Verifica el endpoint /sectores.',
          style: TextStyle(
            color: JassColors.warning,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final values = sectores.map(_idSector).where((id) => id > 0).toSet();
    final safeValue = values.contains(value) ? value : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: 'Sector',
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: sectores.map((sector) {
          return DropdownMenuItem<int>(
            value: _idSector(sector),
            child: Text(_nombreSector(sector)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  _Input({required this.controller, required this.label, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  _EstadoChip({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: activo ? Color(0xFFEAF8EF) : Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? JassColors.success : JassColors.danger,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  _Error({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: JassColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text('Reintentar')),
        ],
      ),
    );
  }
}
