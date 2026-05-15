import 'package:flutter/material.dart';

class ReciboDetailPage extends StatelessWidget {
  const ReciboDetailPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  Map<String, dynamic> _getRecibo(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    return {
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
      'origen': 'cliente',
    };
  }

  double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);

    final String origen = recibo['origen']?.toString() ?? 'cliente';
    final bool esAdmin = origen == 'admin';

    final String estado = recibo['estado']?.toString() ?? 'Pendiente';
    final double total = _toDouble(recibo['total'], 22.20);
    final int consumo = _toInt(recibo['consumo'], 10);

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: esAdmin
          ? null
          : _ClienteBottomNav(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                }

                if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/recibos');
                }

                if (index == 2) {
                  Navigator.pushReplacementNamed(context, '/perfil');
                }
              },
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 18),
              _buildReceiptCard(
                recibo: recibo,
                estado: estado,
                total: total,
                consumo: consumo,
              ),
              const SizedBox(height: 18),
              _buildActionButtons(context, recibo),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 7),
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
                'Detalle de recibo',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Recibo Julio',
                style: TextStyle(
                  color: primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard({
    required Map<String, dynamic> recibo,
    required String estado,
    required double total,
    required int consumo,
  }) {
    final String cliente =
        recibo['cliente']?.toString() ?? 'Carmona Cusquisiban Dany';

    final String codigoSuministro =
        recibo['suministro']?.toString() ?? 'SK-2034-5';

    final String sector =
        recibo['sector']?.toString() ??
            recibo['direccion']?.toString() ??
            'Huacariz Bambamarca';

    final String numero =
        recibo['numero']?.toString() ?? 'N° R-2026-0714';

    return Container(
      width: double.infinity,
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
          _buildReceiptHeader(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(estado: estado),
                    const Spacer(),
                    Text(
                      numero,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const _SectionTitle(title: 'INFORMACIÓN GENERAL'),
                const SizedBox(height: 10),

                _InfoLine(label: 'Titular', value: cliente),
                _InfoLine(label: 'Código de suministro', value: codigoSuministro),
                _InfoLine(label: 'Sector', value: sector),
                const _InfoLine(label: 'Celular', value: '987 654 321'),
                const _InfoLine(label: 'Mes facturado', value: 'Julio 2026'),
                const _InfoLine(label: 'Emisión', value: '02/07/2026'),
                const _InfoLine(label: 'Vencimiento', value: '17/07/2026'),
                const _InfoLine(
                  label: 'Periodo',
                  value: '02/06/2026 - 02/07/2026',
                ),

                const SizedBox(height: 18),

                const _SectionTitle(title: 'LECTURA DEL MEDIDOR'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Expanded(
                      child: _ReadingBox(
                        label: 'Anterior',
                        value: '1020',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _ReadingBox(
                        label: 'Actual',
                        value: '1030',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReadingBox(
                        label: 'Consumo',
                        value: '$consumo m³',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const _SectionTitle(title: 'DETALLE DE FACTURACIÓN'),
                const SizedBox(height: 10),

                const _InfoLine(
                  label: 'Volumen de agua potable',
                  value: 'S/ 20.00',
                ),
                const _InfoLine(
                  label: 'Mantenimiento',
                  value: 'S/ 3.00',
                ),
                const _InfoLine(
                  label: 'Pago al lecturador',
                  value: 'S/ 2.00',
                ),
                const _InfoLine(
                  label: 'Otros cargos',
                  value: 'S/ 0.20',
                ),
                const _InfoLine(
                  label: 'Mora',
                  value: 'S/ 0.00',
                ),

                const SizedBox(height: 14),

                _TotalBox(total: total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D5F9E),
            Color(0xFF0B78B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: const Center(
              child: Text(
                '💧',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JASS Huacariz Agua Potable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Municipalidad de Huacariz · RUC 20481234567',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'www.jasshuacariz.com',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> recibo,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/pdf-viewer',
                arguments: recibo,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Descargar recibo PDF',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recibo compartido de forma visual.'),
                  backgroundColor: secondary,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: Color(0xFFCFEFF7)),
              backgroundColor: const Color(0xFFF4FBFE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Compartir recibo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impresión simulada correctamente.'),
                  backgroundColor: Color(0xFF1F8F4D),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F8F4D),
              side: const BorderSide(color: Color(0xFFCFF3DA)),
              backgroundColor: const Color(0xFFEAF8EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Imprimir',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F3D57),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2EDF3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8794),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F3D57),
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

class _ReadingBox extends StatelessWidget {
  final String label;
  final String value;

  const _ReadingBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFEFF7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B8794),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F3D57),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final double total;

  const _TotalBox({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCFF3DA)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Importe total a pagar',
              style: TextStyle(
                color: Color(0xFF7B8794),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0F3D57),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String estado;

  const _StatusBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    if (estado.toLowerCase() == 'pagado') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (estado.toLowerCase() == 'vencido') {
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
        estado.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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