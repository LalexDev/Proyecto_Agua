import 'package:flutter/material.dart';

class RecibosPage extends StatefulWidget {
  const RecibosPage({super.key});

  @override
  State<RecibosPage> createState() => _RecibosPageState();
}

class _RecibosPageState extends State<RecibosPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  String filtroEstado = 'Todos';

  final List<Map<String, dynamic>> recibos = [
    {
      'id': 1,
      'codigo': 'REC-0001',
      'suministro': 'Casa principal',
      'direccion': 'Av. Principal 123',
      'periodo': 'Mayo 2026',
      'consumo': 12,
      'total': 37.00,
      'vencimiento': '15/05/2026',
      'estado': 'Pendiente',
    },
    {
      'id': 2,
      'codigo': 'REC-0002',
      'suministro': 'Tienda',
      'direccion': 'Av. Principal 125',
      'periodo': 'Mayo 2026',
      'consumo': 18,
      'total': 91.00,
      'vencimiento': '15/05/2026',
      'estado': 'Pagado',
    },
    {
      'id': 3,
      'codigo': 'REC-0003',
      'suministro': 'Local comercial',
      'direccion': 'Jr. Lima 560',
      'periodo': 'Mayo 2026',
      'consumo': 10,
      'total': 31.00,
      'vencimiento': '15/05/2026',
      'estado': 'Pendiente',
    },
    {
      'id': 4,
      'codigo': 'REC-0004',
      'suministro': 'Casa principal',
      'direccion': 'Av. Principal 123',
      'periodo': 'Abril 2026',
      'consumo': 12,
      'total': 37.00,
      'vencimiento': '15/04/2026',
      'estado': 'Pagado',
    },
  ];

  List<Map<String, dynamic>> get recibosFiltrados {
    if (filtroEstado == 'Todos') {
      return recibos;
    }

    return recibos.where((recibo) => recibo['estado'] == filtroEstado).toList();
  }

  int get recibosPendientes {
    return recibos.where((recibo) => recibo['estado'] == 'Pendiente').length;
  }

  int get recibosPagados {
    return recibos.where((recibo) => recibo['estado'] == 'Pagado').length;
  }

  double get deudaTotal {
    return recibos
        .where((recibo) =>
            recibo['estado'] == 'Pendiente' || recibo['estado'] == 'Vencido')
        .fold(0.0, (total, recibo) => total + (recibo['total'] as double));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }

          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/perfil');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildSummaryCards(),
              const SizedBox(height: 22),
              _buildFilter(),
              const SizedBox(height: 18),
              _buildRecibosList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF146C94),
            secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis recibos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Consulta tus recibos pendientes y pagados por suministro.',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pendientes',
                value: '$recibosPendientes',
                subtitle: 'Por pagar',
                icon: Icons.pending_actions_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Pagados',
                value: '$recibosPagados',
                subtitle: 'Cancelados',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DebtCard(total: deudaTotal),
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por estado',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: filtroEstado,
            decoration: InputDecoration(
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos')),
              DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'Pagado', child: Text('Pagado')),
              DropdownMenuItem(value: 'Vencido', child: Text('Vencido')),
            ],
            onChanged: (value) {
              setState(() {
                filtroEstado = value ?? 'Todos';
              });
            },
          ),
        ],
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 54,
              color: secondary,
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
            SizedBox(height: 6),
            Text(
              'Cambia el filtro para visualizar otros recibos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
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
          codigo: recibo['codigo'],
          suministro: recibo['suministro'],
          direccion: recibo['direccion'],
          periodo: recibo['periodo'],
          consumo: recibo['consumo'],
          total: recibo['total'],
          vencimiento: recibo['vencimiento'],
          estado: recibo['estado'],
          onDetalle: () {
            Navigator.pushNamed(
              context,
              '/recibo-detalle',
              arguments: recibo,
            );
          },
          onPagar: () {
            Navigator.pushNamed(
              context,
              '/pago-cip',
              arguments: recibo,
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondary, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final double total;

  const _DebtCard({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFE1A8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC77700),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deuda total pendiente',
                  style: TextStyle(
                    color: Color(0xFFC77700),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 26,
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

class _ReciboCard extends StatelessWidget {
  final String codigo;
  final String suministro;
  final String direccion;
  final String periodo;
  final int consumo;
  final double total;
  final String vencimiento;
  final String estado;
  final VoidCallback onDetalle;
  final VoidCallback onPagar;

  const _ReciboCard({
    required this.codigo,
    required this.suministro,
    required this.direccion,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.vencimiento,
    required this.estado,
    required this.onDetalle,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    final bool puedePagar = estado == 'Pendiente' || estado == 'Vencido';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF3)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FB),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  codigo,
                  style: const TextStyle(
                    color: Color(0xFF146C94),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              _EstadoBadge(estado: estado),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            suministro,
            style: const TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            direccion,
            style: const TextStyle(
              color: textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Periodo',
                  value: periodo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Consumo',
                  value: '$consumo m³',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Vence',
                  value: vencimiento,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Total',
                  value: 'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetalle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondary,
                    side: const BorderSide(color: secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text(
                    'Ver detalle',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (puedePagar) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPagar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text(
                      'Pagar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontSize: 13,
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
    Color background;
    Color textColor;

    if (estado == 'Pagado') {
      background = const Color(0xFFEAF8EF);
      textColor = const Color(0xFF1F8F4D);
    } else if (estado == 'Vencido') {
      background = const Color(0xFFFFECEC);
      textColor = const Color(0xFFD93025);
    } else {
      background = const Color(0xFFFFF3DF);
      textColor = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}