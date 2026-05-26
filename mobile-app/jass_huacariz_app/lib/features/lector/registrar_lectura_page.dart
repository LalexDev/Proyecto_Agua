import 'package:flutter/material.dart';

import '../../core/services/lecturador_service.dart';

class RegistrarLecturaPage extends StatefulWidget {
  const RegistrarLecturaPage({super.key});

  @override
  State<RegistrarLecturaPage> createState() => _RegistrarLecturaPageState();
}

class _RegistrarLecturaPageState extends State<RegistrarLecturaPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final LecturadorService lecturadorService = LecturadorService();

  final TextEditingController lecturaController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  Map<String, dynamic> suministro = {};
  bool cargadoArgs = false;
  bool guardando = false;

  int anioSeleccionado = DateTime.now().year;
  int mesSeleccionado = DateTime.now().month;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (cargadoArgs) return;
    cargadoArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      suministro = args;
    } else if (args is Map) {
      suministro = Map<String, dynamic>.from(args);
    }

    anioSeleccionado = DateTime.now().year;
    mesSeleccionado = DateTime.now().month;
  }

  @override
  void dispose() {
    lecturaController.dispose();
    observacionController.dispose();
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

  int _anioActual() => anioSeleccionado;

  int _mesActual() => mesSeleccionado;

  String _nombreMes(int mes) {
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
    return meses[index];
  }

  String _codigoSuministro() {
    return _txt(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _titular() {
    return _txt(
      suministro['titular'] ??
          suministro['cliente'] ??
          suministro['nombreCliente'] ??
          suministro['nombres'] ??
          suministro['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion() {
    return _txt(
      suministro['direccionSuministro'] ??
          suministro['direccion'] ??
          suministro['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _sector() {
    return _txt(
      suministro['nombreSector'] ??
          suministro['sector'] ??
          suministro['sectorNombre'],
      'Huacariz',
    );
  }

  double _lecturaAnterior() {
    return _num(
      suministro['lecturaAnterior'] ??
          suministro['ultimaLectura'] ??
          suministro['lecturaActual'] ??
          suministro['lecturaInicial'] ??
          0,
    );
  }

  double _consumoCalculado() {
    final lecturaActual = double.tryParse(lecturaController.text.trim()) ?? 0;
    final consumo = lecturaActual - _lecturaAnterior();

    if (consumo < 0) return 0;

    return consumo;
  }

  Future<void> registrarLectura() async {
    final codigo = _codigoSuministro();
    final lecturaActual = double.tryParse(lecturaController.text.trim());

    if (codigo == 'SIN-CÓDIGO') {
      _mensaje('No se encontró el código del suministro.', true);
      return;
    }

    if (lecturaActual == null) {
      _mensaje('Ingresa una lectura válida.', true);
      return;
    }

    if (lecturaActual < _lecturaAnterior()) {
      _mensaje('La lectura actual no puede ser menor a la anterior.', true);
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final response = await lecturadorService.registrarLectura(
        codigoSuministro: codigo,
        lecturaActual: lecturaActual,
        anio: _anioActual(),
        mes: _mesActual(),
        observacion: observacionController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      final comprobante = {
        ...suministro,
        ...response,
        'codigoSuministro': response['codigoSuministro'] ?? codigo,
        'lecturaAnterior': response['lecturaAnterior'] ?? _lecturaAnterior(),
        'lecturaActual': response['lecturaActual'] ?? lecturaActual,
        'consumoM3':
            response['consumoM3'] ?? (lecturaActual - _lecturaAnterior()),
        'observacion':
            response['observacion'] ?? observacionController.text.trim(),
        'anio': response['anio'] ?? _anioActual(),
        'mes': response['mes'] ?? _mesActual(),
      };

      _mensaje('Lectura registrada correctamente.', false);

      Navigator.pushReplacementNamed(
        context,
        '/comprobante-recibo',
        arguments: comprobante,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
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

  void _volverBuscar() {
    Navigator.pushReplacementNamed(context, '/buscar-suministro');
  }

  @override
  Widget build(BuildContext context) {
    final lecturaAnterior = _lecturaAnterior();
    final consumo = _consumoCalculado();

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
              _buildSuministroCard(),
              const SizedBox(height: 18),
              _buildPeriodoSelector(),
              const SizedBox(height: 18),
              _buildLecturaForm(
                lecturaAnterior: lecturaAnterior,
                consumo: consumo,
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
            onPressed: _volverBuscar,
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
                'Registrar lectura',
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

  Widget _buildSuministroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suministro seleccionado',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _codigoSuministro(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _WhiteInfo(label: 'Titular', value: _titular()),
          _WhiteInfo(label: 'Dirección', value: _direccion()),
          _WhiteInfo(label: 'Sector', value: _sector()),
        ],
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    final anioActual = DateTime.now().year;

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
            'Periodo de lectura',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: mesSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Mes',
                    filled: true,
                    fillColor: const Color(0xFFF4F8FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    final mes = index + 1;

                    return DropdownMenuItem<int>(
                      value: mes,
                      child: Text(_nombreMes(mes)),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      mesSeleccionado = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: anioSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Año',
                    filled: true,
                    fillColor: const Color(0xFFF4F8FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    anioActual - 1,
                    anioActual,
                    anioActual + 1,
                  ].map((anio) {
                    return DropdownMenuItem<int>(
                      value: anio,
                      child: Text('$anio'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      anioSeleccionado = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Periodo seleccionado: ${_nombreMes(mesSeleccionado)} $anioSeleccionado',
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturaForm({
    required double lecturaAnterior,
    required double consumo,
  }) {
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
            'Datos de lectura',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LecturaValorCard(
                  label: 'Lectura anterior',
                  value: lecturaAnterior.toStringAsFixed(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LecturaValorCard(
                  label: 'Consumo calculado',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lecturaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Lectura actual',
              hintText: 'Ingrese lectura actual del medidor',
              prefixIcon: const Icon(Icons.speed_rounded),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: observacionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observación',
              hintText: 'Opcional',
              prefixIcon: const Icon(Icons.note_alt_outlined),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: guardando ? null : registrarLectura,
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                guardando ? 'Registrando...' : 'Registrar lectura',
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

class _WhiteInfo extends StatelessWidget {
  final String label;
  final String value;

  const _WhiteInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE7F8FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LecturaValorCard extends StatelessWidget {
  final String label;
  final String value;

  const _LecturaValorCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}