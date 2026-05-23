import 'package:flutter/material.dart';

import '../../core/services/lecturador_service.dart';

class BuscarSuministroPage extends StatefulWidget {
  const BuscarSuministroPage({super.key});

  @override
  State<BuscarSuministroPage> createState() => _BuscarSuministroPageState();
}

class _BuscarSuministroPageState extends State<BuscarSuministroPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final LecturadorService lecturadorService = LecturadorService();
  final TextEditingController codigoController = TextEditingController();

  bool buscando = false;
  String error = '';
  Map<String, dynamic>? suministro;

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String _codigoSuministro(Map<String, dynamic> data) {
    return _txt(
      data['codigoSuministro'] ??
          data['suministroCodigo'] ??
          data['codigo'] ??
          data['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _titular(Map<String, dynamic> data) {
    return _txt(
      data['titular'] ??
          data['cliente'] ??
          data['nombreCliente'] ??
          data['nombres'] ??
          data['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> data) {
    return _txt(
      data['direccionSuministro'] ??
          data['direccion'] ??
          data['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _sector(Map<String, dynamic> data) {
    return _txt(
      data['nombreSector'] ?? data['sector'] ?? data['sectorNombre'],
      'Huacariz',
    );
  }

  double _lecturaAnterior(Map<String, dynamic> data) {
    final value = data['lecturaAnterior'] ??
        data['ultimaLectura'] ??
        data['lecturaActual'] ??
        data['lecturaInicial'] ??
        0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _activo(Map<String, dynamic> data) {
    final value = data['estado'] ?? data['activo'];

    if (value is bool) return value;

    if (value == null) return true;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  Future<void> buscarSuministro() async {
    final codigo = codigoController.text.trim();

    if (codigo.isEmpty) {
      _mensaje('Ingresa el código del suministro.', true);
      return;
    }

    setState(() {
      buscando = true;
      error = '';
      suministro = null;
    });

    try {
      final data = await lecturadorService.buscarSuministro(codigo);

      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          error = 'No se encontró información del suministro.';
          buscando = false;
        });
        return;
      }

      setState(() {
        suministro = data;
        buscando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        buscando = false;
      });
    }
  }

  void irRegistrarLectura() {
    final data = suministro;

    if (data == null) {
      _mensaje('Primero busca un suministro.', true);
      return;
    }

    Navigator.pushNamed(
      context,
      '/registrar-lectura',
      arguments: data,
    );
  }

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? const Color(0xFFD93025) : const Color(0xFF1F8F4D),
      ),
    );
  }

  void _volverInicio() {
    Navigator.pushReplacementNamed(context, '/lector-home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchCard(),
              const SizedBox(height: 18),
              if (buscando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (error.isNotEmpty && !buscando)
                _ErrorCard(
                  error: error,
                  onRetry: buscarSuministro,
                ),
              if (suministro != null && !buscando)
                _SuministroCard(
                  codigo: _codigoSuministro(suministro!),
                  titular: _titular(suministro!),
                  direccion: _direccion(suministro!),
                  sector: _sector(suministro!),
                  lecturaAnterior: _lecturaAnterior(suministro!),
                  activo: _activo(suministro!),
                  onRegistrar: irRegistrarLectura,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _volverInicio,
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
                'Módulo lecturador',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Buscar suministro',
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

  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de suministro',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa o escanea el código del suministro para registrar una nueva lectura.',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: codigoController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => buscarSuministro(),
            decoration: InputDecoration(
              hintText: 'Ejemplo: SUM-001',
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: buscando ? null : buscarSuministro,
              icon: buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                buscando ? 'Buscando...' : 'Buscar suministro',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
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
    );
  }
}

class _SuministroCard extends StatelessWidget {
  final String codigo;
  final String titular;
  final String direccion;
  final String sector;
  final double lecturaAnterior;
  final bool activo;
  final VoidCallback onRegistrar;

  const _SuministroCard({
    required this.codigo,
    required this.titular,
    required this.direccion,
    required this.sector,
    required this.lecturaAnterior,
    required this.activo,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F7FB),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  codigo,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(label: 'Titular', value: titular),
          _InfoLine(label: 'Dirección', value: direccion),
          _InfoLine(label: 'Sector', value: sector),
          _InfoLine(
            label: 'Última lectura',
            value: lecturaAnterior.toStringAsFixed(0),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: activo ? onRegistrar : null,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text(
                'Registrar lectura',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFE2EDF3),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFEAF8EF) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? const Color(0xFF1F8F4D) : const Color(0xFFD93025),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD93025),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}