import 'package:flutter/material.dart';

class PagoCipPage extends StatefulWidget {
  const PagoCipPage({super.key});

  @override
  State<PagoCipPage> createState() => _PagoCipPageState();
}

class _PagoCipPageState extends State<PagoCipPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  String metodoSeleccionado = 'PagoEfectivo';
  String codigoGenerado = '';
  bool pagoGenerado = false;
  bool pagoConfirmado = false;

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

  void generarCodigo() {
    final int numero = DateTime.now().millisecondsSinceEpoch % 1000000000;

    setState(() {
      if (metodoSeleccionado == 'PagoEfectivo') {
        codigoGenerado = 'CIP-$numero';
      } else if (metodoSeleccionado == 'Transferencia') {
        codigoGenerado = 'TR-$numero';
      } else {
        codigoGenerado = 'PRES-$numero';
      }

      pagoGenerado = true;
      pagoConfirmado = false;
    });
  }

  void confirmarPagoVisual() {
    setState(() {
      pagoConfirmado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago simulado correctamente.'),
        backgroundColor: Color(0xFF1F8F4D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);
    final double total = recibo['total'] as double;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Pagar recibo',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
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
              _buildHeader(recibo, total),
              const SizedBox(height: 18),
              _buildReciboInfo(recibo),
              const SizedBox(height: 18),
              _buildMetodoPago(),
              const SizedBox(height: 18),
              _buildBotonGenerar(),
              if (pagoGenerado) ...[
                const SizedBox(height: 18),
                _buildCodigoGenerado(recibo),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> recibo, double total) {
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
            color: primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderTag(text: 'Pago de recibo'),
          const SizedBox(height: 16),
          Text(
            recibo['codigo'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${recibo['suministro']} · ${recibo['periodo']}',
            style: const TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReciboInfo(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Información del recibo',
      subtitle: 'Verifica los datos antes de generar el pago.',
      child: Column(
        children: [
          _InfoRow(label: 'Código', value: recibo['codigo']),
          _InfoRow(label: 'Suministro', value: recibo['suministro']),
          _InfoRow(label: 'Dirección', value: recibo['direccion']),
          _InfoRow(label: 'Periodo', value: recibo['periodo']),
          _InfoRow(label: 'Consumo', value: '${recibo['consumo']} m³'),
          _InfoRow(label: 'Vencimiento', value: recibo['vencimiento']),
          _InfoRow(
            label: 'Total',
            value: 'S/ ${(recibo['total'] as double).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPago() {
    return _SectionCard(
      title: 'Método de pago',
      subtitle: 'Selecciona cómo deseas pagar el recibo.',
      child: Column(
        children: [
          _PaymentMethodCard(
            title: 'PagoEfectivo',
            description: 'Genera un código CIP para pagar en agentes, banca móvil o plataformas afiliadas.',
            icon: Icons.confirmation_number_outlined,
            selected: metodoSeleccionado == 'PagoEfectivo',
            onTap: () {
              setState(() {
                metodoSeleccionado = 'PagoEfectivo';
                pagoGenerado = false;
              });
            },
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            title: 'Transferencia',
            description: 'Usa una operación bancaria y registra el concepto del pago.',
            icon: Icons.account_balance_outlined,
            selected: metodoSeleccionado == 'Transferencia',
            onTap: () {
              setState(() {
                metodoSeleccionado = 'Transferencia';
                pagoGenerado = false;
              });
            },
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            title: 'Pago presencial',
            description: 'Presenta el código generado en la oficina de JASS Huacariz.',
            icon: Icons.storefront_outlined,
            selected: metodoSeleccionado == 'Presencial',
            onTap: () {
              setState(() {
                metodoSeleccionado = 'Presencial';
                pagoGenerado = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBotonGenerar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: generarCodigo,
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text(
          'Generar código de pago',
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
    );
  }

  Widget _buildCodigoGenerado(Map<String, dynamic> recibo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          Center(
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: pagoConfirmado
                    ? const Color(0xFFEAF8EF)
                    : const Color(0xFFE8F7FB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                pagoConfirmado
                    ? Icons.check_circle_outline
                    : Icons.qr_code_2_rounded,
                color: pagoConfirmado
                    ? const Color(0xFF1F8F4D)
                    : secondary,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              pagoConfirmado ? 'Pago confirmado' : 'Código generado',
              style: const TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              codigoGenerado,
              style: const TextStyle(
                color: secondary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildInstructions(),
          const SizedBox(height: 18),
          if (!pagoConfirmado)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: confirmarPagoVisual,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Simular pago realizado',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/recibos');
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text(
                  'Volver a mis recibos',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondary,
                  side: const BorderSide(color: secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    if (metodoSeleccionado == 'PagoEfectivo') {
      return const _InstructionBox(
        title: 'Instrucciones PagoEfectivo',
        items: [
          'Copia el código CIP generado.',
          'Ingresa a tu banca móvil, agente o plataforma afiliada.',
          'Busca la opción PagoEfectivo.',
          'Ingresa el código CIP y confirma el pago.',
        ],
      );
    }

    if (metodoSeleccionado == 'Transferencia') {
      return const _BankInfoBox();
    }

    return const _PresentialInfoBox();
  }
}

class _HeaderTag extends StatelessWidget {
  final String text;

  const _HeaderTag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE8EEF3),
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
          Text(
            title,
            style: const TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F7FB) : const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? secondary : const Color(0xFFE8EEF3),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? secondary : textMuted,
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? secondary : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _InstructionBox extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InstructionBox({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color textMuted = Color(0xFF52616B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EEF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankInfoBox extends StatelessWidget {
  const _BankInfoBox();

  @override
  Widget build(BuildContext context) {
    return const _InstructionBox(
      title: 'Datos para transferencia',
      items: [
        'Banco: Banco de la Nación.',
        'Cuenta: 000-000000000.',
        'Titular: JASS Huacariz.',
        'Usa el código generado como concepto de pago.',
      ],
    );
  }
}

class _PresentialInfoBox extends StatelessWidget {
  const _PresentialInfoBox();

  @override
  Widget build(BuildContext context) {
    return const _InstructionBox(
      title: 'Pago presencial',
      items: [
        'Acércate a la oficina de atención de JASS Huacariz.',
        'Presenta el código generado.',
        'Solicita la constancia de pago correspondiente.',
      ],
    );
  }
}