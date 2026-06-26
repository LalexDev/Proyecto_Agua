import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/lecturador_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class RegistrarLecturaPage extends StatefulWidget {
  final bool modoAdmin;

  const RegistrarLecturaPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<RegistrarLecturaPage> createState() =>
      _RegistrarLecturaPageState();
}

class _RegistrarLecturaPageState extends State<RegistrarLecturaPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;

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
        widget.modoAdmin
            ? '/admin-comprobante-recibo'
            : '/comprobante-recibo',
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
    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-buscar-suministro'
          : '/buscar-suministro',
    );
  }

  void _goBottomAdmin(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(context: context);
  }

  void _goBottomLector(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/lector-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/buscar-suministro');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/qr-scanner');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/historial-lecturas');
    }
  }

  void _abrirMenuLector() {
    showLectorQuickMenu(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final lecturaAnterior = _lecturaAnterior();
    final consumo = _consumoCalculado();

    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: widget.modoAdmin
          ? AdminBottomNav(
              currentIndex: -1,
              onTap: _goBottomAdmin,
              onPlus: _abrirMenuAdmin,
            )
          : LectorBottomNav(
              currentIndex: -1,
              onTap: _goBottomLector,
              onPlus: _abrirMenuLector,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildSuministroCard(),
              SizedBox(height: 18),
              _buildPeriodoSelector(),
              SizedBox(height: 18),
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
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _volverBuscar,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.modoAdmin
                    ? 'Panel del administrador'
                    : 'Módulo lecturador',
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
          Text(
            'Suministro seleccionado',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _codigoSuministro(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
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
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periodo de lectura',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: mesSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Mes',
                    filled: true,
                    fillColor: context.jassSurfaceAlt,
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
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: anioSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Año',
                    filled: true,
                    fillColor: context.jassSurfaceAlt,
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
          SizedBox(height: 10),
          Text(
            'Periodo seleccionado: ${_nombreMes(mesSeleccionado)} $anioSeleccionado',
            style: TextStyle(
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
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos de lectura',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LecturaValorCard(
                  label: 'Lectura anterior',
                  value: lecturaAnterior.toStringAsFixed(0),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _LecturaValorCard(
                  label: 'Consumo calculado',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: lecturaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Lectura actual',
              hintText: 'Ingrese lectura actual del medidor',
              prefixIcon: Icon(Icons.speed_rounded),
              filled: true,
              fillColor: context.jassSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: observacionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observación',
              hintText: 'Opcional',
              prefixIcon: Icon(Icons.note_alt_outlined),
              filled: true,
              fillColor: context.jassSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: guardando ? null : registrarLectura,
              icon: guardando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save_outlined),
              label: Text(
                guardando ? 'Registrando...' : 'Registrar lectura',
                style: TextStyle(
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
              style: TextStyle(
                color: Color(0xFFE7F8FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
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
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
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
