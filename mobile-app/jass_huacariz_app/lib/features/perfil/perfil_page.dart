import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  String telefono = '987654321';
  String correo = 'dany@gmail.com';

  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();

  final List<Map<String, dynamic>> suministros = const [
    {
      'alias': 'Casa principal',
      'direccion': 'Av. Principal 123',
      'sector': 'Huacariz',
      'estado': 'Activo',
    },
    {
      'alias': 'Tienda',
      'direccion': 'Av. Principal 125',
      'sector': 'Huacariz',
      'estado': 'Activo',
    },
    {
      'alias': 'Local comercial',
      'direccion': 'Jr. Lima 560',
      'sector': 'Huacariz Alto',
      'estado': 'Activo',
    },
  ];

  @override
  void dispose() {
    telefonoController.dispose();
    correoController.dispose();
    super.dispose();
  }

  void abrirModalEditar() {
    telefonoController.text = telefono;
    correoController.text = correo;

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
                  'Editar datos',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Actualiza tu teléfono y correo de contacto.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        telefono = telefonoController.text.trim();
                        correo = correoController.text.trim();
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos actualizados correctamente.'),
                          backgroundColor: Color(0xFF1F8F4D),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Guardar cambios',
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

  void cerrarSesion() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/recibos');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildPersonalInfo(),
              const SizedBox(height: 18),
              _buildSecurityCard(),
              const SizedBox(height: 18),
              _buildSuministros(),
              const SizedBox(height: 18),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF146C94),
            secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dany Carmona',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cliente JASS Huacariz',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Cuenta activa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _SectionCard(
      title: 'Información personal',
      subtitle: 'Datos principales registrados en el sistema.',
      action: IconButton(
        onPressed: abrirModalEditar,
        icon: const Icon(
          Icons.edit_outlined,
          color: secondary,
        ),
      ),
      child: Column(
        children: [
          const _InfoRow(
            icon: Icons.badge_outlined,
            label: 'DNI',
            value: '12345678',
          ),
          const _InfoRow(
            icon: Icons.person_outline,
            label: 'Nombres',
            value: 'Dany Carmona',
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: telefono,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: correo,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _SectionCard(
      title: 'Seguridad',
      subtitle: 'Administra el acceso a tu cuenta.',
      child: Column(
        children: [
          _OptionTile(
            icon: Icons.lock_outline,
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu clave de acceso.',
            onTap: () {
              Navigator.pushNamed(context, '/cambiar-password');
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.verified_user_outlined,
            title: 'Estado de cuenta',
            subtitle: 'Tu cuenta se encuentra activa.',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSuministros() {
    return _SectionCard(
      title: 'Suministros asociados',
      subtitle: 'Puntos de consumo vinculados a tu usuario.',
      child: ListView.separated(
        itemCount: suministros.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = suministros[index];

          return _SuministroTile(
            alias: item['alias'],
            direccion: item['direccion'],
            sector: item['sector'],
            estado: item['estado'],
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: cerrarSesion,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD93025),
          side: const BorderSide(color: Color(0xFFD93025)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE8EEF3),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EEF3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7FB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuministroTile extends StatelessWidget {
  final String alias;
  final String direccion;
  final String sector;
  final String estado;

  const _SuministroTile({
    required this.alias,
    required this.direccion,
    required this.sector,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color textMuted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.water_drop,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alias,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  direccion,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sector,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              estado,
              style: const TextStyle(
                color: Color(0xFF1F8F4D),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}