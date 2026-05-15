import 'package:flutter/material.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final TextEditingController buscarController = TextEditingController();

  final List<Map<String, dynamic>> clientes = [
    {
      'inicial': 'C',
      'nombre': 'Carmona Cusquisiban Dany',
      'codigo': 'SK-2034-5',
      'sector': 'Huacariz Bambamarca',
      'consumo': '10 m³',
      'monto': 'S/ 22.20',
      'estado': 'Pendiente',
    },
    {
      'inicial': 'M',
      'nombre': 'María Torres Huamán',
      'codigo': 'SK-2019-12',
      'sector': 'Sector La Molina',
      'consumo': '8 m³',
      'monto': 'S/ 21.20',
      'estado': 'Pagado',
    },
    {
      'inicial': 'J',
      'nombre': 'Juan Pérez Silva',
      'codigo': 'SK-2040-09',
      'sector': 'Huacariz Centro',
      'consumo': '19 m³',
      'monto': 'S/ 82.20',
      'estado': 'Vencido',
    },
  ];

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  void abrirModalRegistrarCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar cliente',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Formulario visual para registrar un cliente y su suministro.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _InputField(
                  label: 'DNI',
                  hint: 'Ej. 12345678',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Nombres y apellidos',
                  hint: 'Ej. Dany Carmona',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Código de suministro',
                  hint: 'Ej. SK-2034-5',
                  icon: Icons.confirmation_number_outlined,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Dirección / sector',
                  hint: 'Ej. Huacariz Bambamarca',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente registrado de forma visual.'),
                          backgroundColor: Color(0xFF1F8F4D),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Guardar cliente',
                      style: TextStyle(fontWeight: FontWeight.w900),
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
  }

  List<Map<String, dynamic>> get clientesFiltrados {
    final texto = buscarController.text.trim().toLowerCase();

    if (texto.isEmpty) return clientes;

    return clientes.where((cliente) {
      final nombre = cliente['nombre'].toString().toLowerCase();
      final codigo = cliente['codigo'].toString().toLowerCase();
      final sector = cliente['sector'].toString().toLowerCase();

      return nombre.contains(texto) ||
          codigo.contains(texto) ||
          sector.contains(texto);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          }

          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/admin-tarifas');
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
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildActionButtons(),
              const SizedBox(height: 18),
              _buildClientesList(),
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
                'Clientes y suministros',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Clientes',
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
            onPressed: abrirModalRegistrarCliente,
            icon: const Icon(
              Icons.add_rounded,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: buscarController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Buscar por código, cliente o sector',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2EDF3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2EDF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: secondary, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EDF3)),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: abrirModalRegistrarCliente,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Registrar cliente',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edición masiva disponible luego con backend.'),
                  backgroundColor: secondary,
                ),
              );
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text(
              'Gestionar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: Color(0xFFE2EDF3)),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientesList() {
    final lista = clientesFiltrados;

    if (lista.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: secondary,
            ),
            SizedBox(height: 12),
            Text(
              'No se encontraron clientes',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: lista.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final cliente = lista[index];

        return _ClienteCard(
          inicial: cliente['inicial'],
          nombre: cliente['nombre'],
          codigo: cliente['codigo'],
          sector: cliente['sector'],
          consumo: cliente['consumo'],
          monto: cliente['monto'],
          estado: cliente['estado'],
        );
      },
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final String inicial;
  final String nombre;
  final String codigo;
  final String sector;
  final String consumo;
  final String monto;
  final String estado;

  const _ClienteCard({
    required this.inicial,
    required this.nombre,
    required this.codigo,
    required this.sector,
    required this.consumo,
    required this.monto,
    required this.estado,
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EDF3)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                    inicial,
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
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$codigo · $sector',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Consumo del mes',
                  value: consumo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Monto total',
                  value: monto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final montoLimpio = monto
                        .replaceAll('S/', '')
                        .replaceAll(' ', '')
                        .replaceAll(',', '.');

                    final total = double.tryParse(montoLimpio) ?? 0.0;

                    final consumoLimpio = consumo
                        .replaceAll('m³', '')
                        .replaceAll(' ', '');

                    final consumoNumero = int.tryParse(consumoLimpio) ?? 0;

                    Navigator.pushNamed(
                      context,
                      '/recibo-detalle',
                      arguments: {
                        'id': 1,
                        'codigo': 'REC-0001',
                        'numero': 'N° R-2026-0714',
                        'cliente': nombre,
                        'suministro': codigo,
                        'sector': sector,
                        'periodo': 'Julio 2026',
                        'consumo': consumoNumero,
                        'total': total,
                        'vencimiento': '17/07/2026',
                        'estado': estado,
                        'origen': 'admin',
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: Color(0xFFE2EDF3)),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Ver detalle',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Editar cliente: $nombre'),
                        backgroundColor: secondary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Editar cliente',
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
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

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    if (estado == 'Pagado') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (estado == 'Vencido') {
      bg = const Color(0xFFFFECEC);
      text = const Color(0xFFD93025);
    } else {
      bg = const Color(0xFFFFF3DF);
      text = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF4F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
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