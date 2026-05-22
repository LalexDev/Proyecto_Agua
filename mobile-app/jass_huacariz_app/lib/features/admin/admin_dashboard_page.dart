import 'package:flutter/material.dart';

import '../../core/services/cliente_service.dart';
import '../../core/services/recibo_service.dart';
import '../../core/services/pago_service.dart';
import '../../core/storage/secure_storage_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final ClienteService clienteService = ClienteService();
  final ReciboService reciboService = ReciboService();
  final PagoService pagoService = PagoService();
  final SecureStorageService storageService = SecureStorageService();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> recibos = [];
  List<Map<String, dynamic>> pagos = [];
  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDashboard();
  }

  Future<void> cargarDashboard() async {
    setState(() { cargando = true; error = ''; });
    try {
      final data = await Future.wait([
        clienteService.listarClientes(),
        reciboService.listarRecibosAdmin(),
        pagoService.listarPagos(),
      ]);
      if (!mounted) return;
      setState(() {
        clientes = data[0];
        recibos = data[1];
        pagos = data[2];
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceFirst('Exception: ', ''); cargando = false; });
    }
  }

  String _estado(Map<String, dynamic> r) => (r['estadoRecibo'] ?? r['estado'] ?? '').toString().toUpperCase();
  double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  int get totalClientes => clientes.length;
  int get recibosPendientes => recibos.where((r) => _estado(r) == 'PENDIENTE').length;
  int get recibosPagados => recibos.where((r) => _estado(r) == 'PAGADO').length;
  int get recibosVencidos => recibos.where((r) => _estado(r) == 'VENCIDO').length;
  double get moraAcumulada => recibos.fold(0, (s, r) => s + _num(r['mora'] ?? r['montoMora']));
  int get lecturasMes => recibos.length;
  double get recaudacion => pagos.fold(0, (s, p) => s + _num(p['monto']));

  Future<void> cerrarSesion() async {
    await storageService.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(currentIndex: 0, onTap: _go),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Panel del administrador', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Inicio', style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w900)),
                ])),
                IconButton(onPressed: cerrarSesion, icon: const Icon(Icons.logout_rounded, color: primary)),
              ]),
              const SizedBox(height: 18),
              Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [primary, secondary]), borderRadius: BorderRadius.circular(28)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('JASS Huacariz Agua Potable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Resumen operativo', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('Control mensual de clientes, recibos, estados de pago y mora acumulada.', style: TextStyle(color: Color(0xFFE7F8FF), height: 1.4)),
              ])),
              const SizedBox(height: 18),
              if (cargando) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (error.isNotEmpty) _ErrorBox(error: error, onRetry: cargarDashboard),
              if (!cargando && error.isEmpty) ...[
                GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.18, children: [
                  _Stat(icon: Icons.groups_rounded, label: 'Total de clientes', value: '$totalClientes'),
                  _Stat(icon: Icons.pending_actions_rounded, label: 'Recibos pendientes', value: '$recibosPendientes'),
                  _Stat(icon: Icons.check_circle_rounded, label: 'Recibos pagados', value: '$recibosPagados'),
                  _Stat(icon: Icons.warning_rounded, label: 'Recibos vencidos', value: '$recibosVencidos'),
                  _Stat(icon: Icons.payments_rounded, label: 'Recaudación', value: 'S/ ${recaudacion.toStringAsFixed(2)}'),
                  _Stat(icon: Icons.calendar_month_rounded, label: 'Lecturas del mes', value: '$lecturasMes'),
                ]),
                const SizedBox(height: 18),
                const Text('Accesos rápidos', style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Quick(label: 'Clientes', icon: Icons.people_alt_rounded, onTap: () => Navigator.pushNamed(context, '/admin-clientes'))),
                  const SizedBox(width: 10),
                  Expanded(child: _Quick(label: 'Recibos', icon: Icons.receipt_long_rounded, onTap: () => Navigator.pushNamed(context, '/admin-recibos'))),
                  const SizedBox(width: 10),
                  Expanded(child: _Quick(label: 'Reportes', icon: Icons.bar_chart_rounded, onTap: () => Navigator.pushNamed(context, '/admin-reportes'))),
                ]),
              ]
            ]),
          ),
        ),
      ),
    );
  }
  void _go(int i) { if (i==1) Navigator.pushReplacementNamed(context,'/admin-clientes'); if (i==2) Navigator.pushReplacementNamed(context,'/admin-tarifas'); if (i==3) Navigator.pushReplacementNamed(context,'/admin-recibos'); if (i==4) Navigator.pushReplacementNamed(context,'/admin-reportes'); }
}

class _Stat extends StatelessWidget { final IconData icon; final String label; final String value; const _Stat({required this.icon, required this.label, required this.value}); @override Widget build(BuildContext context){ return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Color(0xFFE2EDF3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Color(0xFF1DA1C2)), const Spacer(), Text(value, style: const TextStyle(color: Color(0xFF0F3D57), fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Color(0xFF7B8794), fontWeight: FontWeight.w800, fontSize: 12))])); }}
class _Quick extends StatelessWidget { final String label; final IconData icon; final VoidCallback onTap; const _Quick({required this.label, required this.icon, required this.onTap}); @override Widget build(BuildContext context){ return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(height: 82, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Color(0xFFE2EDF3))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Color(0xFF1DA1C2)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F3D57)))]))); }}
class _ErrorBox extends StatelessWidget { final String error; final VoidCallback onRetry; const _ErrorBox({required this.error, required this.onRetry}); @override Widget build(BuildContext context){ return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Color(0xFFFFECEC), borderRadius: BorderRadius.circular(18)), child: Column(children: [Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD93025), fontWeight: FontWeight.w800)), TextButton(onPressed: onRetry, child: const Text('Reintentar'))])); }}
class _AdminBottomNav extends StatelessWidget { final int currentIndex; final Function(int) onTap; const _AdminBottomNav({required this.currentIndex, required this.onTap}); @override Widget build(BuildContext context){ return NavigationBar(selectedIndex: currentIndex, onDestinationSelected: onTap, height: 76, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'), NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Clientes'), NavigationDestination(icon: Icon(Icons.attach_money_rounded), label: 'Tarifas'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Recibos'), NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Reportes')]); }}
