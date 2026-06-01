import 'package:flutter/material.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../core/storage/secure_storage_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);
  static const Color muted = Color(0xFF7B8794);

  final ClientePortalService clientePortalService = ClientePortalService();
  final SecureStorageService storageService = SecureStorageService();

  Map<String, dynamic>? perfil;
  List<Map<String, dynamic>> suministros = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final perfilData = await clientePortalService.obtenerMiPerfil();
      final suministrosData =
          await clientePortalService.listarMisSuministros();

      if (!mounted) return;

      setState(() {
        perfil = perfilData;
        suministros = suministrosData;
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

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String get nombreCompleto {
    final nombres = _texto(perfil?['nombres'], '');
    final apellidos = _texto(perfil?['apellidos'], '');

    final completo = '$nombres $apellidos'.trim();

    return completo.isEmpty ? 'Cliente del servicio' : completo;
  }

  String get codigoUsuario {
    return _texto(perfil?['codigoUsuario']);
  }

  String get dni {
    return _texto(perfil?['dni']);
  }

  String get telefono {
    return _texto(perfil?['telefono'] ?? perfil?['celular']);
  }

  String get correo {
    return _texto(perfil?['correo']);
  }

  bool get estado {
    final value = perfil?['estado'];

    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

Future<void> cerrarSesion() async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          '¿Deseas cerrar tu sesión actual?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  await storageService.clearSession();

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (route) => false,
  );
}

  void irCambiarPassword() {
    Navigator.pushNamed(context, '/cambiar-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: _ClienteBottomNav(
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
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) ...[
                  _buildProfileCard(),
                  const SizedBox(height: 18),
                  _buildActions(),
                  const SizedBox(height: 18),
                  _buildSuministros(),
                ],
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
                'Portal cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mi perfil',
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
            onPressed: cargarDatos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD93025),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD93025),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: cargarDatos,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
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
            color: primary.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Código: $codigoUsuario',
            style: const TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: estado
                  ? const Color(0xFFEAF8EF)
                  : const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              estado ? 'ACTIVO' : 'INACTIVO',
              style: TextStyle(
                color: estado
                    ? const Color(0xFF1F8F4D)
                    : const Color(0xFFD93025),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InfoProfileRow(
            icon: Icons.badge_rounded,
            label: 'DNI',
            value: dni,
          ),
          _InfoProfileRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: telefono,
          ),
          _InfoProfileRow(
            icon: Icons.email_rounded,
            label: 'Correo',
            value: correo,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: irCambiarPassword,
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text(
              'Cambiar contraseña',
              style: TextStyle(fontWeight: FontWeight.w900),
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
        ),
        const SizedBox(height: 12),
        SizedBox(
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
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFFFD1D1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuministros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis suministros',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (suministros.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No tienes suministros registrados.',
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: suministros.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final suministro = suministros[index];

                return _SuministroCard(
                  codigo: _texto(suministro['codigoSuministro']),
                  sector: _texto(suministro['nombreSector']),
                  direccion: _texto(suministro['direccionSuministro']),
                  referencia: _texto(suministro['referencia']),
                  alias: _texto(suministro['aliasSuministro']),
                  lecturaInicial: _texto(suministro['lecturaInicial']),
                  activo: suministro['estado'] == true ||
                      suministro['estado'].toString().toLowerCase() == 'true',
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
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
              style: const TextStyle(
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

class _SuministroCard extends StatelessWidget {
  final String codigo;
  final String sector;
  final String direccion;
  final String referencia;
  final String alias;
  final String lecturaInicial;
  final bool activo;

  const _SuministroCard({
    required this.codigo,
    required this.sector,
    required this.direccion,
    required this.referencia,
    required this.alias,
    required this.lecturaInicial,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color muted = Color(0xFF7B8794);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF1DA1C2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  codigo,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFFEAF8EF)
                      : const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: activo
                        ? const Color(0xFF1F8F4D)
                        : const Color(0xFFD93025),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SuministroInfo(icon: Icons.map_rounded, text: sector),
          _SuministroInfo(icon: Icons.place_rounded, text: direccion),
          _SuministroInfo(icon: Icons.bookmark_rounded, text: alias),
          _SuministroInfo(icon: Icons.info_outline_rounded, text: referencia),
          _SuministroInfo(
            icon: Icons.speed_rounded,
            text: 'Lectura inicial: $lecturaInicial',
          ),
        ],
      ),
    );
  }
}

class _SuministroInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SuministroInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const Color muted = Color(0xFF7B8794);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ClienteBottomNav({
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
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Recibos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}