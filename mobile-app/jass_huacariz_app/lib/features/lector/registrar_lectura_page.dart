import 'package:flutter/material.dart';

import '../../core/services/lectura_offline_service.dart';
import '../../core/services/lecturador_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class RegistrarLecturaPage extends StatefulWidget {
  final bool modoAdmin;

  const RegistrarLecturaPage({super.key, this.modoAdmin = false});

  @override
  State<RegistrarLecturaPage> createState() => _RegistrarLecturaPageState();
}

class _RegistrarLecturaPageState extends State<RegistrarLecturaPage> {
  final LecturadorService lecturadorService = LecturadorService();
  final LecturaOfflineService offlineService = LecturaOfflineService();
  final SecureStorageService storage = SecureStorageService();

  final TextEditingController lecturaController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();
  final TextEditingController lecturaInicialNuevoMedidorController =
      TextEditingController(text: '0');
  final TextEditingController observacionCambioMedidorController =
      TextEditingController();

  Map<String, dynamic> suministro = {};
  Map<String, dynamic>? reciboEstimado;
  bool cargadoArgs = false;
  bool guardando = false;
  bool calculando = false;
  bool cambioMedidor = false;
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

    if (esMantenimiento) {
      lecturaController.text = lecturaAnterior.toStringAsFixed(3);
      if (observacionController.text.trim().isEmpty) {
        observacionController.text = 'Recibo de mantenimiento generado';
      }
    } else if (observacionController.text.trim().isEmpty) {
      observacionController.text = 'Lectura mensual registrada';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarEstimado();
    });
  }

  @override
  void dispose() {
    lecturaController.dispose();
    observacionController.dispose();
    lecturaInicialNuevoMedidorController.dispose();
    observacionCambioMedidorController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  String get codigo => _txt(
    suministro['codigoSuministro'] ??
        suministro['suministroCodigo'] ??
        suministro['codigo'],
    'SIN-CÓDIGO',
  );

  String get titular => _txt(
    suministro['nombreCliente'] ??
        suministro['titular'] ??
        suministro['cliente'],
    'Usuario del servicio',
  );

  String get direccion => _txt(
    suministro['direccionSuministro'] ?? suministro['direccion'],
    'Dirección no registrada',
  );

  String get sector => _txt(
    suministro['nombreSector'] ?? suministro['sector'],
    'Sector no registrado',
  );

  double get lecturaAnterior => _num(
    suministro['lecturaAnterior'] ??
        suministro['ultimaLectura'] ??
        suministro['lecturaInicial'],
  );

  String get tipoOperacion {
    final explicito = _txt(suministro['tipoOperacion'], '').toUpperCase();
    if (explicito == 'MANTENIMIENTO' || explicito == 'LECTURA') {
      return explicito;
    }
    final estado = _txt(
      suministro['estadoInstalacion'],
      'PENDIENTE_INSTALACION',
    ).toUpperCase();
    return estado == 'INSTALADO' ? 'LECTURA' : 'MANTENIMIENTO';
  }

  bool get esMantenimiento => tipoOperacion == 'MANTENIMIENTO';

  String get estadoInstalacion => _txt(
    suministro['estadoInstalacion'],
    esMantenimiento ? 'PENDIENTE_INSTALACION' : 'INSTALADO',
  ).toUpperCase();

  bool get suministroActivo {
    final value = suministro['activo'] ?? suministro['estado'];

    if (value is bool) return value;
    if (value == null) return true;

    final text = value.toString().toLowerCase().trim();

    if (text == 'false' ||
        text == 'inactivo' ||
        text == 'suspendido' ||
        text == '0') {
      return false;
    }

    return true;
  }

  bool get lecturaDigitada => lecturaController.text.trim().isNotEmpty;

  bool get sinConsumo {
    if (esMantenimiento || cambioMedidor || !lecturaDigitada) return false;
    return (lecturaActualIngresada - lecturaAnterior).abs() < 0.0001;
  }

  bool get consumoInusual {
    if (esMantenimiento || !lecturaDigitada) return false;
    return consumo >= 50;
  }

  double get lecturaActualIngresada {
    if (esMantenimiento) return lecturaAnterior;
    return double.tryParse(
          lecturaController.text.trim().replaceAll(',', '.'),
        ) ??
        lecturaAnterior;
  }

  double get lecturaInicialNuevoMedidor {
    return double.tryParse(
          lecturaInicialNuevoMedidorController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  double get baseCalculoConsumo {
    if (esMantenimiento) return lecturaAnterior;
    return cambioMedidor ? lecturaInicialNuevoMedidor : lecturaAnterior;
  }

  double get consumo {
    if (esMantenimiento) return 0;
    final valor = lecturaActualIngresada - baseCalculoConsumo;
    return valor < 0 ? 0 : valor;
  }

  String _nombreMes(int mes) {
    const nombres = [
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
    return nombres[(mes - 1).clamp(0, 11)];
  }

  Future<void> _actualizarEstimado() async {
    if (widget.modoAdmin) return;
    if (!esMantenimiento && lecturaController.text.trim().isEmpty) {
      if (mounted) setState(() => reciboEstimado = null);
      return;
    }
    if (lecturaActualIngresada < baseCalculoConsumo) return;

    setState(() => calculando = true);
    try {
      final recibo = await offlineService.calcularReciboEstimado(
        suministro: suministro,
        tipoOperacion: tipoOperacion,
        consumo: consumo,
        anio: anioSeleccionado,
        mes: mesSeleccionado,
      );
      if (!mounted) return;
      setState(() {
        reciboEstimado = recibo;
        calculando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        reciboEstimado = null;
        calculando = false;
      });
    }
  }

  bool _esErrorConexion(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network is unreachable') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('clientexception') ||
        text.contains('tiempo de espera') ||
        text.contains('backend esté encendido');
  }

  Future<void> registrar() async {
    if (codigo == 'SIN-CÓDIGO') {
      _mensaje('No se encontró el código del suministro.', true);
      return;
    }

    if (!suministroActivo) {
      _mensaje(
        'Suministro suspendido o inactivo. No se puede registrar una lectura desde la app.',
        true,
      );
      return;
    }

    final lecturaActual = lecturaActualIngresada;
    if (!esMantenimiento && lecturaController.text.trim().isEmpty) {
      _mensaje('Ingresa la lectura actual.', true);
      return;
    }
    if (!esMantenimiento && cambioMedidor) {
      if (lecturaInicialNuevoMedidorController.text.trim().isEmpty) {
        _mensaje('Ingresa la lectura inicial del nuevo medidor.', true);
        return;
      }
      if (lecturaActual < lecturaInicialNuevoMedidor) {
        _mensaje(
          'La lectura actual no puede ser menor a la lectura inicial del nuevo medidor.',
          true,
        );
        return;
      }
      if (observacionCambioMedidorController.text.trim().isEmpty) {
        _mensaje('Ingresa la observación del cambio de medidor.', true);
        return;
      }
    }

    if (!esMantenimiento && !cambioMedidor && lecturaActual < lecturaAnterior) {
      _mensaje('La lectura actual no puede ser menor a la anterior.', true);
      return;
    }

    setState(() => guardando = true);

    try {
      Map<String, dynamic> response;
      bool guardadoLocal = false;

      if (widget.modoAdmin) {
        response = esMantenimiento
            ? await lecturadorService.registrarMantenimiento(
                codigoSuministro: codigo,
                anio: anioSeleccionado,
                mes: mesSeleccionado,
                observacion: observacionController.text.trim(),
              )
            : await lecturadorService.registrarLectura(
                codigoSuministro: codigo,
                lecturaActual: lecturaActual,
                anio: anioSeleccionado,
                mes: mesSeleccionado,
                observacion: observacionController.text.trim(),
                cambioMedidor: cambioMedidor,
                lecturaInicialNuevoMedidor: cambioMedidor
                    ? lecturaInicialNuevoMedidor
                    : null,
                observacionCambioMedidor: cambioMedidor
                    ? observacionCambioMedidorController.text.trim()
                    : null,
              );
      } else {
        final modoOffline = await storage.isOfflineMode();
        if (modoOffline) {
          response = await _guardarLocal(lecturaActual);
          guardadoLocal = true;
        } else {
          try {
            response = esMantenimiento
                ? await lecturadorService.registrarMantenimiento(
                    codigoSuministro: codigo,
                    anio: anioSeleccionado,
                    mes: mesSeleccionado,
                    observacion: observacionController.text.trim(),
                  )
                : await lecturadorService.registrarLectura(
                    codigoSuministro: codigo,
                    lecturaActual: lecturaActual,
                    anio: anioSeleccionado,
                    mes: mesSeleccionado,
                    observacion: observacionController.text.trim(),
                    cambioMedidor: cambioMedidor,
                    lecturaInicialNuevoMedidor: cambioMedidor
                        ? lecturaInicialNuevoMedidor
                        : null,
                    observacionCambioMedidor: cambioMedidor
                        ? observacionCambioMedidorController.text.trim()
                        : null,
                  );
          } catch (e) {
            if (!_esErrorConexion(e)) rethrow;
            response = await _guardarLocal(lecturaActual);
            guardadoLocal = true;
          }
        }
      }

      if (!mounted) return;
      setState(() => guardando = false);

      final comprobante = {
        ...suministro,
        ...response,
        'codigoSuministro': response['codigoSuministro'] ?? codigo,
        'lecturaAnterior': response['lecturaAnterior'] ?? lecturaAnterior,
        'lecturaActual': response['lecturaActual'] ?? lecturaActual,
        'consumoM3': response['consumoM3'] ?? consumo,
        'anio': response['anio'] ?? anioSeleccionado,
        'mes': response['mes'] ?? mesSeleccionado,
        'tipoOperacion': tipoOperacion,
        'cambioMedidor': response['cambioMedidor'] ?? cambioMedidor,
        'lecturaInicialNuevoMedidor':
            response['lecturaInicialNuevoMedidor'] ??
            (cambioMedidor ? lecturaInicialNuevoMedidor : null),
        'observacionCambioMedidor':
            response['observacionCambioMedidor'] ??
            (cambioMedidor
                ? observacionCambioMedidorController.text.trim()
                : null),
        'origenOffline': response['origenOffline'] ?? guardadoLocal,
      };

      _mensaje(
        guardadoLocal
            ? 'Guardado en el celular. Se enviará al recuperar conexión.'
            : esMantenimiento
            ? 'Recibo de mantenimiento generado correctamente.'
            : 'Lectura registrada correctamente.',
        false,
      );

      Navigator.pushReplacementNamed(
        context,
        widget.modoAdmin ? '/admin-comprobante-recibo' : '/comprobante-recibo',
        arguments: comprobante,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => guardando = false);
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  Future<Map<String, dynamic>> _guardarLocal(double lecturaActual) {
    if (esMantenimiento) {
      return offlineService.registrarMantenimientoLocal(
        suministro: suministro,
        anio: anioSeleccionado,
        mes: mesSeleccionado,
        observacion: observacionController.text.trim(),
      );
    }
    return offlineService.registrarLecturaLocal(
      suministro: suministro,
      lecturaActual: lecturaActual,
      anio: anioSeleccionado,
      mes: mesSeleccionado,
      observacion: observacionController.text.trim(),
      cambioMedidor: cambioMedidor,
      lecturaInicialNuevoMedidor: cambioMedidor
          ? lecturaInicialNuevoMedidor
          : null,
      observacionCambioMedidor: cambioMedidor
          ? observacionCambioMedidorController.text.trim()
          : '',
    );
  }

  void _mensaje(String mensaje, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? JassColors.danger : JassColors.success,
      ),
    );
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(
        context,
        widget.modoAdmin ? '/admin-buscar-suministro' : '/buscar-suministro',
      );
    }
  }

  void _goAdmin(int index) {
    const rutas = [
      '/admin-dashboard',
      '/admin-clientes',
      '/admin-tarifas',
      '/admin-recibos',
    ];
    if (index >= 0 && index < rutas.length) {
      Navigator.pushReplacementNamed(context, rutas[index]);
    }
  }

  void _goLector(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/lector-home');
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/buscar-suministro');
    }
    if (index == 2) Navigator.pushNamed(context, '/qr-scanner');
    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/historial-lecturas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _num(reciboEstimado?['total']);
    final textoBoton = guardando
        ? 'Guardando...'
        : esMantenimiento
        ? 'Generar recibo de mantenimiento'
        : sinConsumo
        ? 'Marcar consumo cero'
        : 'Registrar lectura y generar recibo';

    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: widget.modoAdmin
          ? AdminBottomNav(
              currentIndex: -1,
              onTap: _goAdmin,
              onPlus: () => showAdminQuickMenu(context: context),
            )
          : LectorBottomNav(
              currentIndex: 1,
              onTap: _goLector,
              onPlus: () => showLectorQuickMenu(context: context),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: esMantenimiento
                    ? 'Solo mantenimiento'
                    : 'Registrar lectura',
                subtitle: widget.modoAdmin
                    ? 'Panel del administrador'
                    : 'Módulo lecturador',
                onBack: _volver,
              ),
              const SizedBox(height: 18),
              _SupplyCard(
                codigo: codigo,
                titular: titular,
                direccion: direccion,
                sector: sector,
                lecturaAnterior: lecturaAnterior,
                mantenimiento: esMantenimiento,
                offline: suministro['origenOffline'] == true,
              ),
              const SizedBox(height: 12),
              _OperationalStatusCard(
                activo: suministroActivo,
                mantenimiento: esMantenimiento,
                estadoInstalacion: estadoInstalacion,
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periodo del recibo',
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: mesSeleccionado,
                            decoration: _inputDecoration(context, 'Mes'),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_nombreMes(index + 1)),
                              ),
                            ),
                            onChanged: guardando
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => mesSeleccionado = value);
                                    _actualizarEstimado();
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: anioSeleccionado,
                            decoration: _inputDecoration(context, 'Año'),
                            items: List.generate(3, (index) {
                              final year = DateTime.now().year - 1 + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                            onChanged: guardando
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => anioSeleccionado = value);
                                    _actualizarEstimado();
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (!esMantenimiento) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: lecturaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _actualizarEstimado();
                        },
                        decoration: _inputDecoration(
                          context,
                          'Lectura actual del medidor',
                          icon: Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cambioMedidor
                              ? const Color(0xFFEAF7FC)
                              : context.jassSurfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cambioMedidor
                                ? JassColors.primary
                                : context.jassBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: cambioMedidor,
                              activeColor: JassColors.primary,
                              title: Text(
                                'Cambio de medidor',
                                style: TextStyle(
                                  color: context.jassTextPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              subtitle: const Text(
                                'Activa esta opción si el medidor fue reemplazado y la lectura reinicia desde otro valor.',
                              ),
                              onChanged: guardando
                                  ? null
                                  : (value) {
                                      setState(() {
                                        cambioMedidor = value;
                                        if (!value) {
                                          lecturaInicialNuevoMedidorController
                                                  .text =
                                              '0';
                                          observacionCambioMedidorController
                                              .clear();
                                        }
                                      });
                                      _actualizarEstimado();
                                    },
                            ),
                            if (cambioMedidor) ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller:
                                    lecturaInicialNuevoMedidorController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) {
                                  setState(() {});
                                  _actualizarEstimado();
                                },
                                decoration: _inputDecoration(
                                  context,
                                  'Lectura inicial del nuevo medidor',
                                  icon: Icons.water_drop_outlined,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: observacionCambioMedidorController,
                                maxLines: 2,
                                decoration: _inputDecoration(
                                  context,
                                  'Observación del cambio de medidor',
                                  icon: Icons.build_circle_outlined,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: cambioMedidor
                                  ? 'Inicial nuevo'
                                  : 'Anterior',
                              value:
                                  '${baseCalculoConsumo.toStringAsFixed(3)} m³',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Metric(
                              label: 'Consumo',
                              value: '${consumo.toStringAsFixed(3)} m³',
                            ),
                          ),
                        ],
                      ),
                      ..._buildAvisosLectura(),
                    ] else ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'No se registra consumo. El recibo incluirá únicamente el cargo de mantenimiento configurado.',
                          style: TextStyle(
                            color: Color(0xFF8A5B00),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: observacionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        context,
                        'Observación (opcional)',
                        icon: Icons.note_alt_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _AmountCard(
                loading: calculando,
                total: total,
                receipt: reciboEstimado,
                provisional: !widget.modoAdmin,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: guardando ? null : registrar,
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          esMantenimiento
                              ? Icons.home_repair_service_rounded
                              : Icons.save_outlined,
                        ),
                  label: Text(
                    textoBoton,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JassColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAvisosLectura() {
    final widgets = <Widget>[];

    if (!lecturaDigitada) return widgets;

    if (sinConsumo) {
      widgets.add(
        const _NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Sin consumo registrado',
          message:
              'La lectura actual es igual a la lectura anterior. Se generará un recibo con consumo 0.00 m³.',
          color: Color(0xFF1593C7),
          background: Color(0xFFEAF7FC),
        ),
      );
    }

    if (consumoInusual) {
      widgets.add(
        const _NoticeCard(
          icon: Icons.warning_amber_rounded,
          title: 'Consumo inusual detectado',
          message:
              'Verifica la lectura antes de registrar. El consumo calculado es mayor al rango esperado.',
          color: Color(0xFFC2410C),
          background: Color(0xFFFFF1DC),
        ),
      );
    }

    if (cambioMedidor) {
      widgets.add(
        const _NoticeCard(
          icon: Icons.build_circle_outlined,
          title: 'Cambio de medidor activado',
          message:
              'El consumo se calculará desde la lectura inicial del nuevo medidor.',
          color: Color(0xFF0F617E),
          background: Color(0xFFEAF7FC),
        ),
      );
    }

    return widgets
        .map(
          (widget) =>
              Padding(padding: const EdgeInsets.only(top: 12), child: widget),
        )
        .toList();
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: context.jassSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: context.jassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: context.jassBorder),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.jassBorder),
          ),
          child: IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: context.jassTextPrimary,
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
}

class _SupplyCard extends StatelessWidget {
  final String codigo;
  final String titular;
  final String direccion;
  final String sector;
  final double lecturaAnterior;
  final bool mantenimiento;
  final bool offline;

  const _SupplyCard({
    required this.codigo,
    required this.titular,
    required this.direccion,
    required this.sector,
    required this.lecturaAnterior,
    required this.mantenimiento,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [JassColors.primary, JassColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  codigo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (offline)
                const Icon(Icons.cloud_off_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titular,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$direccion · $sector',
            style: const TextStyle(
              color: Color(0xFFDDF6FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mantenimiento
                ? 'Operación: solo mantenimiento'
                : 'Lectura anterior: ${lecturaAnterior.toStringAsFixed(3)} m³',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: child,
    );
  }
}

class _OperationalStatusCard extends StatelessWidget {
  final bool activo;
  final bool mantenimiento;
  final String estadoInstalacion;

  const _OperationalStatusCard({
    required this.activo,
    required this.mantenimiento,
    required this.estadoInstalacion,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color background;
    final IconData icon;
    final String title;
    final String message;

    if (!activo) {
      color = JassColors.danger;
      background = const Color(0xFFFFECEC);
      icon = Icons.block_rounded;
      title = 'Suministro suspendido o inactivo';
      message =
          'No se debe registrar lectura mensual mientras el suministro esté suspendido.';
    } else if (mantenimiento) {
      color = const Color(0xFFB45309);
      background = const Color(0xFFFFF4DD);
      icon = Icons.home_repair_service_rounded;
      title = 'Suministro pendiente de instalación';
      message =
          'Este suministro aún no está instalado. Solo se generará recibo de mantenimiento si corresponde.';
    } else {
      color = JassColors.success;
      background = const Color(0xFFEAF8EF);
      icon = Icons.verified_rounded;
      title = 'Estado operativo';
      message =
          'Suministro instalado y activo. Puede registrar la lectura actual del medidor.';
    }

    return _NoticeCard(
      icon: icon,
      title: title,
      message: message,
      color: color,
      background: background,
      trailing: estadoInstalacion.replaceAll('_', ' '),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;
  final String? trailing;

  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.background,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          trailing!,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final bool loading;
  final double total;
  final Map<String, dynamic>? receipt;
  final bool provisional;

  const _AmountCard({
    required this.loading,
    required this.total,
    required this.receipt,
    required this.provisional,
  });

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : receipt == null
          ? Text(
              'El monto se mostrará al ingresar una lectura válida. Para calcular sin internet, primero actualiza el catálogo.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provisional ? 'Monto provisional' : 'Monto calculado',
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _AmountLine('Agua', _num(receipt?['subtotalAgua'])),
                _AmountLine(
                  'Mantenimiento',
                  _num(receipt?['cargoMantenimiento']),
                ),
                _AmountLine('Lector', _num(receipt?['cargoLector'])),
                _AmountLine('Otros', _num(receipt?['cargoOtros'])),
                if (provisional) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'El backend confirmará el monto oficial al sincronizar.',
                    style: TextStyle(
                      color: JassColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  final String label;
  final double amount;

  const _AmountLine(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'S/ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
