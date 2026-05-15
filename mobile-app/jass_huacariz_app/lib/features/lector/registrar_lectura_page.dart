import 'package:flutter/material.dart';

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

  final TextEditingController lecturaActualController =
      TextEditingController(text: '1030');

  double lecturaAnterior = 1020;
  double lecturaActual = 1030;
  double consumo = 10;

  double volumenAgua = 20.00;
  double pagoLecturador = 2.00;
  double otrosCargos = 0.20;
  double mora = 0.00;
  double total = 22.20;

  Map<String, dynamic> _getSuministro(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    return {
      'codigo': 'SK-2034-5',
      'cliente': 'Carmona Cusquisiban Dany',
      'sector': 'Huacariz Bambamarca',
      'direccion': 'Av. Principal 123',
      'lecturaAnterior': 1020.0,
      'estado': 'Pendiente',
    };
  }

  @override
  void dispose() {
    lecturaActualController.dispose();
    super.dispose();
  }

  void calcularRecibo() {
    final nuevaLectura = double.tryParse(
          lecturaActualController.text.trim().replaceAll(',', '.'),
        ) ??
        lecturaAnterior;

    if (nuevaLectura < lecturaAnterior) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La lectura actual no puede ser menor a la anterior.'),
          backgroundColor: Color(0xFFD93025),
        ),
      );
      return;
    }

    setState(() {
      lecturaActual = nuevaLectura;
      consumo = lecturaActual - lecturaAnterior;

      volumenAgua = consumo * 2.00;
      pagoLecturador = 2.00;
      otrosCargos = 0.20;
      mora = 0.00;
      total = volumenAgua + pagoLecturador + otrosCargos + mora;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cálculo realizado correctamente.'),
        backgroundColor: secondary,
      ),
    );
  }

  void generarRecibo(Map<String, dynamic> suministro) {
    calcularRecibo();

    final reciboGenerado = {
      'id': 1,
      'codigo': 'REC-0001',
      'numero': 'N° R-2026-0714',
      'cliente': suministro['cliente'],
      'suministro': suministro['codigo'],
      'sector': suministro['sector'],
      'periodo': 'Julio 2026',
      'consumo': consumo.toInt(),
      'total': total,
      'vencimiento': '17/07/2026',
      'estado': 'Pendiente',
      'origen': 'admin',
    };

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Recibo generado',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Se generó el recibo para ${suministro['cliente']} por S/ ${total.toStringAsFixed(2)}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/recibo-detalle',
                  arguments: reciboGenerado,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver recibo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suministro = _getSuministro(context);

    lecturaAnterior = suministro['lecturaAnterior'] is num
        ? (suministro['lecturaAnterior'] as num).toDouble()
        : 1020.0;

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _LectorBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/lector-home');
          }

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/buscar-suministro');
          }

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/historial-lecturas');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildFormCard(suministro),
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
                'Registro de lectura',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Nueva lectura',
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

  Widget _buildFormCard(Map<String, dynamic> suministro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientHeader(suministro),
          const SizedBox(height: 16),
          _buildInfoGrid(),
          const SizedBox(height: 16),
          const Text(
            'Lectura actual',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: lecturaActualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
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
            style: const TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _buildCalculationCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: calcularRecibo,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FAFD),
                    foregroundColor: primary,
                    side: const BorderSide(color: Color(0xFFE2EDF3)),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Calcular',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    generarRecibo(suministro);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Generar recibo',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(Map<String, dynamic> suministro) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7FB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              suministro['cliente'].toString().substring(0, 1),
              style: const TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suministro['cliente'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${suministro['codigo']} · ${suministro['sector']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: _InfoBox(
                label: 'Mes facturado',
                value: 'JULIO 2026',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _InfoBox(
                label: 'Fecha emisión',
                value: '2/7/2026',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _InfoBox(
                label: 'Vencimiento',
                value: '17/7/2026',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoBox(
                label: 'Lectura anterior',
                value: lecturaAnterior.toStringAsFixed(0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalculationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cálculo automático del recibo',
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _CalcRow(label: 'Consumo del mes', value: '${consumo.toStringAsFixed(0)} m³'),
          _CalcRow(label: 'Volumen de agua potable', value: 'S/ ${volumenAgua.toStringAsFixed(2)}'),
          _CalcRow(label: 'Pago al lecturador', value: 'S/ ${pagoLecturador.toStringAsFixed(2)}'),
          _CalcRow(label: 'Otros cargos', value: 'S/ ${otrosCargos.toStringAsFixed(2)}'),
          _CalcRow(label: 'Mora', value: 'S/ ${mora.toStringAsFixed(2)}'),
          _CalcRow(
            label: 'Total a pagar',
            value: 'S/ ${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _CalcRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? 12 : 9,
      ),
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
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF0F3D57)
                    : const Color(0xFF7B8794),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0F3D57),
              fontSize: isTotal ? 15 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LectorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _LectorBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 76,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2_rounded),
          label: 'QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          selectedIcon: Icon(Icons.water_drop_rounded),
          label: 'Lectura',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'Historial',
        ),
      ],
    );
  }
}