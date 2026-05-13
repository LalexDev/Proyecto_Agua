import 'package:flutter/material.dart';

class ReciboDetailPage extends StatelessWidget {
  const ReciboDetailPage({super.key});

  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  Map<String, dynamic> _getRecibo(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    return {
      'id': 1,
      'codigo': 'REC-0001',
      'suministro': 'Casa principal',
      'direccion': 'Av. Principal 123',
      'periodo': 'Mayo 2026',
      'consumo': 12,
      'total': 37.00,
      'vencimiento': '15/05/2026',
      'estado': 'Pendiente',
    };
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);

    final String estado = recibo['estado'];
    final bool puedePagar = estado == 'Pendiente' || estado == 'Vencido';

    final double subtotal = estado == 'Pagado'
        ? (recibo['total'] as double) - 1
        : (recibo['total'] as double) - 1;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Detalle del recibo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReceiptHeader(
                codigo: recibo['codigo'],
                periodo: recibo['periodo'],
                estado: estado,
              ),

              const SizedBox(height: 18),

              _AmountCard(
                total: recibo['total'],
                vencimiento: recibo['vencimiento'],
              ),

              const SizedBox(height: 18),

              _InfoSection(
                title: 'Datos del suministro',
                children: [
                  _InfoRow(label: 'Cliente', value: 'Dany Carmona'),
                  _InfoRow(label: 'DNI', value: '12345678'),
                  _InfoRow(label: 'Suministro', value: recibo['suministro']),
                  _InfoRow(label: 'Dirección', value: recibo['direccion']),
                  const _InfoRow(label: 'Sector', value: 'Huacariz'),
                ],
              ),

              const SizedBox(height: 18),

              _ReadingSection(
                lecturaAnterior: 450.345,
                lecturaActual: 462.345,
                consumo: recibo['consumo'],
              ),

              const SizedBox(height: 18),

              _InfoSection(
                title: 'Detalle del importe',
                children: [
                  _InfoRow(
                    label: 'Subtotal por consumo',
                    value: 'S/ ${subtotal.toStringAsFixed(2)}',
                  ),
                  const _InfoRow(label: 'Pago de lector', value: 'S/ 1.00'),
                  const _InfoRow(label: 'Mantenimiento', value: 'S/ 0.00'),
                  const _InfoRow(label: 'Mora', value: 'S/ 0.00'),
                  _InfoRow(
                    label: 'Total',
                    value: 'S/ ${(recibo['total'] as double).toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/pdf-viewer',
                          arguments: recibo,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ver PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        side: const BorderSide(color: secondary),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (puedePagar) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/pago-cip',
                            arguments: recibo,
                          );
                        },
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('Pagar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  final String codigo;
  final String periodo;
  final String estado;

  const _ReceiptHeader({
    required this.codigo,
    required this.periodo,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  codigo,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  periodo,
                  style: const TextStyle(
                    color: Color(0xFF7B8794),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _EstadoBadge(estado: estado),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double total;
  final String vencimiento;

  const _AmountCard({
    required this.total,
    required this.vencimiento,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);

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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total a pagar',
            style: TextStyle(
              color: Color(0xFFDFF6FF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vencimiento: $vencimiento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ReadingSection extends StatelessWidget {
  final double lecturaAnterior;
  final double lecturaActual;
  final int consumo;

  const _ReadingSection({
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.consumo,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Detalle de lectura',
      children: [
        _InfoRow(
          label: 'Lectura anterior',
          value: '${lecturaAnterior.toStringAsFixed(3)} m³',
        ),
        _InfoRow(
          label: 'Lectura actual',
          value: '${lecturaActual.toStringAsFixed(3)} m³',
        ),
        _InfoRow(
          label: 'Consumo mensual',
          value: '$consumo m³',
          isTotal: true,
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF3)),
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
          Text(
            title,
            style: const TextStyle(
              color: primary,
              fontSize: 20,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? 14 : 11,
        horizontal: isTotal ? 14 : 0,
      ),
      margin: EdgeInsets.only(top: isTotal ? 8 : 0),
      decoration: BoxDecoration(
        color: isTotal ? const Color(0xFFE8F7FB) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          bottom: isTotal
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE8EEF3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? primary : textMuted,
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: primary,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
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