import 'package:flutter/material.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class LectorHomePage extends StatefulWidget {
  const LectorHomePage({super.key});

  @override
  State<LectorHomePage> createState() => _LectorHomePageState();
}

class _LectorHomePageState extends State<LectorHomePage> {
  final SecureStorageService storageService = SecureStorageService();

  String codigoUsuario = 'Lecturador';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await storageService.getUserName();

    if (!mounted) return;

    setState(() {
      codigoUsuario = usuario?.trim().isNotEmpty == true
          ? usuario!.trim()
          : 'Lecturador';
    });
  }

  void _irInicio() {
    Navigator.pushReplacementNamed(context, '/lector-home');
  }

  void _irBuscar() {
    Navigator.pushNamed(context, '/buscar-suministro');
  }

  void _irQr() {
    Navigator.pushNamed(context, '/qr-scanner');
  }

  void _irHistorial() {
    Navigator.pushNamed(context, '/historial-lecturas');
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '¿Deseas cerrar la sesión del lecturador?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: JassColors.danger,
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

  void _goBottomLector(int index) {
    if (index == 0) return;
    if (index == 1) _irBuscar();
    if (index == 2) _irQr();
    if (index == 3) _irHistorial();
  }

  void _abrirMenuLector() {
    showLectorQuickMenu(
      context: context,
      onRefresh: _cargarUsuario,
      onLogout: _cerrarSesion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro ? JassColors.darkBackground : JassColors.background,
      extendBody: true,
      bottomNavigationBar: LectorBottomNav(
        currentIndex: 0,
        onTap: _goBottomLector,
        onPlus: _abrirMenuLector,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(oscuro),
              const SizedBox(height: 22),
              _buildMainCard(),
              const SizedBox(height: 18),
              _buildAccessGrid(oscuro),
              const SizedBox(height: 18),
              _buildRoleCard(oscuro),
              const SizedBox(height: 18),
              _buildInfoCard(oscuro),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool oscuro) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: JassColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JASS Huacariz',
                style: TextStyle(
                  color: oscuro ? Colors.white : JassColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Panel móvil del lecturador',
                style: TextStyle(
                  color: oscuro
                      ? JassColors.darkMuted
                      : JassColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: oscuro ? JassColors.darkCard : JassColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: oscuro ? JassColors.darkBorder : JassColors.border,
            ),
          ),
          child: IconButton(
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
            icon: Icon(
              Icons.logout_rounded,
              color: oscuro ? Colors.white : JassColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            JassColors.primary,
            JassColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2607384A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'REGISTRO DE CAMPO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Hola, $codigoUsuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca un suministro, verifica sus datos y registra la lectura mensual del medidor.',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _irBuscar,
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                'Buscar suministro',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: JassColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _irQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                'Escanear código QR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
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

  Widget _buildAccessGrid(bool oscuro) {
    return Row(
      children: [
        Expanded(
          child: _AccessCard(
            icon: Icons.search_rounded,
            title: 'Buscar',
            subtitle: 'Ingreso manual',
            oscuro: oscuro,
            onTap: _irBuscar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccessCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Escanear',
            subtitle: 'Código QR',
            oscuro: oscuro,
            onTap: _irQr,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccessCard(
            icon: Icons.history_rounded,
            title: 'Historial',
            subtitle: 'Mis lecturas',
            oscuro: oscuro,
            onTap: _irHistorial,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: oscuro
                  ? const Color(0xFF162432)
                  : const Color(0xFFE8F7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: JassColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rol activo',
                  style: TextStyle(
                    color: oscuro
                        ? JassColors.darkMuted
                        : JassColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lecturador',
                  style: TextStyle(
                    color: oscuro ? Colors.white : JassColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'ACTIVO',
              style: TextStyle(
                color: JassColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: JassColors.secondary,
              ),
              const SizedBox(width: 9),
              Text(
                'Flujo recomendado',
                style: TextStyle(
                  color: oscuro ? Colors.white : JassColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _StepLine(
            number: '1',
            text: 'Ingresa o escanea el código del suministro.',
            oscuro: oscuro,
          ),
          _StepLine(
            number: '2',
            text: 'Verifica el cliente y la lectura anterior.',
            oscuro: oscuro,
          ),
          _StepLine(
            number: '3',
            text: 'Selecciona el año, mes y registra la lectura actual.',
            oscuro: oscuro,
          ),
          _StepLine(
            number: '4',
            text: 'Confirma el recibo generado por el sistema.',
            oscuro: oscuro,
          ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool oscuro;
  final VoidCallback onTap;

  const _AccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: oscuro ? JassColors.darkCard : JassColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: oscuro ? JassColors.darkBorder : JassColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: JassColors.secondary,
                size: 29,
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: oscuro ? Colors.white : JassColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: oscuro
                      ? JassColors.darkMuted
                      : JassColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final String number;
  final String text;
  final bool oscuro;

  const _StepLine({
    required this.number,
    required this.text,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: JassColors.secondary,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: oscuro
                    ? JassColors.darkMuted
                    : JassColors.muted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
