import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/pago_service.dart';
import '../../core/services/recibo_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class PagoCipPage extends StatefulWidget {
  const PagoCipPage({super.key});

  @override
  State<PagoCipPage> createState() => _PagoCipPageState();
}

class _PagoCipPageState extends State<PagoCipPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;
  static const Color success = JassColors.success;
  static const Color warning = JassColors.warning;

  final PagoService pagoService = PagoService();
  final ReciboService reciboService = ReciboService();
  final TextEditingController codigoOperacionController =
      TextEditingController();

  bool cargando = false;
  String metodoPago = 'YAPE';

  @override
  void dispose() {
    codigoOperacionController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getRecibo(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    if (args is Map) {
      return Map<String, dynamic>.from(args);
    }

    return {};
  }

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;
    if (value is num) return value.toInt();

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
          recibo['codigoSuministroRecibo'] ??
          recibo['numeroSuministro'] ??
          recibo['suministro'],
      'SIN-SUMINISTRO',
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

  double _total(Map<String, dynamic> recibo) {
    return _numero(
      recibo['total'] ??
          recibo['montoTotal'] ??
          recibo['importeTotal'] ??
          recibo['totalPagar'] ??
          0,
    );
  }

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  bool _puedePagar(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

 void _mostrarMensaje(
  String mensaje, {
  Color? color,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor:
          color ?? Theme.of(context).colorScheme.primary,
    ),
  );
}

  Future<Map<String, dynamic>?> _buscarReciboDelCliente(int idRecibo) async {
    final recibos = await reciboService.listarMisRecibos();

    try {
      return recibos.firstWhere((recibo) => _id(recibo) == idRecibo);
    } catch (_) {
      return null;
    }
  }

  Future<void> registrarPago() async {
    final recibo = _getRecibo(context);
    final idRecibo = _id(recibo);
    final codigoOperacion = codigoOperacionController.text.trim();

    if (idRecibo <= 0) {
      _mostrarMensaje(
        'No se encontró el recibo para pagar.',
        color: danger,
      );
      return;
    }

    if (!_puedePagar(recibo)) {
      _mostrarMensaje(
        'Este recibo no está pendiente de pago.',
        color: warning,
      );
      return;
    }

    if (metodoPago != 'EFECTIVO' && codigoOperacion.isEmpty) {
      _mostrarMensaje(
        'Ingresa el código de operación.',
        color: warning,
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final reciboValidado = await _buscarReciboDelCliente(idRecibo);

      if (reciboValidado == null) {
        if (!mounted) return;

        setState(() {
          cargando = false;
        });

        _mostrarMensaje(
          'Este recibo no pertenece a tus suministros.',
          color: danger,
        );
        return;
      }

      await pagoService.pagarMiRecibo(
        idRecibo: idRecibo,
        metodoPago: metodoPago,
        codigoOperacion: codigoOperacion,
      );

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      _mostrarMensaje(
        'Pago registrado correctamente.',
        color: success,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/recibos',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      _mostrarMensaje(
        e.toString().replaceFirst('Exception: ', ''),
        color: danger,
      );
    }
  }

  void _irHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _irRecibos() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void _irPerfil() {
    Navigator.pushReplacementNamed(context, '/perfil');
  }

  void _irCambiarPassword() {
    Navigator.pushNamed(context, '/cambiar-password');
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irRecibos();
    }
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    if (index == 0) {
      _irHome();
    }

    if (index == 1) {
      _irRecibos();
    }

    if (index == 2) return;

    if (index == 3) {
      _irPerfil();
    }
  }

  void _abrirMenuCliente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.jassSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: context.jassBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: [
                        ClienteMenuTile(
                          icon: Icons.home_rounded,
                          label: 'Inicio',
                          onTap: () {
                            Navigator.pop(context);
                            _irHome();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Recibos',
                          onTap: () {
                            Navigator.pop(context);
                            _irRecibos();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.person_rounded,
                          label: 'Perfil',
                          onTap: () {
                            Navigator.pop(context);
                            _irPerfil();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.lock_reset_rounded,
                          label: 'Clave',
                          onTap: () {
                            Navigator.pop(context);
                            _irCambiarPassword();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.arrow_back_rounded,
                          label: 'Volver',
                          onTap: () {
                            Navigator.pop(context);
                            _volver();
                          },
                        ),
                        ClienteThemeTile(
                          onAfterChange: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: JassColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibo = _getRecibo(context);

    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: ClienteBottomNav(
        currentIndex: 2,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 18),
              _buildResumenRecibo(recibo),
              SizedBox(height: 18),
              _buildMetodoPago(),
              SizedBox(height: 18),
              _buildCodigoOperacion(),
              SizedBox(height: 22),
              _buildBotonPagar(),
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
            boxShadow: [
              BoxShadow(
                color: JassColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: cargando ? null : _volver,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pagar recibo',
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

  Widget _buildResumenRecibo(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    final puedePagar = _puedePagar(recibo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: JassColors.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumen del pago',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _ResumenLine(
            label: 'Recibo',
            value: _codigoRecibo(recibo),
          ),
          _ResumenLine(
            label: 'Suministro',
            value: _codigoSuministro(recibo),
          ),
          _ResumenLine(
            label: 'Periodo',
            value: _periodo(recibo),
          ),
          _ResumenLine(
            label: 'Estado',
            value: estado,
          ),
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total a pagar',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'S/ ${_total(recibo).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (!puedePagar) ...[
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Este recibo no está pendiente de pago.',
                style: TextStyle(
                  color: warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetodoPago() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona método de pago',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _MetodoPagoTile(
            value: 'YAPE',
            selectedValue: metodoPago,
            icon: Icons.phone_android_rounded,
            title: 'Yape',
            subtitle: 'Pago por aplicativo móvil',
            onChanged: (value) {
              setState(() {
                metodoPago = value;
              });
            },
          ),
          SizedBox(height: 10),
          _MetodoPagoTile(
            value: 'PLIN',
            selectedValue: metodoPago,
            icon: Icons.mobile_friendly_rounded,
            title: 'Plin',
            subtitle: 'Transferencia por aplicativo',
            onChanged: (value) {
              setState(() {
                metodoPago = value;
              });
            },
          ),
          SizedBox(height: 10),
          _MetodoPagoTile(
            value: 'TRANSFERENCIA',
            selectedValue: metodoPago,
            icon: Icons.account_balance_rounded,
            title: 'Transferencia',
            subtitle: 'Pago desde banco o agente',
            onChanged: (value) {
              setState(() {
                metodoPago = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodigoOperacion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código de operación',
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa el código que aparece en tu comprobante de pago.',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14),
          TextField(
            controller: codigoOperacionController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ejemplo: 123456789',
              prefixIcon: Icon(Icons.confirmation_number_rounded),
              filled: true,
              fillColor: context.jassSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: context.jassBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: context.jassBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: secondary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPagar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : registrarPago,
        icon: cargando
            ? SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.check_circle_rounded),
        label: Text(
          cargando ? 'Registrando pago...' : 'Registrar pago',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: secondary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ResumenLine extends StatelessWidget {
  final String label;
  final String value;

  const _ResumenLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFFE7F8FF),
                fontSize: 13,
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

class _MetodoPagoTile extends StatelessWidget {
  final String value;
  final String selectedValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  const _MetodoPagoTile({
    required this.value,
    required this.selectedValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? context.jassSelectedSurface : context.jassSurfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1DA1C2) : context.jassBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF1DA1C2)
                  : const Color(0xFF7B8794),
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.jassTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.jassTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              activeColor: const Color(0xFF1DA1C2),
              onChanged: (newValue) {
                if (newValue == null) return;
                onChanged(newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}
