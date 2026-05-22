import 'package:flutter/material.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../core/services/recibo_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final ClientePortalService clientePortalService = ClientePortalService();
  final ReciboService reciboService = ReciboService();

  Map<String, dynamic>? perfil;
  List<Map<String, dynamic>> suministros = [];
  List<Map<String, dynamic>> recibos = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final perfilData = await clientePortalService.obtenerMiPerfil();
      final suministrosData =
          await clientePortalService.listarMisSuministros();
      final recibosData = await reciboService.listarMisRecibos();

      if (!mounted) return;

      setState(() {
        perfil = perfilData;
        suministros = suministrosData;
        recibos = recibosData;
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

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _total(Map<String, dynamic> recibo) {
    return _numero(
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  String get nombreCliente {
    final nombres = _texto(perfil?['nombres'], '');
    final apellidos = _texto(perfil?['apellidos'], '');

    final nombreCompleto = '$nombres $apellidos'.trim();

    if (nombreCompleto.isEmpty) {
      return 'Cliente';
    }

    return _capitalizar(nombreCompleto);
  }

  String _capitalizar(String texto) {
    return texto
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) {
          final lower = p.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  double get deudaPendiente {
    return recibos.where((recibo) {
      final estado = _estado(recibo);
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) {
      return sum + _total(recibo);
    });
  }

  int get totalSuministros {
    return suministros.length;
  }

  double get consumoUltimoMes {
    if (recibos.isEmpty) {
      return 0;
    }

    final recibosOrdenados = [...recibos];

    recibosOrdenados.sort((a, b) {
      final anioA = int.tryParse('${a['anio'] ?? 0}') ?? 0;
      final mesA = int.tryParse('${a['mes'] ?? 0}') ?? 0;
      final anioB = int.tryParse('${b['anio'] ?? 0}') ?? 0;
      final mesB = int.tryParse('${b['mes'] ?? 0}') ?? 0;

      final fechaA = anioA * 100 + mesA;
      final fechaB = anioB * 100 + mesB;

      return fechaB.compareTo(fechaA);
    });

    return _consumo(recibosOrdenados.first);
  }

  Map<String, dynamic>? get reciboPendiente {
    try {
      return recibos.firstWhere((recibo) {
        final estado = _estado(recibo);
        return estado == 'PENDIENTE' || estado == 'VENCIDO';
      });
    } catch (_) {
      return null;
    }
  }

  void irRecibos() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void irPerfil() {
    Navigator.pushReplacementNamed(context, '/perfil');
  }

  void irPagar() {
    final recibo = reciboPendiente;

    if (recibo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes recibos pendientes para pagar.'),
          backgroundColor: Color(0xFF1F8F4D),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/pago-cip',
      arguments: recibo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _ClienteBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            irRecibos();
          }

          if (index == 2) {
            irPerfil();
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 22),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) ...[
                  _buildWelcomeCard(),
                  const SizedBox(height: 18),
                  _buildStats(),
                  const SizedBox(height: 24),
                  const Text(
                    'Accesos rápidos',
                    style: TextStyle(
                      color: primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JASS Huacariz',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Portal móvil del cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: irPerfil,
          icon: const Icon(
            Icons.account_circle_outlined,
            color: primary,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando información...',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD93025),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD93025),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: cargarDatos,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Bienvenido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Hola, $nombreCliente',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consulta tus recibos, suministros y pagos del servicio de agua potable.',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deuda total pendiente',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'S/ ${deudaPendiente.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
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

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.water_drop_outlined,
            label: 'Suministros',
            value: '$totalSuministros',
            subLabel: 'Asociados',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatBox(
            icon: Icons.bar_chart_rounded,
            label: 'Consumo',
            value: '${consumoUltimoMes.toStringAsFixed(0)} m³',
            subLabel: 'Último mes',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
  return Row(
    children: [
      Expanded(
        child: _QuickAction(
          icon: Icons.receipt_long_rounded,
          label: 'Recibos',
          onTap: irRecibos,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _QuickAction(
          icon: Icons.payments_rounded,
          label: 'Pagos',
          onTap: irPagar,
        ),
      ),
    ],
  );
}
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: secondary,
            size: 30,
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
  height: 96,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE2EDF3)),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        color: secondary,
        size: 28,
      ),
      const SizedBox(height: 8),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: primary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}

class _ClienteBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ClienteBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 76,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}