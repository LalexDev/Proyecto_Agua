// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/services/pago_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminPagosPage extends StatefulWidget {
  const AdminPagosPage({super.key});

  @override
  State<AdminPagosPage> createState() => _AdminPagosPageState();
}

class _AdminPagosPageState extends State<AdminPagosPage> {
  final Color secondary = JassColors.secondary;
  final PagoService pagoService = PagoService();

  List<Map<String, dynamic>> pagos = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';
  String filtroEstado = 'TODOS';
  int? procesandoPagoId;

  @override
  void initState() {
    super.initState();
    cargarPagos();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    final text = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(text) ?? 0.0;
  }

  int? _idPago(Map<String, dynamic> pago) {
    final value = pago['id'] ?? pago['idPago'] ?? pago['pagoId'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _codigoRecibo(Map<String, dynamic> pago) {
    final recibo = pago['recibo'];

    if (recibo is Map) {
      return _txt(
        recibo['codigoRecibo'] ?? recibo['codigo'] ?? recibo['numeroRecibo'],
        'RECIBO',
      );
    }

    return _txt(
      pago['codigoRecibo'] ??
          pago['reciboCodigo'] ??
          pago['numeroRecibo'] ??
          pago['codigo'],
      'RECIBO',
    );
  }

  String _codigoOperacion(Map<String, dynamic> pago) {
    return _txt(
      pago['codigoOperacion'] ??
          pago['operacion'] ??
          pago['numeroOperacion'] ??
          pago['referencia'],
      'SIN OPERACIÓN',
    );
  }

  String _metodoPago(Map<String, dynamic> pago) {
    return _txt(
      pago['metodoPago'] ??
          pago['metodo'] ??
          pago['formaPago'] ??
          pago['tipoPago'],
      'Sin datos',
    );
  }

  String _estadoPago(Map<String, dynamic> pago) {
    return _txt(
      pago['estadoPago'] ?? pago['estado'] ?? pago['estadoPagoRecibo'],
      '-',
    ).toUpperCase();
  }

  String _estadoLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGO_EN_REVISION':
        return 'En revisión';
      case 'PAGADO_CONFIRMADO':
      case 'PAGADO':
        return 'Confirmado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return estado == '-' ? 'Sin estado' : estado;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGO_EN_REVISION':
        return Color(0xFFD97706);
      case 'PAGADO_CONFIRMADO':
      case 'PAGADO':
        return Color(0xFF047857);
      case 'RECHAZADO':
        return JassColors.danger;
      default:
        return context.jassTextMuted;
    }
  }

  Color _estadoBg(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGO_EN_REVISION':
        return Color(0xFFFFF3CD);
      case 'PAGADO_CONFIRMADO':
      case 'PAGADO':
        return Color(0xFFDDFBEA);
      case 'RECHAZADO':
        return Color(0xFFFFE1E1);
      default:
        return context.jassSurface;
    }
  }

  bool _enRevision(Map<String, dynamic> pago) {
    return _estadoPago(pago) == 'PAGO_EN_REVISION';
  }

  double _monto(Map<String, dynamic> pago) {
    return _num(
      pago['monto'] ??
          pago['montoPagado'] ??
          pago['total'] ??
          pago['importe'] ??
          pago['totalPagado'],
    );
  }

  String _fecha(Map<String, dynamic> pago) {
    return _txt(
      pago['fechaPago'] ??
          pago['fecha'] ??
          pago['fechaRegistro'] ??
          pago['createdAt'],
      '-',
    );
  }

  String _cliente(Map<String, dynamic> pago) {
    return _txt(
      pago['nombreCliente'] ??
          pago['cliente'] ??
          pago['titular'] ??
          pago['usuario'],
      '-',
    );
  }

  String _suministro(Map<String, dynamic> pago) {
    return _txt(
      pago['codigoSuministro'] ??
          pago['suministroCodigo'] ??
          pago['numeroSuministro'],
      '-',
    );
  }

  String _comprobanteUrl(Map<String, dynamic> pago) {
    return _txt(
      pago['comprobanteUrl'] ??
          pago['comprobante'] ??
          pago['urlComprobante'] ??
          pago['rutaComprobante'],
      '',
    );
  }

  bool _esPagoDelMes(Map<String, dynamic> pago) {
    final fechaTexto = _fecha(pago);
    final fecha = DateTime.tryParse(fechaTexto);

    if (fecha == null) return false;

    final now = DateTime.now();

    return fecha.year == now.year && fecha.month == now.month;
  }

  double get montoRecaudado {
    return pagos
        .where((pago) {
          final estado = _estadoPago(pago);
          return estado == 'PAGADO_CONFIRMADO' || estado == 'PAGADO';
        })
        .fold(0.0, (sum, pago) => sum + _monto(pago));
  }

  int get pagosDelMes {
    return pagos.where(_esPagoDelMes).length;
  }

  int get pagosEnRevision {
    return pagos.where(_enRevision).length;
  }

  String get metodoPrincipal {
    if (pagos.isEmpty) return 'Sin datos';

    final conteo = <String, int>{};

    for (final pago in pagos) {
      final metodo = _metodoPago(pago);
      conteo[metodo] = (conteo[metodo] ?? 0) + 1;
    }

    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ordenado.isEmpty ? 'Sin datos' : ordenado.first.key;
  }

  Map<String, int> get conteoMetodos {
    final data = <String, int>{};

    for (final pago in pagos) {
      final metodo = _metodoPago(pago);
      data[metodo] = (data[metodo] ?? 0) + 1;
    }

    return data;
  }

  int _conteoEstado(String estado) {
    if (estado == 'TODOS') return pagos.length;
    return pagos.where((pago) => _estadoPago(pago) == estado).length;
  }

  static const int _limiteInicialPagos = 60;
  static const int _limiteBusquedaPagos = 100;

  int get _limitePagosActual {
    return busqueda.trim().isEmpty ? _limiteInicialPagos : _limiteBusquedaPagos;
  }

  List<Map<String, dynamic>> get pagosFiltrados {
    final query = busqueda.trim().toLowerCase();

    return pagos.where((pago) {
      if (filtroEstado != 'TODOS' && _estadoPago(pago) != filtroEstado) {
        return false;
      }

      if (query.isEmpty) return true;

      final texto =
          '''
      ${_codigoRecibo(pago)}
      ${_codigoOperacion(pago)}
      ${_metodoPago(pago)}
      ${_cliente(pago)}
      ${_suministro(pago)}
      ${_fecha(pago)}
      ${_monto(pago)}
      ${_estadoLabel(_estadoPago(pago))}
      '''
              .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get pagosVisibles {
    final filtrados = pagosFiltrados;
    return filtrados.take(_limitePagosActual).toList(growable: false);
  }

  bool get _pagosLimitados {
    return pagosFiltrados.length > pagosVisibles.length;
  }

  Future<void> cargarPagos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await pagoService.listarPagos();

      if (!mounted) return;

      setState(() {
        pagos = data;
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

  void limpiarFiltros() {
    setState(() {
      busqueda = '';
      filtroEstado = 'TODOS';
    });
  }

  void _volverDashboard() {
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
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

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  String _fullComprobanteUrl(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    var host = ApiConfig.baseUrl.trim();
    if (host.endsWith('/api')) {
      host = host.substring(0, host.length - 4);
    }

    if (raw.startsWith('/')) {
      return '$host$raw';
    }

    return '$host/$raw';
  }

  void _snack(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? JassColors.danger : JassColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verComprobante(Map<String, dynamic> pago) async {
    final url = _fullComprobanteUrl(_comprobanteUrl(pago));

    if (url.isEmpty) {
      _snack('Este pago no tiene comprobante registrado.', error: true);
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              color: context.jassSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(18, 16, 12, 12),
                    decoration: BoxDecoration(
                      color: context.jassSelectedSurface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comprobante de pago',
                                style: TextStyle(
                                  color: context.jassTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _codigoRecibo(pago),
                                style: TextStyle(
                                  color: context.jassTextMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      minScale: 0.7,
                      maxScale: 4,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.65,
                          minHeight: 260,
                          minWidth: double.infinity,
                        ),
                        color: Colors.black.withOpacity(0.04),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: JassColors.danger,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No se pudo cargar el comprobante.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.jassTextPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    url,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.jassTextMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(Icons.check_rounded),
                        label: Text('Entendido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JassColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmarAccion({
    required Map<String, dynamic> pago,
    required bool aprobar,
  }) async {
    final titulo = aprobar ? 'Aprobar pago' : 'Rechazar pago';
    final mensaje = aprobar
        ? 'El recibo pasará a estado PAGADO. Verifica el comprobante antes de confirmar.'
        : 'El recibo volverá a estado PENDIENTE. El cliente deberá enviar un nuevo comprobante.';
    final color = aprobar ? Color(0xFF047857) : JassColors.danger;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              SizedBox(height: 12),
              _DialogLine(label: 'Recibo', value: _codigoRecibo(pago)),
              _DialogLine(
                label: 'Monto',
                value: 'S/ ${_monto(pago).toStringAsFixed(2)}',
              ),
              _DialogLine(label: 'Operación', value: _codigoOperacion(pago)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(aprobar ? 'Sí, aprobar' : 'Sí, rechazar'),
            ),
          ],
        );
      },
    );

    return confirmado == true;
  }

  Future<void> _cambiarEstadoPago(
    Map<String, dynamic> pago, {
    required bool aprobar,
  }) async {
    final idPago = _idPago(pago);

    if (idPago == null) {
      _snack('No se pudo identificar el pago seleccionado.', error: true);
      return;
    }

    if (!_enRevision(pago)) {
      _snack(
        'Solo se puede aprobar o rechazar un pago en revisión.',
        error: true,
      );
      return;
    }

    final confirmado = await _confirmarAccion(pago: pago, aprobar: aprobar);
    if (!confirmado) return;

    setState(() {
      procesandoPagoId = idPago;
    });

    try {
      if (aprobar) {
        await pagoService.aprobarPago(idPago);
      } else {
        await pagoService.rechazarPago(idPago);
      }

      _snack(
        aprobar
            ? 'Pago aprobado correctamente.'
            : 'Pago rechazado correctamente.',
      );

      await cargarPagos();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          procesandoPagoId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: -1,
        onTap: _go,
        onPlus: () {
          showAdminQuickMenu(context: context, onRefresh: cargarPagos);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarPagos,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                if (cargando)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _ErrorBox(error: error, onRetry: cargarPagos),
                if (!cargando && error.isEmpty) ...[
                  _buildStats(),
                  SizedBox(height: 18),
                  _buildAlertRevision(),
                  SizedBox(height: 18),
                  _buildMetodos(),
                  SizedBox(height: 18),
                  _buildSearch(),
                  SizedBox(height: 12),
                  _buildFiltrosEstado(),
                  SizedBox(height: 18),
                  _buildListado(),
                ],
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _volverDashboard,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagos / Recaudación',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pagos',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Revisa comprobantes y confirma pagos enviados por clientes.',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargarPagos,
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
                icon: Icons.hourglass_top_rounded,
                label: 'En revisión',
                value: '$pagosEnRevision',
                subtitle: 'Necesitan validación',
                selected: true,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.savings_rounded,
                label: 'Confirmado',
                value: 'S/ ${montoRecaudado.toStringAsFixed(2)}',
                subtitle: 'Recaudación válida',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_rounded,
                label: 'Pagos del mes',
                value: '$pagosDelMes',
                subtitle: 'Mes actual',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_rounded,
                label: 'Método principal',
                value: metodoPrincipal,
                subtitle: 'Método más usado',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertRevision() {
    if (pagosEnRevision == 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xFFDDFBEA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFFB8F0CF)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF047857)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No hay pagos pendientes de validación.',
                style: TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFFFE29A)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay $pagosEnRevision pago(s) en revisión. Verifica el comprobante antes de aprobar o rechazar.',
              style: TextStyle(
                color: Color(0xFF9A5B00),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodos() {
    final metodos = conteoMetodos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métodos de pago',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Distribución de pagos por método de cobranza.',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          if (metodos.isEmpty)
            Text(
              'Sin métodos registrados.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...metodos.map((entry) {
              return _MetodoLine(
                metodo: entry.key,
                cantidad: entry.value,
                total: pagos.length,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                busqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar recibo, operación, método o fecha...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: context.jassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: limpiarFiltros,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.jassSurface,
            foregroundColor: context.jassTextPrimary,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.jassBorder),
            ),
          ),
          child: Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildFiltrosEstado() {
    final filtros = [
      ('TODOS', 'Todos'),
      ('PAGO_EN_REVISION', 'Revisión'),
      ('PAGADO_CONFIRMADO', 'Confirmados'),
      ('RECHAZADO', 'Rechazados'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((item) {
          final selected = filtroEstado == item.$1;
          final color = item.$1 == 'TODOS'
              ? JassColors.primary
              : _estadoColor(item.$1);

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) {
                setState(() {
                  filtroEstado = item.$1;
                });
              },
              label: Text('${item.$2} (${_conteoEstado(item.$1)})'),
              selectedColor: color.withOpacity(0.16),
              backgroundColor: context.jassSurface,
              labelStyle: TextStyle(
                color: selected ? color : context.jassTextMuted,
                fontWeight: FontWeight.w900,
              ),
              side: BorderSide(color: selected ? color : context.jassBorder),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListado() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pagos registrados',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${pagosFiltrados.length} resultado(s)',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (pagosFiltrados.isEmpty)
            Text(
              'No hay pagos para mostrar.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            if (_pagosLimitados)
              _LimitNotice(
                texto:
                    'Mostrando ${pagosVisibles.length} de ${pagosFiltrados.length} pagos. Usa el buscador para encontrar pagos específicos.',
              ),
            ...pagosVisibles.map((pago) {
              final id = _idPago(pago);
              return RepaintBoundary(
                child: _PagoCard(
                  recibo: _codigoRecibo(pago),
                  metodo: _metodoPago(pago),
                  operacion: _codigoOperacion(pago),
                  monto: _monto(pago),
                  fecha: _fecha(pago),
                  cliente: _cliente(pago),
                  suministro: _suministro(pago),
                  estado: _estadoPago(pago),
                  estadoLabel: _estadoLabel(_estadoPago(pago)),
                  estadoColor: _estadoColor(_estadoPago(pago)),
                  estadoBg: _estadoBg(_estadoPago(pago)),
                  tieneComprobante: _comprobanteUrl(pago).isNotEmpty,
                  enRevision: _enRevision(pago),
                  procesando: id != null && procesandoPagoId == id,
                  onVerComprobante: () => _verComprobante(pago),
                  onAprobar: () => _cambiarEstadoPago(pago, aprobar: true),
                  onRechazar: () => _cambiarEstadoPago(pago, aprobar: false),
                ),
              );
            }),
          ],
        ],
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final bool selected;

  _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? JassColors.primary : context.jassSurface;
    final text = selected ? Colors.white : context.jassTextPrimary;
    final sub = selected ? Color(0xFFE7F8FF) : context.jassTextMuted;

    return Container(
      constraints: BoxConstraints(minHeight: 118),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? Colors.white : JassColors.secondary),
          SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoLine extends StatelessWidget {
  final String metodo;
  final int cantidad;
  final int total;

  _MetodoLine({
    required this.metodo,
    required this.cantidad,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = total <= 0 ? 0.0 : cantidad / total;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
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
            metodo,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: porcentaje,
            minHeight: 7,
            borderRadius: BorderRadius.circular(100),
          ),
          SizedBox(height: 6),
          Text(
            '$cantidad pago(s)',
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PagoCard extends StatelessWidget {
  final String recibo;
  final String metodo;
  final String operacion;
  final double monto;
  final String fecha;
  final String cliente;
  final String suministro;
  final String estado;
  final String estadoLabel;
  final Color estadoColor;
  final Color estadoBg;
  final bool tieneComprobante;
  final bool enRevision;
  final bool procesando;
  final VoidCallback onVerComprobante;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  _PagoCard({
    required this.recibo,
    required this.metodo,
    required this.operacion,
    required this.monto,
    required this.fecha,
    required this.cliente,
    required this.suministro,
    required this.estado,
    required this.estadoLabel,
    required this.estadoColor,
    required this.estadoBg,
    required this.tieneComprobante,
    required this.enRevision,
    required this.procesando,
    required this.onVerComprobante,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.jassSelectedSurface,
                child: Icon(Icons.receipt_long_rounded, color: secondary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recibo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: estadoBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        estadoLabel,
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'S/ ${monto.toStringAsFixed(2)}',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _Line(label: 'Método', value: metodo),
          _Line(label: 'Operación', value: operacion),
          _Line(label: 'Fecha', value: fecha),
          _Line(label: 'Cliente', value: cliente),
          _Line(label: 'Suministro', value: suministro),
          SizedBox(height: 12),
          if (procesando)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.jassSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Procesando pago...',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniActionButton(
                  icon: Icons.image_search_rounded,
                  label: 'Comprobante',
                  color: JassColors.primary,
                  enabled: tieneComprobante,
                  onPressed: onVerComprobante,
                ),
                if (enRevision) ...[
                  _MiniActionButton(
                    icon: Icons.check_circle_rounded,
                    label: 'Aprobar',
                    color: Color(0xFF047857),
                    onPressed: onAprobar,
                  ),
                  _MiniActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Rechazar',
                    color: JassColors.danger,
                    onPressed: onRechazar,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  _MiniActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : context.jassBorder,
        foregroundColor: enabled ? Colors.white : context.jassTextMuted,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
      ),
    );
  }
}

class _DialogLine extends StatelessWidget {
  final String label;
  final String value;

  _DialogLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  _ErrorBox({required this.error, required this.onRetry});

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
