import 'package:flutter/material.dart';

import '../../core/services/lectura_admin_service.dart';

class HistorialLecturasPage extends StatefulWidget {
  const HistorialLecturasPage({super.key});

  @override
  State<HistorialLecturasPage> createState() => _HistorialLecturasPageState();
}

class _HistorialLecturasPageState extends State<HistorialLecturasPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final LecturaAdminService lecturaService = LecturaAdminService();
  final TextEditingController buscarController = TextEditingController();

  List<Map<String, dynamic>> lecturas = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _codigoSuministro(Map<String, dynamic> lectura) {
    return _txt(
      lectura['codigoSuministro'] ??
          lectura['suministroCodigo'] ??
          lectura['codigo'] ??
          lectura['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _cliente(Map<String, dynamic> lectura) {
    return _txt(
      lectura['titular'] ??
          lectura['cliente'] ??
          lectura['nombreCliente'] ??
          lectura['nombres'] ??
          lectura['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> lectura) {
    return _txt(
      lectura['direccionSuministro'] ??
          lectura['direccion'] ??
          lectura['direccionCliente'],
      'Dirección no registrada',
    );
  }

  double _lecturaAnterior(Map<String, dynamic> lectura) {
    return _num(
      lectura['lecturaAnterior'] ??
          lectura['ultimaLectura'] ??
          lectura['lecturaInicial'] ??
          0,
    );
  }

  double _lecturaActual(Map<String, dynamic> lectura) {
    return _num(
      lectura['lecturaActual'] ??
          lectura['lecturaNueva'] ??
          lectura['actual'] ??
          0,
    );
  }

  double _consumo(Map<String, dynamic> lectura) {
    final consumo = _num(
      lectura['consumoM3'] ??
          lectura['consumo'] ??
          lectura['consumoMes'],
    );

    if (consumo > 0) return consumo;

    final calculado = _lecturaActual(lectura) - _lecturaAnterior(lectura);
    return calculado < 0 ? 0 : calculado;
  }

  String _periodo(Map<String, dynamic> lectura) {
    final anio = int.tryParse('${lectura['anio'] ?? DateTime.now().year}') ??
        DateTime.now().year;

    final mes = int.tryParse('${lectura['mes'] ?? DateTime.now().month}') ??
        DateTime.now().month;

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

    final index = (mes - 1).clamp(0, 11);
    return '${meses[index]} $anio';
  }

  String _fecha(Map<String, dynamic> lectura) {
    return _txt(
      lectura['fechaLectura'] ??
          lectura['fechaRegistro'] ??
          lectura['createdAt'] ??
          lectura['fechaEmision'],
      '-',
    );
  }

  List<Map<String, dynamic>> get lecturasFiltradas {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return lecturas;

    return lecturas.where((lectura) {
      final texto = '''
      ${_codigoSuministro(lectura)}
      ${_cliente(lectura)}
      ${_direccion(lectura)}
      ${_periodo(lectura)}
      ${_fecha(lectura)}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarHistorial() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await lecturaService.listarHistorial();

      if (!mounted) return;

      setState(() {
        lecturas = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  void _volverInicio() {
    Navigator.pushReplacementNamed(context, '/lector-home');
  }

  void _nuevaLectura() {
    Navigator.pushReplacementNamed(context, '/buscar-suministro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        onPressed: _nuevaLectura,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarHistorial,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildSearch(),
                const SizedBox(height: 18),
                if (cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _ErrorCard(
                    error: error,
                    onRetry: cargarHistorial,
                  ),
                if (!cargando && error.isEmpty && lecturasFiltradas.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No hay lecturas registradas.',
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...lecturasFiltradas.map((lectura) {
                    return _LecturaCard(
                      codigo: _codigoSuministro(lectura),
                      cliente: _cliente(lectura),
                      direccion: _direccion(lectura),
                      periodo: _periodo(lectura),
                      fecha: _fecha(lectura),
                      lecturaAnterior: _lecturaAnterior(lectura),
                      lecturaActual: _lecturaActual(lectura),
                      consumo: _consumo(lectura),
                    );
                  }),
              ],
            ),
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
                'Historial de lecturas',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargarHistorial,
          icon: const Icon(
            Icons.refresh_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: buscarController,
      onChanged: (value) {
        setState(() {
          busqueda = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar por suministro, cliente o periodo...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _LecturaCard extends StatelessWidget {
  final String codigo;
  final String cliente;
  final String direccion;
  final String periodo;
  final String fecha;
  final double lecturaAnterior;
  final double lecturaActual;
  final double consumo;

  const _LecturaCard({
    required this.codigo,
    required this.cliente,
    required this.direccion,
    required this.periodo,
    required this.fecha,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.consumo,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color muted = Color(0xFF7B8794);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cliente,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            direccion,
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Periodo',
                  value: periodo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Fecha',
                  value: fecha,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Anterior',
                  value: lecturaAnterior.toStringAsFixed(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Actual',
                  value: lecturaActual.toStringAsFixed(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Consumo',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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