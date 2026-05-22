import 'package:flutter/material.dart';
import '../../core/services/recibo_service.dart';
import '../../core/services/pago_service.dart';

class PagoCipPage extends StatefulWidget {
  const PagoCipPage({super.key});

  @override
  State<PagoCipPage> createState() => _PagoCipPageState();
}

class _PagoCipPageState extends State<PagoCipPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final PagoService pagoService = PagoService();
  final ReciboService reciboService = ReciboService();
  final TextEditingController codigoOperacionController =
      TextEditingController();

  bool cargando = false;
  String metodoPago = 'EFECTIVO';

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

    return {};
  }

  int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
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
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    );
  }

Future<void> registrarPago(Map<String, dynamic> recibo) async {
  final idRecibo = _id(recibo);

  if (idRecibo <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se encontró el ID del recibo.'),
        backgroundColor: Color(0xFFD93025),
      ),
    );
    return;
  }

  setState(() {
    cargando = true;
  });

  try {
    // Verifica que el recibo realmente pertenezca al cliente logueado.
    final reciboCliente = await reciboService.obtenerMiReciboPorId(idRecibo);

    if (reciboCliente == null) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este recibo no pertenece al cliente autenticado. Cierra sesión e ingresa con el usuario correcto.',
          ),
          backgroundColor: Color(0xFFD93025),
        ),
      );
      return;
    }

    if (_estado(reciboCliente).toUpperCase() == 'PAGADO') {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este recibo ya se encuentra pagado.'),
          backgroundColor: Color(0xFF1F8F4D),
        ),
      );
      return;
    }

    final codigoOperacion = codigoOperacionController.text.trim().isEmpty
        ? 'APP-${DateTime.now().millisecondsSinceEpoch}'
        : codigoOperacionController.text.trim();

    await pagoService.pagarMiRecibo(
      idRecibo: idRecibo,
      metodoPago: metodoPago,
      codigoOperacion: codigoOperacion,
    );

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago registrado correctamente.'),
        backgroundColor: Color(0xFF1F8F4D),
      ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al registrar pago: $e'),
        backgroundColor: const Color(0xFFD93025),
      ),
    );
  }
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
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildResumenPago(recibo),
              const SizedBox(height: 18),
              _buildMetodoPago(),
              const SizedBox(height: 18),
              _buildOperacionInput(),
              const SizedBox(height: 22),
              _buildBotonPagar(recibo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        const Expanded(
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

  Widget _buildResumenPago(Map<String, dynamic> recibo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del recibo',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _codigoRecibo(recibo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suministro: ${_codigoSuministro(recibo)}',
            style: const TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Periodo: ${_periodo(recibo)}',
            style: const TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total a pagar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'S/ ${_total(recibo).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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

  Widget _buildMetodoPago() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Método de pago',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _MetodoPagoTile(
            title: 'Efectivo',
            subtitle: 'Pago registrado como efectivo',
            icon: Icons.payments_rounded,
            value: 'EFECTIVO',
            groupValue: metodoPago,
            onChanged: (value) {
              setState(() {
                metodoPago = value;
              });
            },
          ),
          _MetodoPagoTile(
            title: 'Yape / Plin',
            subtitle: 'Pago con código de operación',
            icon: Icons.phone_android_rounded,
            value: 'YAPE',
            groupValue: metodoPago,
            onChanged: (value) {
              setState(() {
                metodoPago = value;
              });
            },
          ),
          _MetodoPagoTile(
            title: 'Transferencia',
            subtitle: 'Pago mediante operación bancaria',
            icon: Icons.account_balance_rounded,
            value: 'TRANSFERENCIA',
            groupValue: metodoPago,
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

  Widget _buildOperacionInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de operación',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Si el pago es en efectivo, este campo puede quedar vacío.',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: codigoOperacionController,
            decoration: InputDecoration(
              hintText: 'Ej. 842913 / APP automático',
              filled: true,
              fillColor: const Color(0xFFF8FBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD8E6EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD8E6EE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: secondary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPagar(Map<String, dynamic> recibo) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : () => registrarPago(recibo),
        icon: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Icon(Icons.check_circle_rounded),
        label: Text(
          cargando ? 'Registrando pago...' : 'Confirmar pago',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

class _MetodoPagoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _MetodoPagoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () {
        onChanged(value);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F7FB) : const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1DA1C2) : const Color(0xFFE2EDF3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF1DA1C2)
                  : const Color(0xFF7B8794),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF0F3D57)
                          : const Color(0xFF52616B),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF1DA1C2),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}