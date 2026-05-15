import 'package:flutter/material.dart';

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

  bool editando = false;

  final List<Map<String, dynamic>> tarifas = [
    {
      'nombre': 'Mantenimiento',
      'valor': 3.00,
    },
    {
      'nombre': 'De 0 a 12 m³',
      'valor': 2.00,
    },
    {
      'nombre': 'Mayor a 12 hasta 15 m³',
      'valor': 3.00,
    },
    {
      'nombre': 'Mayor a 15 y hasta 20 m³',
      'valor': 4.00,
    },
    {
      'nombre': 'Mayor a 20 m³',
      'valor': 5.00,
    },
    {
      'nombre': 'Pago al lecturador',
      'valor': 2.00,
    },
    {
      'nombre': 'Otros cargos',
      'valor': 0.20,
    },
    {
      'nombre': 'Mora por vencimiento',
      'valor': 1.50,
    },
  ];

  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = tarifas.map((tarifa) {
      return TextEditingController(
        text: (tarifa['valor'] as double).toStringAsFixed(2),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void activarEdicion() {
    setState(() {
      editando = true;
    });
  }

  void guardarCambios() {
    for (int i = 0; i < tarifas.length; i++) {
      final value = double.tryParse(
            controllers[i].text.trim().replaceAll(',', '.'),
          ) ??
          tarifas[i]['valor'];

      tarifas[i]['valor'] = value;
      controllers[i].text = value.toStringAsFixed(2);
    }

    setState(() {
      editando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarifas actualizadas correctamente.'),
        backgroundColor: Color(0xFF1F8F4D),
      ),
    );
  }

  void cancelarEdicion() {
    for (int i = 0; i < tarifas.length; i++) {
      controllers[i].text = (tarifas[i]['valor'] as double).toStringAsFixed(2);
    }

    setState(() {
      editando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 2,
        onTap: (index) {
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
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTarifasCard(),
            ],
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
                  fontSize: 13,
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
            onPressed: editando ? cancelarEdicion : activarEdicion,
            icon: Icon(
              editando ? Icons.close_rounded : Icons.edit_rounded,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarifasCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
        children: [
          ListView.separated(
            itemCount: tarifas.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const Divider(
              height: 28,
              color: Color(0xFFE2EDF3),
            ),
            itemBuilder: (context, index) {
              final tarifa = tarifas[index];

              return _TarifaRow(
                nombre: tarifa['nombre'].toString(),
                valor: tarifa['valor'] as double,
                controller: controllers[index],
                editando: editando,
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: editando ? cancelarEdicion : activarEdicion,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FAFD),
                    foregroundColor: primary,
                    side: const BorderSide(
                      color: Color(0xFFE2EDF3),
                    ),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    editando ? 'Cancelar' : 'Editar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: guardarCambios,
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
                    'Guardar cambios',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarifaRow extends StatelessWidget {
  final String nombre;
  final double valor;
  final TextEditingController controller;
  final bool editando;

  const _TarifaRow({
    required this.nombre,
    required this.valor,
    required this.controller,
    required this.editando,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);

    return Row(
      children: [
        Expanded(
          child: Text(
            nombre,
            style: const TextStyle(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 96,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD8E6EE),
            ),
          ),
          child: editando
              ? TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: 'S/ ',
                    prefixStyle: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'S/ ${valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
      ],
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
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.attach_money_outlined),
          selectedIcon: Icon(Icons.attach_money_rounded),
          label: 'Tarifas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reportes',
        ),
      ],
    );
  }
}