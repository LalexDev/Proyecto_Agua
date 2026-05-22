import 'package:flutter/material.dart';

import '../../core/services/tarifa_service.dart';

class AdminTarifasPage extends StatefulWidget {
  const AdminTarifasPage({super.key});

  @override
  State<AdminTarifasPage> createState() => _AdminTarifasPageState();
}

class _AdminTarifasPageState extends State<AdminTarifasPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final TarifaService service = TarifaService();
  List<Map<String, dynamic>> tarifas = [];
  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  String _txt(dynamic v, [String f = '-']) {
    if (v == null) return f;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? f : s;
  }

  double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  int _id(Map<String, dynamic> t) {
    if (t['id'] is int) return t['id'];
    return int.tryParse('${t['id'] ?? 0}') ?? 0;
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await service.listarTarifas();
      if (!mounted) return;
      setState(() {
        tarifas = data;
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

  Future<void> guardar({Map<String, dynamic>? actual}) async {
    final nombre = TextEditingController(text: _txt(actual?['nombreTarifa'], ''));
    final desde = TextEditingController(text: actual == null ? '0' : '${actual['consumoDesde'] ?? 0}');
    final hasta = TextEditingController(text: actual?['consumoHasta']?.toString() ?? '');
    final precio = TextEditingController(text: actual == null ? '0.00' : '${actual['precioM3'] ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(actual == null ? 'Nueva tarifa' : 'Editar tarifa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre tarifa')),
              TextField(controller: desde, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Consumo desde')),
              TextField(controller: hasta, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Consumo hasta (vacío = sin límite)')),
              TextField(controller: precio, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio m³')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok != true) return;

    final payload = {
      'nombreTarifa': nombre.text.trim(),
      'consumoDesde': double.tryParse(desde.text.trim()) ?? 0,
      'consumoHasta': hasta.text.trim().isEmpty ? null : double.tryParse(hasta.text.trim()),
      'precioM3': double.tryParse(precio.text.trim()) ?? 0,
      'estado': actual?['estado'] ?? true,
    };

    try {
      if (actual == null) {
        await service.registrarTarifa(payload);
      } else {
        await service.actualizarTarifa(_id(actual), payload);
      }
      await cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD93025),
        ),
      );
    }
  }

  Future<void> cambiarEstado(Map<String, dynamic> tarifa) async {
    try {
      await service.cambiarEstadoTarifa(
        id: _id(tarifa),
        estado: !(tarifa['estado'] == true),
      );
      await cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD93025),
        ),
      );
    }
  }

  void _go(int i) {
    if (i == 0) Navigator.pushReplacementNamed(context, '/admin-dashboard');
    if (i == 1) Navigator.pushReplacementNamed(context, '/admin-clientes');
    if (i == 3) Navigator.pushReplacementNamed(context, '/admin-recibos');
    if (i == 4) Navigator.pushReplacementNamed(context, '/admin-reportes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(currentIndex: 2, onTap: _go),
      floatingActionButton: FloatingActionButton(
        onPressed: () => guardar(),
        backgroundColor: secondary,
        child: const Icon(Icons.add),
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
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Configuración', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Tarifas de pago', style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: cargar, icon: const Icon(Icons.refresh, color: primary)),
                  ],
                ),
                const SizedBox(height: 16),
                if (cargando) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                if (error.isNotEmpty) _Error(error: error, onRetry: cargar),
                if (!cargando && error.isEmpty)
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: tarifas.map((tarifa) {
                        return ListTile(
                          title: Text(
                            _txt(tarifa['nombreTarifa']),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: primary),
                          ),
                          subtitle: Text(
                            'Desde ${_num(tarifa['consumoDesde']).toStringAsFixed(0)} hasta ${tarifa['consumoHasta'] ?? '∞'} m³ · ${tarifa['estado'] == true ? 'Activo' : 'Inactivo'}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'S/ ${_num(tarifa['precioM3']).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: primary),
                              ),
                              IconButton(
                                onPressed: () => guardar(actual: tarifa),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              Switch(
                                value: tarifa['estado'] == true,
                                onChanged: (_) => cambiarEstado(tarifa),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _Error({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD93025), fontWeight: FontWeight.w800)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AdminBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 76,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Clientes'),
        NavigationDestination(icon: Icon(Icons.attach_money_rounded), label: 'Tarifas'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Recibos'),
        NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Reportes'),
      ],
    );
  }
}
