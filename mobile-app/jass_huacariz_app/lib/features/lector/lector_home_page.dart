import 'package:flutter/material.dart';

class LectorHomePage extends StatelessWidget {
  const LectorHomePage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _LectorBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/buscar-suministro');
          }

          if (index == 2) {
            Navigator.pushNamed(context, '/registrar-lectura');
          }

          if (index == 3) {
            Navigator.pushNamed(context, '/historial-lecturas');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 20),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildActionGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel principal del lecturador',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bienvenido, Lecturador',
                style: TextStyle(
                  color: primary,
                  fontSize: 22,
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
          child: IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F7EA3),
            Color(0xFF10B5CC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: secondary.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: 10,
            child: Icon(
              Icons.grid_view_rounded,
              size: 82,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID Lecturador: LEC001',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Trabajo en campo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Fecha actual: 02/07/2026. Escanea el QR, ingresa la lectura actual y genera el recibo.',
                style: TextStyle(
                  color: Color(0xFFE7F8FF),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.22,
      children: [
        _ActionCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Escanear QR',
          subtitle: 'Identificar suministro',
          onTap: () {
            Navigator.pushNamed(context, '/buscar-suministro');
          },
        ),
        _ActionCard(
          icon: Icons.water_drop_rounded,
          title: 'Registrar lectura',
          subtitle: 'Ingreso de lectura actual',
          onTap: () {
            Navigator.pushNamed(context, '/registrar-lectura');
          },
        ),
        _ActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'Generar recibo',
          subtitle: 'Comprobante calculado',
          onTap: () {
            Navigator.pushNamed(context, '/registrar-lectura');
          },
        ),
        _ActionCard(
          icon: Icons.history_rounded,
          title: 'Historial reciente',
          subtitle: 'Últimas lecturas',
          onTap: () {
            Navigator.pushNamed(context, '/historial-lecturas');
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2EDF3),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                size: 28,
              ),
            ),
            const Spacer(),
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
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _LectorBottomNav({
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
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2_rounded),
          label: 'QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          selectedIcon: Icon(Icons.water_drop_rounded),
          label: 'Lectura',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'Historial',
        ),
      ],
    );
  }
}