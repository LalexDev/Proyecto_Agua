import 'package:flutter/material.dart';
import '../../core/services/cliente_service.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final ClienteService service = ClienteService();

  List<Map<String, dynamic>> clientes = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }


  bool _activo(Map<String, dynamic> cliente) {
    final value = cliente['estado'];
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  String _nombre(Map<String, dynamic> cliente) {
    final nombres = _txt(cliente['nombres'], '');
    final apellidos = _txt(cliente['apellidos'], '');
    final completo = '$nombres $apellidos'.trim();
    return completo.isEmpty ? 'Sin nombre' : completo;
  }

  List<Map<String, dynamic>> get filtrados {
    final query = busqueda.toLowerCase().trim();

    if (query.isEmpty) return clientes;

    return clientes.where((cliente) {
      final texto = '''
        ${_nombre(cliente)}
        ${cliente['dni']}
        ${cliente['codigoUsuario']}
        ${cliente['telefono']}
        ${cliente['correo']}
        ${cliente['suministros']}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await service.listarClientes();

      if (!mounted) return;

      setState(() {
        clientes = data;
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

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }

    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/admin-reportes');
    }
  }

  void _abrirFormularioCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return _RegistrarClienteSheet(
          onGuardar: (payload) async {
            await service.registrarCliente(payload);

            if (!mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente registrado correctamente.'),
                backgroundColor: Color(0xFF1F8F4D),
              ),
            );

            await cargar();
          },
        );
      },
    );
  }

  void _mostrarDetalle(Map<String, dynamic> cliente) {
    final suministros =
        (cliente['suministros'] is List) ? cliente['suministros'] as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(22),
              children: [
                Text(
                  _nombre(cliente),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _DetalleLine(label: 'DNI', value: _txt(cliente['dni'])),
                _DetalleLine(
                  label: 'Usuario',
                  value: _txt(cliente['codigoUsuario']),
                ),
                _DetalleLine(
                  label: 'Teléfono',
                  value: _txt(cliente['telefono']),
                ),
                _DetalleLine(
                  label: 'Correo',
                  value: _txt(cliente['correo']),
                ),
                const Divider(height: 30),
                const Text(
                  'Suministros',
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (suministros.isEmpty)
                  const Text(
                    'Este cliente no tiene suministros registrados.',
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...suministros.map((item) {
                    final suministro = Map<String, dynamic>.from(item as Map);

                    final activo = suministro['estado'] == true ||
                        suministro['estado'].toString().toLowerCase() == 'true';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE2EDF3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.water_drop_rounded,
                            color: secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _txt(suministro['codigoSuministro']),
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _txt(suministro['direccionSuministro']),
                                  style: const TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _txt(suministro['nombreSector']),
                                  style: const TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _EstadoChip(activo: activo),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 1,
        onTap: _go,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        onPressed: _abrirFormularioCliente,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildSearch(),
                const SizedBox(height: 16),
                if (cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(
                    error: error,
                    onRetry: cargar,
                  ),
                if (!cargando && error.isEmpty && filtrados.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay clientes para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...filtrados.map((cliente) {
                    final suministros = cliente['suministros'];

                    return _ClienteCard(
                      nombre: _nombre(cliente),
                      dni: _txt(cliente['dni']),
                      codigo: _txt(cliente['codigoUsuario']),
                      telefono: _txt(cliente['telefono']),
                      correo: _txt(cliente['correo']),
                      activo: _activo(cliente),
                      suministros:
                          (suministros is List) ? suministros.length : 0,
                      onDetalle: () => _mostrarDetalle(cliente),
                    );
                  }),
                const SizedBox(height: 80),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de usuarios',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Clientes',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargar,
          icon: const Icon(
            Icons.refresh_rounded,
            color: primary,
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
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final String nombre;
  final String dni;
  final String codigo;
  final String telefono;
  final String correo;
  final bool activo;
  final int suministros;
  final VoidCallback onDetalle;

  const _ClienteCard({
    required this.nombre,
    required this.dni,
    required this.codigo,
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.suministros,
    required this.onDetalle,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F7FB),
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre.isEmpty ? 'Sin nombre' : nombre,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'DNI: $dni · Usuario: $codigo',
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tel: $telefono · $correo',
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Suministros: $suministros',
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onDetalle,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                'Ver detalle',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(
                  color: Color(0xFF0F3D57),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFEAF8EF) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? const Color(0xFF1F8F4D) : const Color(0xFFD93025),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetalleLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetalleLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrarClienteSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  const _RegistrarClienteSheet({
    required this.onGuardar,
  });

  @override
  State<_RegistrarClienteSheet> createState() => _RegistrarClienteSheetState();
}

class _RegistrarClienteSheetState extends State<_RegistrarClienteSheet> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color muted = Color(0xFF7B8794);

  final dniController = TextEditingController();
  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();

  final idSectorController = TextEditingController(text: '1');
  final direccionController = TextEditingController();
  final referenciaController = TextEditingController();
  final aliasController = TextEditingController();
  final lecturaInicialController = TextEditingController(text: '0');

  final List<Map<String, dynamic>> suministros = [];

  bool guardando = false;

  @override
  void dispose() {
    dniController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    idSectorController.dispose();
    direccionController.dispose();
    referenciaController.dispose();
    aliasController.dispose();
    lecturaInicialController.dispose();
    super.dispose();
  }

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? const Color(0xFFD93025) : const Color(0xFF1F8F4D),
      ),
    );
  }

  void agregarSuministro() {
    final idSector = int.tryParse(idSectorController.text.trim()) ?? 1;
    final direccion = direccionController.text.trim();
    final referencia = referenciaController.text.trim();
    final alias = aliasController.text.trim();
    final lectura =
        double.tryParse(lecturaInicialController.text.trim()) ?? 0;

    if (direccion.isEmpty || alias.isEmpty) {
      _mensaje('Completa dirección y alias del suministro.', true);
      return;
    }

    setState(() {
      suministros.add({
        'idSector': idSector,
        'direccionSuministro': direccion,
        'referencia': referencia,
        'aliasSuministro': alias,
        'lecturaInicial': lectura,
      });

      direccionController.clear();
      referenciaController.clear();
      aliasController.clear();
      lecturaInicialController.text = '0';
    });
  }

  Future<void> guardar() async {
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
      'codigoUsuario': dni,
      'password': dni,
      'rol': 'CLIENTE',
      'estado': true,
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
            const Text(
              'Registrar cliente',
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'El usuario y la contraseña inicial serán el DNI.',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI / Código usuario',
              keyboardType: TextInputType.number,
            ),
            _Input(
              controller: nombresController,
              label: 'Nombres',
            ),
            _Input(
              controller: apellidosController,
              label: 'Apellidos',
            ),
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
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Suministros',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _Input(
              controller: idSectorController,
              label: 'ID Sector',
              keyboardType: TextInputType.number,
            ),
            _Input(
              controller: direccionController,
              label: 'Dirección del suministro',
            ),
            _Input(
              controller: referenciaController,
              label: 'Referencia',
            ),
            _Input(
              controller: aliasController,
              label: 'Alias del suministro',
            ),
            _Input(
              controller: lecturaInicialController,
              label: 'Lectura inicial',
              keyboardType: TextInputType.number,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: agregarSuministro,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Agregar suministro'),
              ),
            ),
            const SizedBox(height: 12),
            if (suministros.isNotEmpty)
              ...suministros.asMap().entries.map((entry) {
                final index = entry.key;
                final suministro = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${suministro['aliasSuministro']} · ${suministro['direccionSuministro']}',
                          style: const TextStyle(
                            color: primary,
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
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD93025),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardar,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  guardando ? 'Guardando...' : 'Guardar cliente',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
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

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F8FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _Error({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD93025),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 76,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_rounded),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.attach_money_rounded),
          label: 'Tarifas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Reportes',
        ),
      ],
    );
  }
}