// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/recibo_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminRecibosPage extends StatefulWidget {
  const AdminRecibosPage({super.key});

  @override
  State<AdminRecibosPage> createState() => _AdminRecibosPageState();
}

class _AdminRecibosPageState extends State<AdminRecibosPage> {
  final Color secondary = JassColors.secondary;
  final ReciboService reciboService = ReciboService();

  List<Map<String, dynamic>> recibos = [];
  final Set<int> recibosSeleccionados = {};

  bool cargando = false;
  String error = '';
  String busqueda = '';
  String filtroEstado = 'TODOS';

  final List<Map<String, dynamic>> metodosPago = [
    {'value': 'EFECTIVO', 'label': 'Efectivo', 'icon': Icons.payments_rounded},
    {'value': 'YAPE', 'label': 'Yape', 'icon': Icons.qr_code_2_rounded},
    {'value': 'PLIN', 'label': 'Plin', 'icon': Icons.phone_android_rounded},
    {
      'value': 'TRANSFERENCIA',
      'label': 'Transferencia',
      'icon': Icons.account_balance_rounded,
    },
  ];

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

  String _clienteKey(Map<String, dynamic> recibo) {
    return _txt(
      recibo['clienteId'] ??
          recibo['idCliente'] ??
          recibo['dniCliente'] ??
          recibo['dni'] ??
          recibo['documento'] ??
          _cliente(recibo),
      _cliente(recibo),
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
    return _txt(recibo['fechaVencimiento'] ?? recibo['vencimiento']);
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

  static const int _limiteInicialRecibos = 60;
  static const int _limiteBusquedaRecibos = 100;

  int get _limiteRecibosActual {
    return busqueda.trim().isEmpty
        ? _limiteInicialRecibos
        : _limiteBusquedaRecibos;
  }

  List<Map<String, dynamic>> get recibosFiltrados {
    final query = busqueda.trim().toLowerCase();

    return recibos.where((recibo) {
      final estado = _estado(recibo);

      final cumpleEstado = filtroEstado == 'TODOS'
          ? true
          : estado == filtroEstado;

      final texto =
          '''
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

  List<Map<String, dynamic>> get recibosVisibles {
    final filtrados = recibosFiltrados;
    return filtrados.take(_limiteRecibosActual).toList(growable: false);
  }

  bool get _recibosLimitados {
    return recibosFiltrados.length > recibosVisibles.length;
  }

  List<Map<String, dynamic>> get seleccionados {
    return recibos.where((recibo) {
      return recibosSeleccionados.contains(_idRecibo(recibo));
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
    return recibos
        .where((r) {
          final estado = _estado(r);
          return estado == 'PENDIENTE' || estado == 'VENCIDO';
        })
        .fold(0.0, (sum, recibo) => sum + _total(recibo));
  }

  double get totalSeleccionado {
    return seleccionados.fold(0.0, (sum, recibo) => sum + _total(recibo));
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
        recibosSeleccionados.removeWhere((id) {
          return !recibos.any((recibo) => _idRecibo(recibo) == id);
        });
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
        recibosSeleccionados.clear();
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

  void _toggleSeleccion(Map<String, dynamic> recibo) {
    final idRecibo = _idRecibo(recibo);

    if (idRecibo <= 0) {
      _mensaje('No se encontró el ID del recibo.', true);
      return;
    }

    if (!_puedeMarcarPagado(recibo)) {
      _mensaje('Solo puedes cobrar recibos pendientes o vencidos.', true);
      return;
    }

    final estaSeleccionado = recibosSeleccionados.contains(idRecibo);

    if (estaSeleccionado) {
      setState(() {
        recibosSeleccionados.remove(idRecibo);
      });
      return;
    }

    if (seleccionados.isNotEmpty) {
      final clienteActual = _clienteKey(seleccionados.first);
      final clienteNuevo = _clienteKey(recibo);

      if (clienteActual != clienteNuevo) {
        _mensaje(
          'Solo puedes seleccionar recibos del mismo cliente para registrar un pago conjunto.',
          true,
        );
        return;
      }
    }

    setState(() {
      recibosSeleccionados.add(idRecibo);
    });
  }

  Future<void> _cobrarSolo(Map<String, dynamic> recibo) async {
    await _abrirPagoPresencial([recibo]);
  }

  Future<void> _cobrarSeleccion() async {
    final lista = seleccionados;

    if (lista.isEmpty) {
      _mensaje('Selecciona al menos un recibo pendiente.', true);
      return;
    }

    await _abrirPagoPresencial(lista);
  }

  Future<void> _abrirPagoPresencial(
    List<Map<String, dynamic>> recibosPago,
  ) async {
    final recibosValidos = recibosPago.where(_puedeMarcarPagado).toList();

    if (recibosValidos.isEmpty) {
      _mensaje('No hay recibos pendientes para cobrar.', true);
      return;
    }

    final clienteBase = _clienteKey(recibosValidos.first);
    final mezclaClientes = recibosValidos.any(
      (r) => _clienteKey(r) != clienteBase,
    );

    if (mezclaClientes) {
      _mensaje(
        'Solo puedes cobrar varios recibos si pertenecen al mismo cliente.',
        true,
      );
      return;
    }

    final total = recibosValidos.fold(
      0.0,
      (sum, recibo) => sum + _total(recibo),
    );
    final cantidadCobrada = recibosValidos.length;

    final resultado = await showDialog<_PagoPresencialResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _CobranzaPagoDialog(
          cliente: _cliente(recibosValidos.first),
          recibos: recibosValidos,
          total: total,
          metodosPago: metodosPago,
          codigoRecibo: _codigoRecibo,
          periodo: _periodo,
          totalRecibo: _total,
        );
      },
    );

    if (resultado == null || !mounted) return;

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      for (final recibo in recibosValidos) {
        final idRecibo = _idRecibo(recibo);

        if (idRecibo <= 0) continue;

        await reciboService.pagarReciboAdmin(
          idRecibo: idRecibo,
          metodoPago: resultado.metodoPago,
          codigoOperacion: resultado.codigoOperacion,
        );
      }

      if (!mounted) return;

      setState(() {
        recibosSeleccionados.clear();
      });

      await cargarRecibos();

      if (!mounted) return;

      _mensaje(
        cantidadCobrada == 1
            ? 'Recibo cobrado correctamente.'
            : '$cantidadCobrada recibos cobrados correctamente.',
        false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void _mensaje(String mensaje, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? JassColors.danger : JassColors.success,
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
    if (index == 3) return;
  }

  void _abrirMenuRapido() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarRecibos,
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recibosSeleccionados.isNotEmpty) _buildSelectionBar(),
          AdminBottomNav(currentIndex: 3, onTap: _go, onPlus: _abrirMenuRapido),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarRecibos,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                _buildStats(),
                SizedBox(height: 16),
                _buildCobranzaInfo(),
                SizedBox(height: 16),
                _buildSearch(),
                SizedBox(height: 14),
                _buildFilters(),
                SizedBox(height: 16),
                if (cargando)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(error: error, onRetry: cargarRecibos),
                if (!cargando && error.isEmpty && recibosFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay recibos para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty && _recibosLimitados)
                  _LimitNotice(
                    texto:
                        'Mostrando ${recibosVisibles.length} de ${recibosFiltrados.length} recibos. Usa el buscador para encontrar recibos específicos.',
                  ),
                if (!cargando && error.isEmpty)
                  ...recibosVisibles.map((recibo) {
                    final id = _idRecibo(recibo);
                    final seleccionado = recibosSeleccionados.contains(id);

                    return RepaintBoundary(
                      child: _ReciboCard(
                        codigoRecibo: _codigoRecibo(recibo),
                        codigoSuministro: _codigoSuministro(recibo),
                        cliente: _cliente(recibo),
                        direccion: _direccion(recibo),
                        periodo: _periodo(recibo),
                        consumo: _consumo(recibo),
                        total: _total(recibo),
                        vencimiento: _vencimiento(recibo),
                        estado: _estado(recibo),
                        seleccionado: seleccionado,
                        puedeMarcarPagado: _puedeMarcarPagado(recibo),
                        onToggle: () => _toggleSeleccion(recibo),
                        onPagar: () => _cobrarSolo(recibo),
                      ),
                    );
                  }),
                if (recibosSeleccionados.isNotEmpty) SizedBox(height: 110),
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
                'Cobranza de recibos',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cobranza',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Selecciona uno o varios recibos del mismo cliente y registra el pago presencial.',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargarRecibos,
          icon: Icon(Icons.refresh_rounded, color: context.jassTextPrimary),
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
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pendientes',
                value: '$pendientes',
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pagados',
                value: '$pagados',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Vencidos',
                value: '$vencidos',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _StatCard(
            label: 'Deuda pendiente',
            value: 'S/ ${deudaTotal.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCobranzaInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSelectedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: secondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Para cobrar varios recibos, selecciona recibos pendientes o vencidos del mismo cliente. No se mezclan clientes en un solo pago.',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
        prefixIcon: Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () => _buscarPorSuministro(busqueda),
          icon: Icon(Icons.manage_search_rounded),
        ),
        filled: true,
        fillColor: context.jassSurface,
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
            padding: EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              selectedColor: secondary,
              backgroundColor: context.jassSurface,
              side: BorderSide(color: context.jassBorder),
              label: Text(
                item['label']!,
                style: TextStyle(
                  color: selected ? Colors.white : context.jassTextPrimary,
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

  Widget _buildSelectionBar() {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(18, 0, 18, 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: secondary.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: context.jassShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${recibosSeleccionados.length} recibo(s) seleccionado(s)',
                        style: TextStyle(
                          color: context.jassTextPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Total: S/ ${totalSeleccionado.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Limpiar selección',
                  onPressed: () {
                    setState(() => recibosSeleccionados.clear());
                  },
                  icon: Icon(Icons.close_rounded, color: context.jassTextMuted),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _cobrarSeleccion,
                icon: Icon(Icons.point_of_sale_rounded),
                label: Text(
                  'Registrar pago presencial',
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

class _PagoPresencialResult {
  final String metodoPago;
  final String codigoOperacion;

  const _PagoPresencialResult({
    required this.metodoPago,
    required this.codigoOperacion,
  });
}

class _CobranzaPagoDialog extends StatefulWidget {
  final String cliente;
  final List<Map<String, dynamic>> recibos;
  final double total;
  final List<Map<String, dynamic>> metodosPago;
  final String Function(Map<String, dynamic>) codigoRecibo;
  final String Function(Map<String, dynamic>) periodo;
  final double Function(Map<String, dynamic>) totalRecibo;

  const _CobranzaPagoDialog({
    required this.cliente,
    required this.recibos,
    required this.total,
    required this.metodosPago,
    required this.codigoRecibo,
    required this.periodo,
    required this.totalRecibo,
  });

  @override
  State<_CobranzaPagoDialog> createState() => _CobranzaPagoDialogState();
}

class _CobranzaPagoDialogState extends State<_CobranzaPagoDialog> {
  final TextEditingController codigoOperacionController =
      TextEditingController();
  String metodoPago = 'EFECTIVO';

  @override
  void dispose() {
    codigoOperacionController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final esEfectivo = metodoPago == 'EFECTIVO';
    final codigoTexto = codigoOperacionController.text.trim();

    if (!esEfectivo && codigoTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingrese el código de operación del pago.'),
          backgroundColor: JassColors.danger,
        ),
      );
      return;
    }

    final codigoOperacion = codigoTexto.isEmpty
        ? 'PRESENCIAL-${DateTime.now().millisecondsSinceEpoch}'
        : codigoTexto;

    Navigator.of(context).pop(
      _PagoPresencialResult(
        metodoPago: metodoPago,
        codigoOperacion: codigoOperacion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;

    return Dialog(
      backgroundColor: context.jassSurface,
      insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.point_of_sale_rounded, color: secondary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar cobranza',
                          style: TextStyle(
                            color: context.jassTextPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Pago presencial de recibos',
                          style: TextStyle(
                            color: context.jassTextMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _ModalInfoCard(
                title: 'Cliente',
                value: widget.cliente,
                icon: Icons.person_rounded,
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.jassSurfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.jassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recibos seleccionados',
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...widget.recibos.map((recibo) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.codigoRecibo(recibo)} · ${widget.periodo(recibo)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.jassTextMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'S/ ${widget.totalRecibo(recibo).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.jassTextPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 12),
              _ModalInfoCard(
                title: 'Total a cobrar',
                value: 'S/ ${widget.total.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_rounded,
                destacado: true,
              ),
              SizedBox(height: 18),
              Text(
                'Método de pago',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.metodosPago.map((metodo) {
                  final selected = metodoPago == metodo['value'];

                  return ChoiceChip(
                    selected: selected,
                    selectedColor: secondary,
                    backgroundColor: context.jassSurfaceAlt,
                    side: BorderSide(
                      color: selected ? secondary : context.jassBorder,
                    ),
                    avatar: Icon(
                      metodo['icon'] as IconData,
                      size: 18,
                      color: selected ? Colors.white : secondary,
                    ),
                    label: Text(
                      metodo['label'].toString(),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : context.jassTextPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        metodoPago = metodo['value'].toString();
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 14),
              TextField(
                controller: codigoOperacionController,
                decoration: InputDecoration(
                  labelText: metodoPago == 'EFECTIVO'
                      ? 'Código de operación (opcional)'
                      : 'Código de operación',
                  hintText: metodoPago == 'EFECTIVO'
                      ? 'Se generará automáticamente si lo dejas vacío'
                      : 'Ejemplo: OP-123456',
                  filled: true,
                  fillColor: context.jassSurfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: JassColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si seleccionas varios recibos, se registrará un pago por cada recibo para mantener correcto el historial.',
                        style: TextStyle(
                          color: JassColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.jassTextPrimary,
                        side: BorderSide(color: context.jassBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmar,
                      icon: Icon(Icons.check_circle_rounded),
                      label: Text(
                        'Confirmar',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondary, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.jassTextMuted,
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
  final bool seleccionado;
  final bool puedeMarcarPagado;
  final VoidCallback onToggle;
  final VoidCallback onPagar;

  _ReciboCard({
    required this.codigoRecibo,
    required this.codigoSuministro,
    required this.cliente,
    required this.direccion,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.vencimiento,
    required this.estado,
    required this.seleccionado,
    required this.puedeMarcarPagado,
    required this.onToggle,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;

    return InkWell(
      onTap: puedeMarcarPagado ? onToggle : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado
              ? context.jassSelectedSurface
              : context.jassSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: seleccionado ? secondary : context.jassBorder,
            width: seleccionado ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (puedeMarcarPagado) ...[
                  Checkbox(
                    value: seleccionado,
                    activeColor: secondary,
                    onChanged: (_) => onToggle(),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    codigoRecibo,
                    style: TextStyle(
                      color: context.jassTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _EstadoBadge(estado: estado),
              ],
            ),
            SizedBox(height: 8),
            Text(
              cliente,
              style: TextStyle(
                color: context.jassTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Suministro: $codigoSuministro',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              direccion,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniInfo(label: 'Periodo', value: periodo),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MiniInfo(
                    label: 'Consumo',
                    value: '${consumo.toStringAsFixed(2)} m³',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    label: 'Total',
                    value: 'S/ ${total.toStringAsFixed(2)}',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MiniInfo(label: 'Vence', value: vencimiento),
                ),
              ],
            ),
            if (puedeMarcarPagado) ...[
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onToggle,
                      icon: Icon(
                        seleccionado
                            ? Icons.check_circle_rounded
                            : Icons.add_task_rounded,
                      ),
                      label: Text(
                        seleccionado ? 'Seleccionado' : 'Seleccionar',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: seleccionado
                            ? JassColors.success
                            : secondary,
                        side: BorderSide(
                          color: seleccionado
                              ? JassColors.success
                              : context.jassBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPagar,
                      icon: Icon(Icons.payments_rounded),
                      label: Text(
                        'Cobrar',
                        style: TextStyle(fontWeight: FontWeight.w900),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModalInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool destacado;

  _ModalInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destacado ? JassColors.secondary : context.jassTextPrimary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: destacado ? 22 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
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

  _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final upper = estado.toUpperCase();

    Color bg;
    Color text;

    if (upper == 'PAGADO') {
      bg = Color(0xFFEAF8EF);
      text = JassColors.success;
    } else if (upper == 'VENCIDO') {
      bg = Color(0xFFFFECEC);
      text = JassColors.danger;
    } else {
      bg = Color(0xFFFFF3DF);
      text = JassColors.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
