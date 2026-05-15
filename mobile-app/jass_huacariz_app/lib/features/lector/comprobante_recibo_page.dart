import 'package:flutter/material.dart';

class ComprobanteReciboPage extends StatelessWidget {
  const ComprobanteReciboPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);
  static const Color yellow = Color(0xFFFFD527);

  Map<String, dynamic> _getRecibo(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    return {
      'cliente': 'Carmona Cusquisiban Dany',
      'suministro': 'SK-2034-5',
      'sector': 'Huacariz Bambamarca',
      'periodo': 'Julio 2026',
      'lecturaAnterior': 1020,
      'lecturaActual': 1030,
      'consumo': 10,
      'volumenAgua': 20.00,
      'pagoLecturador': 2.00,
      'otrosCargos': 0.20,
      'mora': 0.00,
      'total': 22.20,
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

    final cliente = recibo['cliente']?.toString() ?? 'Carmona Cusquisiban Dany';
    final suministro = recibo['suministro']?.toString() ?? 'SK-2034-5';
    final sector = recibo['sector']?.toString() ?? 'Huacariz Bambamarca';

    final lecturaAnterior = _toInt(recibo['lecturaAnterior'], 1020);
    final lecturaActual = _toInt(recibo['lecturaActual'], 1030);
    final consumo = _toInt(recibo['consumo'], 10);

    final volumenAgua = _toDouble(recibo['volumenAgua'], 20.00);
    final pagoLecturador = _toDouble(recibo['pagoLecturador'], 2.00);
    final otrosCargos = _toDouble(recibo['otrosCargos'], 0.20);
    final mora = _toDouble(recibo['mora'], 0.00);
    final total = _toDouble(recibo['total'], 22.20);

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _LectorBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/lector-home');
          }

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/buscar-suministro');
          }

          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/registrar-lectura');
          }

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/historial-lecturas');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildComprobante(
                cliente: cliente,
                suministro: suministro,
                sector: sector,
                lecturaAnterior: lecturaAnterior,
                lecturaActual: lecturaActual,
                consumo: consumo,
                volumenAgua: volumenAgua,
                pagoLecturador: pagoLecturador,
                otrosCargos: otrosCargos,
                mora: mora,
                total: total,
              ),
              const SizedBox(height: 16),
              _buildActions(context),
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
                'Recibo generado',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Comprobante',
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

  Widget _buildComprobante({
    required String cliente,
    required String suministro,
    required String sector,
    required int lecturaAnterior,
    required int lecturaActual,
    required int consumo,
    required double volumenAgua,
    required double pagoLecturador,
    required double otrosCargos,
    required double mora,
    required double total,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          _buildComprobanteHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            child: Column(
              children: [
                _buildClientBlock(cliente, sector),
                const SizedBox(height: 16),

                _SectionBox(
                  title: 'INFORMACIÓN GENERAL',
                  children: [
                    _InfoLine(label: 'Titular de la conexión', value: cliente),
                    _InfoLine(label: 'ID Usuario', value: suministro),
                    const _InfoLine(label: 'Tipo de facturación', value: 'LECTURA'),
                    const _InfoLine(label: 'Frecuencia de facturación', value: 'Mensual'),
                  ],
                ),

                const SizedBox(height: 14),

                const _SectionBox(
                  title: 'INFORMACIÓN',
                  children: [
                    _InfoLine(label: 'Fecha de emisión', value: '2/7/2026'),
                    _InfoLine(label: 'Periodo de consumo', value: '2/6/2026 - 2/7/2026'),
                    _InfoLine(label: 'Mes facturado', value: 'JULIO 2026'),
                    _InfoLine(label: 'Fecha de vencimiento', value: '17/7/2026'),
                  ],
                ),

                const SizedBox(height: 14),

                _SectionBox(
                  title: 'LECTURA DEL MEDIDOR',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ReadingBox(
                            label: 'Anterior',
                            value: '$lecturaAnterior',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReadingBox(
                            label: 'Actual',
                            value: '$lecturaActual',
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
                  ],
                ),

                const SizedBox(height: 14),

                _SectionBox(
                  title: 'DETALLE DE FACTURACIÓN',
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Concepto',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            'Importe',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _InfoLine(
                      label: 'Volumen del Agua Potable $consumo.00 m³',
                      value: 'S/ ${volumenAgua.toStringAsFixed(2)}',
                    ),
                    _InfoLine(
                      label: 'Pago al lecturador',
                      value: 'S/ ${pagoLecturador.toStringAsFixed(2)}',
                    ),
                    _InfoLine(
                      label: 'Otros cargos',
                      value: 'S/ ${otrosCargos.toStringAsFixed(2)}',
                    ),
                    _InfoLine(
                      label: 'Mora',
                      value: 'S/ ${mora.toStringAsFixed(2)}',
                    ),
                    _InfoLine(
                      label: 'Consumo del mes',
                      value: 'S/ ${total.toStringAsFixed(2)}',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _TotalYellowBox(total: total),

                const SizedBox(height: 12),

                _buildCodeBlock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'AGUA POTABLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'JULIO',
              style: TextStyle(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientBlock(String cliente, String sector) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cliente,
            style: const TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Centro poblado: Huacariz',
            style: TextStyle(
              color: muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Sector: $sector',
            style: const TextStyle(
              color: muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 134,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EDF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Celular: 976012984',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Municipalidad de Huacariz',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'RUC: xxxxxxxxx',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Web: www.jasshuacariz.com',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BarcodePainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 134,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EDF3)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _QrPainter(),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QR recibo',
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF descargado de forma visual.'),
                      backgroundColor: secondary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Descargar PDF',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
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
                  backgroundColor: const Color(0xFFF4FBFE),
                  side: const BorderSide(color: Color(0xFFCFEFF7)),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Compartir recibo',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/lector-home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Finalizar',
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

class _SectionBox extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionBox({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7FB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F3D57),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: children,
            ),
          ),
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
                color: Color(0xFF7B8794),
                fontSize: 12.5,
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
                color: Color(0xFF0F3D57),
                fontSize: 12.5,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E6EE)),
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

class _TotalYellowBox extends StatelessWidget {
  final double total;

  const _TotalYellowBox({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE25B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3BD00)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importe total a pagar',
                  style: TextStyle(
                    color: Color(0xFF0F3D57),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Vence el 17/7/2026',
                  style: TextStyle(
                    color: Color(0xFF52616B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'S/${total.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFF0F3D57),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B5F8D)
      ..strokeWidth = 2;

    final widths = [2.0, 4.0, 1.5, 3.0, 2.0, 5.0, 1.0, 3.5, 2.0, 4.5];

    double x = 0;

    for (int i = 0; x < size.width; i++) {
      final w = widths[i % widths.length];
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        paint,
      );
      x += w + 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF0B5F8D);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cell = size.width / 7;

    final points = [
      [0, 0], [1, 0], [2, 0],
      [0, 1], [2, 1],
      [0, 2], [1, 2], [2, 2],
      [4, 0], [6, 0], [5, 1],
      [4, 2], [6, 2],
      [1, 4], [3, 4], [5, 4],
      [0, 5], [2, 5], [4, 5], [6, 5],
      [1, 6], [3, 6], [5, 6],
    ];

    for (final point in points) {
      canvas.drawRect(
        Rect.fromLTWH(
          point[0] * cell + 2,
          point[1] * cell + 2,
          cell - 4,
          cell - 4,
        ),
        darkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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