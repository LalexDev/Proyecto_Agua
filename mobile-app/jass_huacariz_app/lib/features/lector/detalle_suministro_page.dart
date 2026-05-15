import 'package:flutter/material.dart';

class DetalleSuministroPage extends StatelessWidget {
  const DetalleSuministroPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  Map<String, dynamic> _getSuministro(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    return {
      'codigo': 'SK-2034-5',
      'cliente': 'Carmona Cusquisiban Dany',
      'dni': '12345678',
      'sector': 'Huacariz Bambamarca',
      'direccion': 'Av. Principal 123',
      'lecturaAnterior': 1020.0,
      'estado': 'Pendiente',
      'telefono': '987 654 321',
      'mes': 'Julio 2026',
    };
  }

  @override
  Widget build(BuildContext context) {
    final suministro = _getSuministro(context);

    final lecturaAnterior = suministro['lecturaAnterior'] is num
        ? (suministro['lecturaAnterior'] as num).toDouble()
        : 1020.0;

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _LectorBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/lector-home');
          }

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/buscar-suministro');
          }

          if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/registrar-lectura',
              arguments: suministro,
            );
          }

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/historial-lecturas');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientHeader(suministro),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoBox(
                            label: 'Código',
                            value: suministro['codigo'].toString(),
                            icon: Icons.qr_code_2_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoBox(
                            label: 'Estado',
                            value: suministro['estado'].toString(),
                            icon: Icons.pending_actions_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoBox(
                            label: 'Mes',
                            value: suministro['mes'].toString(),
                            icon: Icons.calendar_month_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoBox(
                            label: 'Lectura anterior',
                            value: lecturaAnterior.toStringAsFixed(0),
                            icon: Icons.speed_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Información del usuario',
                      children: [
                        _InfoLine(
                          label: 'Titular',
                          value: suministro['cliente'].toString(),
                        ),
                        _InfoLine(
                          label: 'DNI',
                          value: suministro['dni'].toString(),
                        ),
                        _InfoLine(
                          label: 'Teléfono',
                          value: suministro['telefono'].toString(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _SectionCard(
                      title: 'Ubicación del suministro',
                      children: [
                        _InfoLine(
                          label: 'Sector',
                          value: suministro['sector'].toString(),
                        ),
                        _InfoLine(
                          label: 'Dirección',
                          value: suministro['direccion'].toString(),
                        ),
                        const _InfoLine(
                          label: 'Centro poblado',
                          value: 'Huacariz',
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/registrar-lectura',
                            arguments: suministro,
                          );
                        },
                        icon: const Icon(Icons.water_drop_rounded),
                        label: const Text(
                          'Registrar nueva lectura',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
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
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suministro identificado',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Detalle del suministro',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientHeader(Map<String, dynamic> suministro) {
    final nombre = suministro['cliente'].toString();

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              nombre.substring(0, 1),
              style: const TextStyle(
                color: primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${suministro['codigo']} · ${suministro['sector']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: secondary,
            size: 24,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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