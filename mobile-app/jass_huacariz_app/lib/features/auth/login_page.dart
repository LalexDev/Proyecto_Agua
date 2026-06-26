import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/auth_service.dart';
import '../../core/storage/secure_storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;

  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();
  final SecureStorageService storageService = SecureStorageService();

  bool mostrarPassword = false;
  bool cargando = false;

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final usuario = usuarioController.text.trim();
    final password = passwordController.text.trim();

    if (usuario.isEmpty || password.isEmpty) {
      _mostrarMensaje('Ingresa usuario y contraseña.', esError: true);
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await authService.login(
        codigoUsuario: usuario,
        password: password,
      );

      final role = await storageService.getUserRole();
      final rol = role?.toUpperCase().trim() ?? '';

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      if (rol.contains('ADMIN')) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        return;
      }

      if (rol.contains('LECTURADOR') || rol.contains('LECTOR')) {
        Navigator.pushReplacementNamed(context, '/lector-home');
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      _mostrarMensaje(
        'Error al iniciar sesión: ${e.toString().replaceFirst('Exception: ', '')}',
        esError: true,
      );
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login-fondo-huacariz.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: JassColors.primary);
              },
            ),
          ),
          // cambio de fondo a un degradado para mejorar contraste y visibilidad del contenido
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF061A24).withValues(alpha: 0.48),
                    const Color(0xFF0F3D57).withValues(alpha: 0.45),
                    const Color(0xFF1DA1C2).withValues(alpha: 0.28),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBrand(),
                  SizedBox(height: 28),
                  _buildHeroText(),
                  SizedBox(height: 26),
                  _buildLoginCard(),
                  SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Proyecto Agua · JASS Huacariz',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrand() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.water_drop_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JASS Huacariz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sistema Administrador de Servicios de Saneamiento',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Servicio público confiable y transparente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Agua que nos une,\ncomunidad que avanza.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 37,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Trabajamos cada día para brindar un servicio de agua potable seguro, sostenible y cercano a las familias de Huacariz.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.water_drop_outlined,
                title: 'Agua segura',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.groups_2_outlined,
                title: 'Gestión',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.eco_outlined,
                title: 'Cuidado',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: context.jassSelectedSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              color: secondary,
              size: 42,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'AGUA POTABLE\nHUACARIZ\nSAN ANTONIO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tu servicio de agua en línea',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),

          _label('Usuario o DNI'),
          SizedBox(height: 8),
          TextField(
            controller: usuarioController,
            enabled: !cargando,
            decoration: _inputDecoration(
              hint: 'Ej. 12345678',
              icon: Icons.person_outline,
            ),
          ),
          SizedBox(height: 14),

          _label('Contraseña'),
          SizedBox(height: 8),
          TextField(
            controller: passwordController,
            enabled: !cargando,
            obscureText: !mostrarPassword,
            onSubmitted: (_) {
              if (!cargando) iniciarSesion();
            },
            decoration: _inputDecoration(
              hint: 'Ingresa tu contraseña',
              icon: Icons.lock_outline,
              suffix: IconButton(
                onPressed: cargando
                    ? null
                    : () {
                        setState(() {
                          mostrarPassword = !mostrarPassword;
                        });
                      },
                icon: Icon(
                  mostrarPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),

          SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: cargando ? null : iniciarSesion,
              icon: cargando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.login_rounded),
              label: Text(
                cargando ? 'Validando datos...' : 'Ingresar al portal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JassColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          SizedBox(height: 18),
          Text(
            '¿Qué deseas hacer hoy?',
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _AccionMiniCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Consultar',
                  subtitle: 'mi recibo',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _AccionMiniCard(
                  icon: Icons.credit_card_outlined,
                  title: 'Pagar',
                  subtitle: 'en línea',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _AccionMiniCard(
                  icon: Icons.report_problem_outlined,
                  title: 'Reportar',
                  subtitle: 'incidencia',
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          Divider(color: context.jassBorder),
          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FooterMini(icon: Icons.access_time, text: 'Atención rápida'),
              _FooterMini(icon: Icons.lock_outline, text: 'Pagos seguros'),
              _FooterMini(icon: Icons.support_agent, text: 'Consulta 24/7'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: context.jassTextMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.jassSurfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.jassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: secondary, width: 1.5),
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _InfoMiniCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AccionMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _LoginPageState.secondary, size: 22),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterMini extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterMini({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: context.jassTextMuted),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.jassTextMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
