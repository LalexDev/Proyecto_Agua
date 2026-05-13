import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  final List<Map<String, dynamic>> suministros = const [
    {
      'alias': 'Casa principal',
      'direccion': 'Av. Principal 123',
      'sector': 'Huacariz',
      'lectura': 462.345,
      'consumo': 12,
      'deuda': 37.00,
      'estado': 'Activo',
    },
    {
      'alias': 'Tienda',
      'direccion': 'Av. Principal 125',
      'sector': 'Huacariz',
      'lectura': 238.000,
      'consumo': 18,
      'deuda': 91.00,
      'estado': 'Activo',
    },
    {
      'alias': 'Local comercial',
      'direccion': 'Jr. Lima 560',
      'sector': 'Huacariz Alto',
      'lectura': 110.000,
      'consumo': 10,
      'deuda': 31.00,
      'estado': 'Activo',
    },
  ];

  double get deudaTotal {
    return suministros.fold(
      0,
      (total, item) => total + (item['deuda'] as double),
    );
  }

  int get consumoTotal {
    return suministros.fold(
      0,
      (total, item) => total + (item['consumo'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/recibos');
          }

          if (index == 2) {
            Navigator.pushNamed(context, '/perfil');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 22),
              _buildWelcomeCard(),
              const SizedBox(height: 22),
              _buildSummaryCards(),
              const SizedBox(height: 22),
              _buildQuickActions(context),
              const SizedBox(height: 22),
              _buildSuministrosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '💧',
              style: TextStyle(fontSize: 26),
            ),
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
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Portal móvil del cliente',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/perfil');
          },
          icon: const Icon(
            Icons.account_circle_outlined,
            color: primary,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Bienvenido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hola, Dany Carmona',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta tus recibos, suministros y pagos del servicio de agua potable.',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deuda total pendiente',
                  style: TextStyle(
                    color: Color(0xFFDFF6FF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'S/ ${deudaTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Suministros',
            value: '${suministros.length}',
            subtitle: 'Asociados',
            icon: Icons.water_drop_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Consumo',
            value: '$consumoTotal m³',
            subtitle: 'Último mes',
            icon: Icons.bar_chart_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos rápidos',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.receipt_long_outlined,
                title: 'Mis recibos',
                onTap: () {
                  Navigator.pushNamed(context, '/recibos');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.payment_outlined,
                title: 'Pagar',
                onTap: () {
                  Navigator.pushNamed(context, '/pago-cip');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuministrosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis suministros',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Puntos de consumo asociados a tu usuario.',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        ListView.separated(
          itemCount: suministros.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final suministro = suministros[index];

            return _SuministroCard(
              alias: suministro['alias'],
              direccion: suministro['direccion'],
              sector: suministro['sector'],
              lectura: suministro['lectura'],
              consumo: suministro['consumo'],
              deuda: suministro['deuda'],
              estado: suministro['estado'],
            );
          },
        ),
      ],
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
            color: primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondary, size: 30),
          const SizedBox(height: 14),
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
              fontSize: 22,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color secondary = Color(0xFF1DA1C2);
    const Color primary = Color(0xFF0F3D57);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8EEF3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: secondary, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuministroCard extends StatelessWidget {
  final String alias;
  final String direccion;
  final String sector;
  final double lectura;
  final int consumo;
  final double deuda;
  final String estado;

  const _SuministroCard({
    required this.alias,
    required this.direccion,
    required this.sector,
    required this.lectura,
    required this.consumo,
    required this.deuda,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8EEF3),
        ),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alias,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sector,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  estado,
                  style: const TextStyle(
                    color: Color(0xFF1F8F4D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            direccion,
            style: const TextStyle(
              color: textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Lectura',
                  value: '${lectura.toStringAsFixed(3)} m³',
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: 'Consumo',
                  value: '$consumo m³',
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: 'Deuda',
                  value: 'S/ ${deuda.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
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
    const Color textMuted = Color(0xFF7B8794);

    return Column(
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