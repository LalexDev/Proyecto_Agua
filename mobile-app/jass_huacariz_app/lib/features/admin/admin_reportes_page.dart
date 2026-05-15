import 'package:flutter/material.dart';

class AdminReportesPage extends StatelessWidget {
  const AdminReportesPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final List<Map<String, dynamic>> recibos = const [
    {
      'cliente': 'Carmona Cusquisiban Dany',
      'consumo': 10,
      'total': 22.20,
      'estado': 'Pendiente',
      'mantenimiento': 3.00,
      'lecturador': 2.00,
      'otros': 0.20,
      'mora': 0.00,
    },
    {
      'cliente': 'María Torres Huamán',
      'consumo': 8,
      'total': 21.20,
      'estado': 'Pagado',
      'mantenimiento': 3.00,
      'lecturador': 2.00,
      'otros': 0.20,
      'mora': 0.00,
    },
    {
      'cliente': 'Juan Pérez Silva',
      'consumo': 19,
      'total': 82.20,
      'estado': 'Vencido',
      'mantenimiento': 3.00,
      'lecturador': 2.00,
      'otros': 0.20,
      'mora': 1.50,
    },
  ];

  double get totalEmitido {
    return recibos.fold(
      0.0,
      (sum, item) => sum + (item['total'] as double),
    );
  }

  double get recaudado {
    return recibos
        .where((item) => item['estado'] == 'Pagado')
        .fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  double get carteraVencida {
    return recibos
        .where((item) => item['estado'] == 'Vencido')
        .fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  double get carteraPendiente {
    return recibos
        .where((item) => item['estado'] == 'Pendiente')
        .fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  double get mantenimientoTotal {
    return recibos.fold(
      0.0,
      (sum, item) => sum + (item['mantenimiento'] as double),
    );
  }

  double get pagoLecturadorTotal {
    return recibos.fold(
      0.0,
      (sum, item) => sum + (item['lecturador'] as double),
    );
  }

  double get otrosCargosTotal {
    return recibos.fold(
      0.0,
      (sum, item) => sum + (item['otros'] as double),
    );
  }

  double get moraTotal {
    return recibos.fold(
      0.0,
      (sum, item) => sum + (item['mora'] as double),
    );
  }

  int get recibosEmitidos => recibos.length;

  int get recibosPendientes {
    return recibos.where((item) => item['estado'] == 'Pendiente').length;
  }

  int get recibosPagados {
    return recibos.where((item) => item['estado'] == 'Pagado').length;
  }

  int get recibosVencidos {
    return recibos.where((item) => item['estado'] == 'Vencido').length;
  }

  int get consumoTotal {
    return recibos.fold(
      0,
      (sum, item) => sum + (item['consumo'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 4,
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

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/admin-recibos');
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
              const SizedBox(height: 20),
              _buildMainReportCard(),
              const SizedBox(height: 18),
              _buildFinancialReports(),
              const SizedBox(height: 18),
              _buildOperationalReports(),
              const SizedBox(height: 18),
              _buildManagerRecommendations(),
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
                'Indicadores',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reportes',
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
            Icons.bar_chart_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMainReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _ReportTile(
            icon: Icons.trending_up_rounded,
            title: 'Recaudación del mes',
            subtitle: 'S/ ${recaudado.toStringAsFixed(2)} cobrados',
            badge: '+12%',
            badgeColor: const Color(0xFFEAF8EF),
            badgeTextColor: const Color(0xFF1F8F4D),
          ),
          const Divider(height: 28, color: Color(0xFFE2EDF3)),
          _ReportTile(
            icon: Icons.receipt_long_rounded,
            title: 'Recibos emitidos',
            subtitle: '$recibosEmitidos recibos procesados',
            badge: '$recibosPendientes pend.',
            badgeColor: const Color(0xFFFFF3DF),
            badgeTextColor: const Color(0xFFC77700),
          ),
          const Divider(height: 28, color: Color(0xFFE2EDF3)),
          _ReportTile(
            icon: Icons.warning_amber_rounded,
            title: 'Cartera vencida',
            subtitle: '$recibosVencidos recibos con mora',
            badge: 'S/ ${carteraVencida.toStringAsFixed(2)}',
            badgeColor: const Color(0xFFFFECEC),
            badgeTextColor: const Color(0xFFD93025),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialReports() {
    return _SectionCard(
      title: 'Reportes financieros',
      children: [
        _MetricRow(
          label: 'Total emitido',
          value: 'S/ ${totalEmitido.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Total recaudado',
          value: 'S/ ${recaudado.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Cartera pendiente',
          value: 'S/ ${carteraPendiente.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Cartera vencida',
          value: 'S/ ${carteraVencida.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Mora acumulada',
          value: 'S/ ${moraTotal.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildOperationalReports() {
    return _SectionCard(
      title: 'Reportes operativos',
      children: [
        _MetricRow(
          label: 'Clientes activos',
          value: '${recibos.length}',
        ),
        _MetricRow(
          label: 'Consumo total del mes',
          value: '$consumoTotal m³',
        ),
        _MetricRow(
          label: 'Recibos pagados',
          value: '$recibosPagados',
        ),
        _MetricRow(
          label: 'Recibos pendientes',
          value: '$recibosPendientes',
        ),
        _MetricRow(
          label: 'Recibos vencidos',
          value: '$recibosVencidos',
        ),
        _MetricRow(
          label: 'Mantenimiento generado',
          value: 'S/ ${mantenimientoTotal.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Pago al lecturador',
          value: 'S/ ${pagoLecturadorTotal.toStringAsFixed(2)}',
        ),
        _MetricRow(
          label: 'Otros cargos',
          value: 'S/ ${otrosCargosTotal.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildManagerRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCFEFF7)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicadores sugeridos para gerencia',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _BulletText(
            text: 'Comparar recaudación mensual contra meses anteriores.',
          ),
          _BulletText(
            text: 'Identificar usuarios con deuda recurrente.',
          ),
          _BulletText(
            text: 'Medir consumo total por sector o zona.',
          ),
          _BulletText(
            text: 'Revisar mantenimiento recaudado para gastos operativos.',
          ),
          _BulletText(
            text: 'Controlar recibos vencidos y mora acumulada.',
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);
    const Color secondary = Color(0xFF1DA1C2);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2EDF3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
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

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF0F3D57),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF52616B),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
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