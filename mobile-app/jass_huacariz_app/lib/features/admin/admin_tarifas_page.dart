import 'package:flutter/material.dart';

import '../../core/services/tarifa_service.dart';

class AdminTarifasPage extends StatefulWidget {
  const AdminTarifasPage({super.key});

  @override
  State<AdminTarifasPage> createState() => _AdminTarifasPageState();
}

class _AdminTarifasPageState extends State<AdminTarifasPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final TarifaService tarifaService = TarifaService();

  List<Map<String, dynamic>> tarifas = [];
  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarTarifas();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  int _idTarifa(Map<String, dynamic> tarifa) {
    final value = tarifa['id'] ?? tarifa['idTarifa'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _consumoDesde(Map<String, dynamic> tarifa) {
    return _numero(tarifa['consumoDesde'] ?? tarifa['desde'] ?? 0);
  }

  double? _consumoHasta(Map<String, dynamic> tarifa) {
    final value = tarifa['consumoHasta'] ?? tarifa['hasta'];

    if (value == null) return null;

    final text = value.toString().trim().toLowerCase();

    if (text.isEmpty || text == 'null' || text == '∞' || text == 'infinity') {
      return null;
    }

    return double.tryParse(text);
  }

  double _precioM3(Map<String, dynamic> tarifa) {
    return _numero(tarifa['precioM3'] ?? tarifa['precio'] ?? tarifa['monto'] ?? 0);
  }

  bool _estado(Map<String, dynamic> tarifa) {
    final value = tarifa['estado'];

    if (value is bool) return value;
    if (value == null) return true;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  String _nombreTarifa(Map<String, dynamic> tarifa) {
    final nombre = _txt(tarifa['nombreTarifa'] ?? tarifa['nombre'], '');

    if (nombre.isNotEmpty && nombre != '-') {
      return nombre;
    }

    final desde = _consumoDesde(tarifa);
    final hasta = _consumoHasta(tarifa);

    final desdeTxt = desde.toStringAsFixed(desde % 1 == 0 ? 0 : 1);

    if (hasta == null || hasta <= 0) {
      return 'Mayor a $desdeTxt m³';
    }

    final hastaTxt = hasta.toStringAsFixed(hasta % 1 == 0 ? 0 : 1);

    return 'Desde $desdeTxt hasta $hastaTxt m³';
  }

  String _rangoTarifa(Map<String, dynamic> tarifa) {
    final desde = _consumoDesde(tarifa);
    final hasta = _consumoHasta(tarifa);

    final desdeTxt = desde.toStringAsFixed(desde % 1 == 0 ? 0 : 1);

    if (hasta == null || hasta <= 0) {
      return 'Consumo mayor a $desdeTxt m³';
    }

    final hastaTxt = hasta.toStringAsFixed(hasta % 1 == 0 ? 0 : 1);

    return 'Desde $desdeTxt hasta $hastaTxt m³';
  }

  Future<void> cargarTarifas() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await tarifaService.listarTarifas();

      data.sort((a, b) {
        return _consumoDesde(a).compareTo(_consumoDesde(b));
      });

      if (!mounted) return;

      setState(() {
        tarifas = data;
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

  Future<void> _guardarTarifa({
    Map<String, dynamic>? tarifa,
    required Map<String, dynamic> payload,
  }) async {
    if (tarifa == null) {
      await tarifaService.registrarTarifa(payload);
      return;
    }

    final idTarifa = _idTarifa(tarifa);

    if (idTarifa <= 0) {
      throw Exception('No se encontró el ID de la tarifa.');
    }

    await tarifaService.actualizarTarifa(
      idTarifa: idTarifa,
      data: payload,
    );
  }

  void _abrirFormularioTarifa({Map<String, dynamic>? tarifa}) {
    final nombreController = TextEditingController(
      text: tarifa == null ? '' : _nombreTarifa(tarifa),
    );

    final desdeController = TextEditingController(
      text: tarifa == null ? '' : _consumoDesde(tarifa).toStringAsFixed(0),
    );

    final hastaController = TextEditingController(
      text: tarifa == null
          ? ''
          : (_consumoHasta(tarifa) == null
              ? ''
              : _consumoHasta(tarifa)!.toStringAsFixed(0)),
    );

    final precioController = TextEditingController(
      text: tarifa == null ? '' : _precioM3(tarifa).toStringAsFixed(2),
    );

    bool estado = tarifa == null ? true : _estado(tarifa);
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (contextSheet) {
        return StatefulBuilder(
          builder: (contextSheet, setModalState) {
            Future<void> guardar() async {
              final nombre = nombreController.text.trim();
              final desde = double.tryParse(desdeController.text.trim());
              final hastaText = hastaController.text.trim();
              final hasta =
                  hastaText.isEmpty ? null : double.tryParse(hastaText);
              final precio = double.tryParse(precioController.text.trim());

              if (nombre.isEmpty) {
                _mostrarMensaje('Ingresa el nombre de la tarifa.', true);
                return;
              }

              if (desde == null) {
                _mostrarMensaje('Ingresa el consumo desde.', true);
                return;
              }

              if (precio == null) {
                _mostrarMensaje('Ingresa el precio por m³.', true);
                return;
              }

              final payload = {
                'nombreTarifa': nombre,
                'consumoDesde': desde,
                'consumoHasta': hasta,
                'precioM3': precio,
                'estado': estado,
              };

              setModalState(() {
                guardando = true;
              });

              try {
                await _guardarTarifa(
                  tarifa: tarifa,
                  payload: payload,
                );

                if (!mounted) return;

                Navigator.pop(contextSheet);

                _mostrarMensaje(
                  tarifa == null
                      ? 'Tarifa registrada correctamente.'
                      : 'Tarifa actualizada correctamente.',
                  false,
                );

                await cargarTarifas();
              } catch (e) {
                setModalState(() {
                  guardando = false;
                });

                _mostrarMensaje(
                  e.toString().replaceFirst('Exception: ', ''),
                  true,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(contextSheet).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarifa == null ? 'Nueva tarifa' : 'Editar tarifa',
                      style: const TextStyle(
                        color: primary,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Configura los rangos y el precio por metro cúbico.',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Input(
                      controller: nombreController,
                      label: 'Nombre de tarifa',
                      keyboardType: TextInputType.text,
                    ),
                    _Input(
                      controller: desdeController,
                      label: 'Consumo desde m³',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _Input(
                      controller: hastaController,
                      label: 'Consumo hasta m³ (vacío si no tiene límite)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _Input(
                      controller: precioController,
                      label: 'Precio por m³ S/',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Estado',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          selected: estado,
                          selectedColor: const Color(0xFFEAF8EF),
                          backgroundColor: const Color(0xFFFFECEC),
                          label: Text(
                            estado ? 'Activa' : 'Inactiva',
                            style: TextStyle(
                              color: estado
                                  ? const Color(0xFF1F8F4D)
                                  : const Color(0xFFD93025),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              estado = !estado;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: guardando ? null : guardar,
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
                          guardando ? 'Guardando...' : 'Guardar cambios',
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
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarMensaje(String mensaje, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            error ? const Color(0xFFD93025) : const Color(0xFF1F8F4D),
      ),
    );
  }

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }

    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/admin-reportes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 2,
        onTap: _go,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormularioTarifa(),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarTarifas,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                if (cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(
                    error: error,
                    onRetry: cargarTarifas,
                  ),
                if (!cargando && error.isEmpty && tarifas.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay tarifas registradas.'),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  _TarifasCard(
                    tarifas: tarifas,
                    nombreTarifa: _nombreTarifa,
                    rangoTarifa: _rangoTarifa,
                    precioM3: _precioM3,
                    estado: _estado,
                    onEditar: (tarifa) {
                      _abrirFormularioTarifa(tarifa: tarifa);
                    },
                  ),
                const SizedBox(height: 90),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tarifas de pago',
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
          onPressed: cargarTarifas,
          icon: const Icon(
            Icons.refresh_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }
}

class _TarifasCard extends StatelessWidget {
  final List<Map<String, dynamic>> tarifas;
  final String Function(Map<String, dynamic>) nombreTarifa;
  final String Function(Map<String, dynamic>) rangoTarifa;
  final double Function(Map<String, dynamic>) precioM3;
  final bool Function(Map<String, dynamic>) estado;
  final Function(Map<String, dynamic>) onEditar;

  const _TarifasCard({
    required this.tarifas,
    required this.nombreTarifa,
    required this.rangoTarifa,
    required this.precioM3,
    required this.estado,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EDF3),
        ),
      ),
      child: Column(
        children: tarifas.map((tarifa) {
          final activo = estado(tarifa);

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE2EDF3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TarifaInfo(
                    titulo: nombreTarifa(tarifa),
                    subtitulo: rangoTarifa(tarifa),
                    activo: activo,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'S/ ${precioM3(tarifa).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF0F3D57),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onEditar(tarifa),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0F3D57),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TarifaInfo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool activo;

  const _TarifaInfo({
    required this.titulo,
    required this.subtitulo,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF0F3D57),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: const TextStyle(
            color: Color(0xFF7B8794),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activo ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: activo ? const Color(0xFF1F8F4D) : const Color(0xFFD93025),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _Input({
    required this.controller,
    required this.label,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F8FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _Error({
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

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 76,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_rounded),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.attach_money_rounded),
          label: 'Tarifas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Reportes',
        ),
      ],
    );
  }
}