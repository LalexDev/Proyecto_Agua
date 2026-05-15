import 'package:flutter/material.dart';

class BuscarSuministroPage extends StatelessWidget {
  const BuscarSuministroPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);
  static const Color darkScanner = Color(0xFF09283A);

  Map<String, dynamic> _suministroDemo() {
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

  void _simularEscaneo(BuildContext context) {
    final suministro = _suministroDemo();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Suministro identificado',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Se encontró el suministro SK-2034-5 de Carmona Cusquisiban Dany.',
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
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  '/detalle-suministro',
                  arguments: suministro,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Ver suministro',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _irAInicio(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/lector-home');
  }

  void _irAQR(BuildContext context) {
    // Ya estamos en QR, no hacemos nada.
  }

  void _irALectura(BuildContext context) {
    final suministro = _suministroDemo();

    Navigator.pushReplacementNamed(
      context,
      '/detalle-suministro',
      arguments: suministro,
    );
  }

  void _irAHistorial(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/historial-lecturas');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _LectorBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            _irAInicio(context);
          }

          if (index == 1) {
            _irAQR(context);
          }

          if (index == 2) {
            _irALectura(context);
          }

          if (index == 3) {
            _irAHistorial(context);
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
              const SizedBox(height: 20),
              _buildScannerBox(),
              const SizedBox(height: 16),
              _buildScanButton(context),
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
              Navigator.pushReplacementNamed(context, '/lector-home');
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
                'Escaneo de suministro',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Escanear QR',
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

  Widget _buildScannerBox() {
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: darkScanner,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
                width: 2,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF37D36E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF37D36E).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 46,
              ),
              const SizedBox(height: 30),
              Text(
                'Apunta la cámara al código QR del suministro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          _simularEscaneo(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: secondary.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Escanear código',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
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