import 'package:flutter/material.dart';

import '../../core/services/recibo_service.dart';

class AdminRecibosPage extends StatefulWidget {
  const AdminRecibosPage({super.key});

  @override
  State<AdminRecibosPage> createState() => _AdminRecibosPageState();
}

class _AdminRecibosPageState extends State<AdminRecibosPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final ReciboService reciboService = ReciboService();

  List<Map<String, dynamic>> recibos = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';
  String filtroEstado = 'TODOS';

  @override
  void initState() {
    super.initState();
    cargarRecibos();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _idRecibo(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _codigoRecibo(Map<String, dynamic> recibo) {
    return _txt(
      recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'],
      'REC-${_idRecibo(recibo)}',
    );
  }

  String _codigoSuministro(Map<String, dynamic> recibo) {
    return _txt(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['suministro'],
    );
  }

  String _cliente(Map<String, dynamic> recibo) {
    return _txt(
      recibo['cliente'] ??
          recibo['nombreCliente'] ??
          recibo['titular'] ??
          recibo['nombres'] ??
          recibo['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> recibo) {
    return _txt(
      recibo['direccionSuministro'] ??
          recibo['direccion'] ??
          recibo['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _estado(Map<String, dynamic> recibo) {
    return _txt(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _num(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  double _total(Map<String, dynamic> recibo) {
    return _num(
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  String _vencimiento(Map<String, dynamic> recibo) {
    return _txt(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
    );
  }

  String _periodo(Map<String, dynamic> recibo) {
    final mes = recibo['mes'];
    final anio = recibo['anio'];

    if (mes != null && anio != null) {
      const meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      final mesNumero = int.tryParse(mes.toString()) ?? 1;
      final index = (mesNumero - 1).clamp(0, 11);

      return '${meses[index]} $anio';
    }

    return _txt(
      recibo['periodo'] ?? recibo['mesFacturado'],
      'Periodo no registrado',
    );
  }

  bool _puedeMarcarPagado(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

  List<Map<String, dynamic>> get recibosFiltrados {
    final query = busqueda.trim().toLowerCase();

    return recibos.where((recibo) {
      final estado = _estado(recibo);

      final cumpleEstado =
          filtroEstado == 'TODOS' ? true : estado == filtroEstado;

      final texto = '''
      ${_codigoRecibo(recibo)}
      ${_codigoSuministro(recibo)}
      ${_cliente(recibo)}
      ${_direccion(recibo)}
      ${_periodo(recibo)}
      ${_estado(recibo)}
      '''
          .toLowerCase();

      final cumpleBusqueda = query.isEmpty ? true : texto.contains(query);

      return cumpleEstado && cumpleBusqueda;
    }).toList();
  }

  int get totalRecibos => recibos.length;

  int get pendientes {
    return recibos.where((r) => _estado(r) == 'PENDIENTE').length;
  }

  int get pagados {
    return recibos.where((r) => _estado(r) == 'PAGADO').length;
  }

  int get vencidos {
    return recibos.where((r) => _estado(r) == 'VENCIDO').length;
  }

  double get deudaTotal {
    return recibos.where((r) {
      final estado = _estado(r);
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) => sum + _total(recibo));
  }

  Future<void> cargarRecibos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await reciboService.listarRecibosAdmin();

      if (!mounted) return;

      setState(() {
        recibos = data;
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

  Future<void> _buscarPorSuministro(String codigo) async {
    final texto = codigo.trim();

    if (texto.isEmpty) {
      await cargarRecibos();
      return;
    }

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await reciboService.buscarPorSuministroAdmin(texto);

      if (!mounted) return;

      setState(() {
        recibos = data;
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

  Future<void> _marcarPagado(Map<String, dynamic> recibo) async {
    final idRecibo = _idRecibo(recibo);

    if (idRecibo <= 0) {
      _mensaje('No se encontró el ID del recibo.', true);
      return;
    }

    final codigoOperacionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (contextSheet) {
        bool guardando = false;
        String metodoPago = 'EFECTIVO';

        return StatefulBuilder(
          builder: (contextSheet, setModalState) {
            Future<void> confirmar() async {
              final codigoOperacion =
                  codigoOperacionController.text.trim().isEmpty
                      ? 'ADMIN-${DateTime.now().millisecondsSinceEpoch}'
                      : codigoOperacionController.text.trim();

              setModalState(() {
                guardando = true;
              });

              try {
                await reciboService.pagarReciboAdmin(
                  idRecibo: idRecibo,
                  metodoPago: metodoPago,
                  codigoOperacion: codigoOperacion,
                );

                if (!mounted) return;

                Navigator.pop(contextSheet);

                _mensaje('Recibo marcado como pagado.', false);

                await cargarRecibos();
              } catch (e) {
                setModalState(() {
                  guardando = false;
                });

                _mensaje(
                  e.toString().replaceFirst('Exception: ', ''),
                  true,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(contextSheet).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar pago presencial',
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_codigoRecibo(recibo)} · S/ ${_total(recibo).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: metodoPago,
                      decoration: InputDecoration(
                        labelText: 'Método de pago',
                        filled: true,
                        fillColor: const Color(0xFFF4F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'EFECTIVO',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'YAPE',
                          child: Text('Yape / Plin'),
                        ),
                        DropdownMenuItem(
                          value: 'TRANSFERENCIA',
                          child: Text('Transferencia'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          metodoPago = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codigoOperacionController,
                      decoration: InputDecoration(
                        labelText: 'Código de operación',
                        hintText: 'Opcional para efectivo',
                        filled: true,
                        fillColor: const Color(0xFFF4F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: guardando ? null : confirmar,
                        icon: guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          guardando ? 'Guardando...' : 'Confirmar pago',
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
          },
        );
      },
    );

    codigoOperacionController.dispose();
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

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    }

    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/admin-reportes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 3,
        onTap: _go,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarRecibos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStats(),
                const SizedBox(height: 16),
                _buildSearch(),
                const SizedBox(height: 14),
                _buildFilters(),
                const SizedBox(height: 16),
                if (cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(
                    error: error,
                    onRetry: cargarRecibos,
                  ),
                if (!cargando && error.isEmpty && recibosFiltrados.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay recibos para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...recibosFiltrados.map((recibo) {
                    return _ReciboCard(
                      codigoRecibo: _codigoRecibo(recibo),
                      codigoSuministro: _codigoSuministro(recibo),
                      cliente: _cliente(recibo),
                      direccion: _direccion(recibo),
                      periodo: _periodo(recibo),
                      consumo: _consumo(recibo),
                      total: _total(recibo),
                      vencimiento: _vencimiento(recibo),
                      estado: _estado(recibo),
                      puedeMarcarPagado: _puedeMarcarPagado(recibo),
                      onPagar: () => _marcarPagado(recibo),
                    );
                  }),
                const SizedBox(height: 90),
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
                'Facturación mensual',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Recibos',
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
          onPressed: cargarRecibos,
          icon: const Icon(
            Icons.refresh_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '$totalRecibos',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pendientes',
                value: '$pendientes',
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pagados',
                value: '$pagados',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Deuda',
                value: 'S/ ${deudaTotal.toStringAsFixed(2)}',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
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
      onSubmitted: _buscarPorSuministro,
      decoration: InputDecoration(
        hintText: 'Buscar por recibo, cliente o suministro...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () => _buscarPorSuministro(busqueda),
          icon: const Icon(Icons.manage_search_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filtros = [
      {'value': 'TODOS', 'label': 'Todos'},
      {'value': 'PENDIENTE', 'label': 'Pendientes'},
      {'value': 'PAGADO', 'label': 'Pagados'},
      {'value': 'VENCIDO', 'label': 'Vencidos'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((item) {
          final selected = filtroEstado == item['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              selectedColor: secondary,
              backgroundColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFFE2EDF3),
              ),
              label: Text(
                item['label']!,
                style: TextStyle(
                  color: selected ? Colors.white : primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  filtroEstado = item['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return Container(
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
          Icon(
            icon,
            color: secondary,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciboCard extends StatelessWidget {
  final String codigoRecibo;
  final String codigoSuministro;
  final String cliente;
  final String direccion;
  final String periodo;
  final double consumo;
  final double total;
  final String vencimiento;
  final String estado;
  final bool puedeMarcarPagado;
  final VoidCallback onPagar;

  const _ReciboCard({
    required this.codigoRecibo,
    required this.codigoSuministro,
    required this.cliente,
    required this.direccion,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.vencimiento,
    required this.estado,
    required this.puedeMarcarPagado,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);
    const Color secondary = Color(0xFF1DA1C2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  codigoRecibo,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cliente,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suministro: $codigoSuministro',
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            direccion,
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Periodo',
                  value: periodo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Consumo',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Total',
                  value: 'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Vence',
                  value: vencimiento,
                ),
              ),
            ],
          ),
          if (puedeMarcarPagado) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: onPagar,
                icon: const Icon(Icons.payments_rounded),
                label: const Text(
                  'Registrar pago presencial',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final upper = estado.toUpperCase();

    Color bg;
    Color text;

    if (upper == 'PAGADO') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (upper == 'VENCIDO') {
      bg = const Color(0xFFFFECEC);
      text = const Color(0xFFD93025);
    } else {
      bg = const Color(0xFFFFF3DF);
      text = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: text,
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