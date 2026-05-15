import 'package:flutter/material.dart';

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

  String filtro = 'Todos';

  final List<Map<String, dynamic>> recibos = [
    {
      'id': 1,
      'codigo': 'REC-0001',
      'numero': 'N° R-2026-0714',
      'cliente': 'Carmona Cusquisiban Dany',
      'suministro': 'SK-2034-5',
      'sector': 'Huacariz Bambamarca',
      'periodo': 'Julio 2026',
      'consumo': 10,
      'total': 22.20,
      'vencimiento': '17/07/2026',
      'estado': 'Pendiente',
      'origen': 'admin',
    },
    {
      'id': 2,
      'codigo': 'REC-0002',
      'numero': 'N° R-2026-0715',
      'cliente': 'María Torres Huamán',
      'suministro': 'SK-2019-12',
      'sector': 'Sector La Molina',
      'periodo': 'Julio 2026',
      'consumo': 8,
      'total': 21.20,
      'vencimiento': '17/07/2026',
      'estado': 'Pagado',
      'origen': 'admin',
    },
    {
      'id': 3,
      'codigo': 'REC-0003',
      'numero': 'N° R-2026-0716',
      'cliente': 'Juan Pérez Silva',
      'suministro': 'SK-2040-09',
      'sector': 'Huacariz Centro',
      'periodo': 'Julio 2026',
      'consumo': 19,
      'total': 82.20,
      'vencimiento': '17/07/2026',
      'estado': 'Vencido',
      'origen': 'admin',
    },
  ];

  List<Map<String, dynamic>> get recibosFiltrados {
    if (filtro == 'Todos') return recibos;
    return recibos.where((recibo) => recibo['estado'] == filtro).toList();
  }

  void registrarPagoPresencial(Map<String, dynamic> recibo) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Confirmar pago presencial',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Deseas marcar el recibo ${recibo['suministro']} como pagado?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  recibo['estado'] = 'Pagado';
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pago presencial registrado correctamente.'),
                    backgroundColor: Color(0xFF1F8F4D),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void compartirRecibo(Map<String, dynamic> recibo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartiendo recibo ${recibo['suministro']}'),
        backgroundColor: secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 3,
        onTap: (index) {
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
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildFilters(),
              const SizedBox(height: 18),
              _buildRecibosList(),
            ],
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
                  fontSize: 13,
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filtros = ['Todos', 'Pagado', 'Pendiente', 'Vencido'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((item) {
          final selected = filtro == item;

          String texto = item;
          if (item == 'Pagado') texto = 'Pagados';
          if (item == 'Pendiente') texto = 'Pendientes';
          if (item == 'Vencido') texto = 'Vencidos';

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              label: Text(
                texto,
                style: TextStyle(
                  color: selected ? Colors.white : muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              selectedColor: const Color(0xFF0B78B7),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2EDF3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (_) {
                setState(() {
                  filtro = item;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecibosList() {
    if (recibosFiltrados.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: secondary,
              size: 54,
            ),
            SizedBox(height: 12),
            Text(
              'No hay recibos para mostrar',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: recibosFiltrados.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final recibo = recibosFiltrados[index];

        return _ReciboCard(
          recibo: recibo,
          onVerRecibo: () {
            Navigator.pushNamed(
              context,
              '/recibo-detalle',
              arguments: recibo,
            );
          },
          onCompartir: () {
            compartirRecibo(recibo);
          },
          onPagoPresencial: () {
            registrarPagoPresencial(recibo);
          },
        );
      },
    );
  }
}

class _ReciboCard extends StatelessWidget {
  final Map<String, dynamic> recibo;
  final VoidCallback onVerRecibo;
  final VoidCallback onCompartir;
  final VoidCallback onPagoPresencial;

  const _ReciboCard({
    required this.recibo,
    required this.onVerRecibo,
    required this.onCompartir,
    required this.onPagoPresencial,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    final String estado = recibo['estado'].toString();
    final bool estaPagado = estado == 'Pagado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EDF3)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recibo['suministro'].toString(),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${recibo['cliente']} · ${recibo['periodo']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Consumo',
                  value: '${recibo['consumo']} m³',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Importe total',
                  value:
                      'S/ ${(recibo['total'] as double).toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onVerRecibo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Ver recibo',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCompartir,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    backgroundColor: const Color(0xFFF0FAFD),
                    side: const BorderSide(color: Color(0xFFE2EDF3)),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Compartir',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          if (!estaPagado) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onPagoPresencial,
                icon: const Icon(Icons.payments_rounded),
                label: const Text(
                  'Registrar pago presencial',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F8F4D),
                  backgroundColor: const Color(0xFFEAF8EF),
                  side: const BorderSide(color: Color(0xFFCFF3DA)),
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

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EDF3)),
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
            style: const TextStyle(
              color: primary,
              fontSize: 15,
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
    Color bg;
    Color text;

    if (estado == 'Pagado') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (estado == 'Vencido') {
      bg = const Color(0xFFFFECEC);
      text = const Color(0xFFD93025);
    } else {
      bg = const Color(0xFFFFF3DF);
      text = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.attach_money_outlined),
          selectedIcon: Icon(Icons.attach_money_rounded),
          label: 'Tarifas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reportes',
        ),
      ],
    );
  }
}