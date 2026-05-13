import 'package:flutter/material.dart';

class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({super.key});

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

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);

    final double total = recibo['total'] as double;
    final double pagoLector = 1.00;
    final double subtotal = total - pagoLector;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Recibo PDF',
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
        actions: [
          IconButton(
            onPressed: () {
              _mostrarMensaje(
                context,
                'Descarga de PDF simulada correctamente.',
              );
            },
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              _buildTopNotice(),
              const SizedBox(height: 18),
              _buildPdfCard(
                recibo: recibo,
                subtotal: subtotal,
                pagoLector: pagoLector,
                total: total,
              ),
              const SizedBox(height: 18),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFCFEFF7),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            color: secondary,
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vista previa del recibo. Luego conectaremos esta pantalla con generación real de PDF.',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard({
    required Map<String, dynamic> recibo,
    required double subtotal,
    required double pagoLector,
    required double total,
  }) {
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
            color: primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPdfHeader(recibo),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _buildClienteSection(),
          const SizedBox(height: 16),
          _buildSuministroSection(recibo),
          const SizedBox(height: 16),
          _buildLecturaSection(recibo),
          const SizedBox(height: 16),
          _buildImporteSection(
            subtotal: subtotal,
            pagoLector: pagoLector,
            total: total,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          const Text(
            'Este comprobante corresponde al servicio de agua potable administrado por JASS Huacariz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfHeader(Map<String, dynamic> recibo) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                primary,
                secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Text(
              '💧',
              style: TextStyle(fontSize: 38),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'JASS HUACARIZ',
          style: TextStyle(
            color: primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Recibo por servicio de agua potable',
          style: TextStyle(
            color: textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEF3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SmallPdfInfo(
                  label: 'Recibo',
                  value: recibo['codigo'],
                ),
              ),
              Expanded(
                child: _SmallPdfInfo(
                  label: 'Periodo',
                  value: recibo['periodo'],
                  alignRight: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClienteSection() {
    return const _PdfSection(
      title: 'Datos del cliente',
      children: [
        _PdfRow(label: 'Cliente', value: 'Dany Carmona'),
        _PdfRow(label: 'DNI', value: '12345678'),
        _PdfRow(label: 'Teléfono', value: '987654321'),
        _PdfRow(label: 'Correo', value: 'dany@gmail.com'),
      ],
    );
  }

  Widget _buildSuministroSection(Map<String, dynamic> recibo) {
    return _PdfSection(
      title: 'Datos del suministro',
      children: [
        _PdfRow(label: 'Suministro', value: recibo['suministro']),
        _PdfRow(label: 'Dirección', value: recibo['direccion']),
        const _PdfRow(label: 'Sector', value: 'Huacariz'),
        _PdfRow(label: 'Vencimiento', value: recibo['vencimiento']),
        _PdfRow(label: 'Estado', value: recibo['estado']),
      ],
    );
  }

  Widget _buildLecturaSection(Map<String, dynamic> recibo) {
    return _PdfSection(
      title: 'Detalle de lectura',
      children: [
        const _PdfRow(label: 'Lectura anterior', value: '450.345 m³'),
        const _PdfRow(label: 'Lectura actual', value: '462.345 m³'),
        _PdfRow(label: 'Consumo mensual', value: '${recibo['consumo']} m³'),
      ],
    );
  }

  Widget _buildImporteSection({
    required double subtotal,
    required double pagoLector,
    required double total,
  }) {
    return _PdfSection(
      title: 'Detalle del importe',
      children: [
        _PdfRow(
          label: 'Subtotal por consumo',
          value: 'S/ ${subtotal.toStringAsFixed(2)}',
        ),
        _PdfRow(
          label: 'Pago de lector',
          value: 'S/ ${pagoLector.toStringAsFixed(2)}',
        ),
        const _PdfRow(label: 'Mantenimiento', value: 'S/ 0.00'),
        const _PdfRow(label: 'Mora', value: 'S/ 0.00'),
        _PdfRow(
          label: 'Total a pagar',
          value: 'S/ ${total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              _mostrarMensaje(
                context,
                'PDF descargado de forma simulada.',
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text(
              'Descargar recibo',
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              _mostrarMensaje(
                context,
                'Opción compartir simulada correctamente.',
              );
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text(
              'Compartir recibo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
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
    );
  }
}

class _SmallPdfInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _SmallPdfInfo({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7B8794),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF0F3D57),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PdfSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PdfSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
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
              color: Color(0xFF0F3D57),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PdfRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PdfRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? 12 : 9,
        horizontal: isTotal ? 12 : 0,
      ),
      margin: EdgeInsets.only(top: isTotal ? 8 : 0),
      decoration: BoxDecoration(
        color: isTotal ? const Color(0xFFE8F7FB) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
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
                color: isTotal
                    ? const Color(0xFF0F3D57)
                    : const Color(0xFF7B8794),
                fontSize: isTotal ? 14 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF0F3D57),
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}