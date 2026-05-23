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

    return {};
  }

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  String _codigoRecibo(Map<String, dynamic> recibo) {
    return _texto(
      recibo['codigoRecibo'] ??
          recibo['numeroRecibo'] ??
          recibo['codigo'] ??
          'REC-${_id(recibo)}',
    );
  }

  String _codigoSuministro(Map<String, dynamic> recibo) {
    return _texto(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['suministro'] ??
          'SIN-SUMINISTRO',
    );
  }

  String _titular(Map<String, dynamic> recibo) {
    return _texto(
      recibo['titular'] ??
          recibo['cliente'] ??
          recibo['nombreCliente'] ??
          recibo['nombres'] ??
          recibo['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> recibo) {
    return _texto(
      recibo['direccionSuministro'] ??
          recibo['direccion'] ??
          recibo['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _sector(Map<String, dynamic> recibo) {
    return _texto(
      recibo['sector'] ?? recibo['nombreSector'] ?? recibo['sectorNombre'],
      'Huacariz',
    );
  }

  String _dni(Map<String, dynamic> recibo) {
    return _texto(
      recibo['dni'] ?? recibo['documento'] ?? recibo['codigoUsuario'],
    );
  }

  String _periodo(Map<String, dynamic> recibo) {
    final mes = recibo['mes'];
    final anio = recibo['anio'];

    if (mes != null && anio != null) {
      const meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      final mesNumero = int.tryParse(mes.toString()) ?? 1;
      final index = (mesNumero - 1).clamp(0, 11);

      return '${meses[index]} $anio';
    }

    return _texto(
      recibo['periodo'] ?? recibo['mesFacturado'],
      'Periodo no registrado',
    );
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  double _lecturaAnterior(Map<String, dynamic> recibo) {
    return _numero(
      recibo['lecturaAnterior'] ??
          recibo['lectura_anterior'] ??
          recibo['anterior'] ??
          0,
    );
  }

  double _lecturaActual(Map<String, dynamic> recibo) {
    return _numero(
      recibo['lecturaActual'] ??
          recibo['lectura_actual'] ??
          recibo['actual'] ??
          0,
    );
  }

  double _volumenAgua(Map<String, dynamic> recibo) {
    return _numero(
      recibo['volumenAgua'] ??
          recibo['montoAgua'] ??
          recibo['importeAgua'] ??
          recibo['subtotalAgua'] ??
          recibo['total'] ??
          0,
    );
  }

  double _mantenimiento(Map<String, dynamic> recibo) {
    return _numero(
      recibo['mantenimiento'] ?? recibo['montoMantenimiento'] ?? 0,
    );
  }

  double _pagoLecturador(Map<String, dynamic> recibo) {
    return _numero(
      recibo['pagoLecturador'] ?? recibo['montoLecturador'] ?? 0,
    );
  }

  double _otrosCargos(Map<String, dynamic> recibo) {
    return _numero(
      recibo['otrosCargos'] ?? recibo['otros'] ?? 0,
    );
  }

  double _mora(Map<String, dynamic> recibo) {
    return _numero(
      recibo['mora'] ?? recibo['montoMora'] ?? 0,
    );
  }

  double _total(Map<String, dynamic> recibo) {
    return _numero(
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    );
  }

  String _vencimiento(Map<String, dynamic> recibo) {
    return _texto(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
      '-',
    );
  }

  String _emision(Map<String, dynamic> recibo) {
    return _texto(
      recibo['fechaEmision'] ?? recibo['emision'],
      '-',
    );
  }

  bool _puedePagar(Map<String, dynamic> recibo) {
    return _estado(recibo).toUpperCase() == 'PENDIENTE';
  }

  void _irPagar(BuildContext context, Map<String, dynamic> recibo) {
    Navigator.pushNamed(
      context,
      '/pago-cip',
      arguments: recibo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, recibo),
              const SizedBox(height: 18),
              _buildReciboCard(context, recibo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> recibo) {
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalle del recibo',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _codigoRecibo(recibo),
                style: const TextStyle(
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

  Widget _buildReciboCard(BuildContext context, Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    final puedePagar = _puedePagar(recibo);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTopBlue(recibo, estado),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              children: [
                _buildClienteInfo(recibo),
                const SizedBox(height: 14),
                _buildPeriodoInfo(recibo),
                const SizedBox(height: 14),
                _buildLecturas(recibo),
                const SizedBox(height: 14),
                _buildDetalleFacturacion(recibo),
                const SizedBox(height: 14),
                _buildTotal(recibo),
                const SizedBox(height: 16),
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
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          backgroundColor: const Color(0xFFF0FAFD),
                          side: const BorderSide(color: Color(0xFFE2EDF3)),
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    if (puedePagar) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _irPagar(context, recibo),
                          icon: const Icon(Icons.payments_rounded),
                          label: const Text('Pagar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
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
        ],
      ),
    );
  }

  Widget _buildTopBlue(Map<String, dynamic> recibo, String estado) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JASS HUACARIZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _periodo(recibo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _EstadoBadge(estado: estado),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vence: ${_vencimiento(recibo)}',
                  style: const TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClienteInfo(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Datos del cliente',
      children: [
        _InfoRow(label: 'Titular', value: _titular(recibo)),
        _InfoRow(label: 'DNI / Código', value: _dni(recibo)),
        _InfoRow(label: 'Suministro', value: _codigoSuministro(recibo)),
        _InfoRow(label: 'Dirección', value: _direccion(recibo)),
        _InfoRow(label: 'Sector', value: _sector(recibo)),
      ],
    );
  }

  Widget _buildPeriodoInfo(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Información del periodo',
      children: [
        _InfoRow(label: 'Periodo', value: _periodo(recibo)),
        _InfoRow(label: 'Fecha emisión', value: _emision(recibo)),
        _InfoRow(label: 'Vencimiento', value: _vencimiento(recibo)),
      ],
    );
  }

  Widget _buildLecturas(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Lecturas y consumo',
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniBox(
                label: 'Anterior',
                value: _lecturaAnterior(recibo).toStringAsFixed(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniBox(
                label: 'Actual',
                value: _lecturaActual(recibo).toStringAsFixed(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniBox(
                label: 'Consumo',
                value: '${_consumo(recibo).toStringAsFixed(2)} m³',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetalleFacturacion(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Detalle de facturación',
      children: [
        _InfoRow(
          label: 'Volumen de agua potable',
          value: 'S/ ${_volumenAgua(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Mantenimiento',
          value: 'S/ ${_mantenimiento(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Pago al lecturador',
          value: 'S/ ${_pagoLecturador(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Otros cargos',
          value: 'S/ ${_otrosCargos(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Mora',
          value: 'S/ ${_mora(recibo).toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildTotal(Map<String, dynamic> recibo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD899)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Total a pagar',
              style: TextStyle(
                color: primary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'S/ ${_total(recibo).toStringAsFixed(2)}',
            style: const TextStyle(
              color: primary,
              fontSize: 26,
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
      padding: const EdgeInsets.all(15),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(width: 12),
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

class _MiniBox extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
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

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final estadoUpper = estado.toUpperCase();

    Color bg;
    Color text;

    if (estadoUpper == 'PAGADO') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (estadoUpper == 'VENCIDO') {
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
        estadoUpper,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}