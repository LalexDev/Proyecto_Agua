import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textMuted = Color(0xFF7B8794);

  final TextEditingController actualController = TextEditingController();
  final TextEditingController nuevaController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  bool verActual = false;
  bool verNueva = false;
  bool verConfirmar = false;
  bool cargando = false;

  @override
  void dispose() {
    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void cambiarPassword() {
    final actual = actualController.text.trim();
    final nueva = nuevaController.text.trim();
    final confirmar = confirmarController.text.trim();

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      mostrarMensaje(
        'Completa todos los campos.',
        esError: true,
      );
      return;
    }

    if (nueva.length < 6) {
      mostrarMensaje(
        'La nueva contraseña debe tener mínimo 6 caracteres.',
        esError: true,
      );
      return;
    }

    if (nueva != confirmar) {
      mostrarMensaje(
        'La nueva contraseña y la confirmación no coinciden.',
        esError: true,
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() {
        cargando = false;
      });

      actualController.clear();
      nuevaController.clear();
      confirmarController.clear();

      mostrarMensaje(
        'Contraseña actualizada correctamente.',
        esError: false,
      );
    });
  }

  void mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError
            ? const Color(0xFFD93025)
            : const Color(0xFF1F8F4D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildFormCard(),
              const SizedBox(height: 18),
              _buildTipsCard(),
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
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguridad de cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Actualiza tu contraseña para mantener protegida tu información.',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actualizar contraseña',
            style: TextStyle(
              color: primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa tu contraseña actual y define una nueva clave.',
            style: TextStyle(
              color: textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),

          _PasswordField(
            label: 'Contraseña actual',
            hint: 'Ingresa tu contraseña actual',
            controller: actualController,
            visible: verActual,
            onToggle: () {
              setState(() {
                verActual = !verActual;
              });
            },
          ),

          const SizedBox(height: 16),

          _PasswordField(
            label: 'Nueva contraseña',
            hint: 'Mínimo 6 caracteres',
            controller: nuevaController,
            visible: verNueva,
            onToggle: () {
              setState(() {
                verNueva = !verNueva;
              });
            },
          ),

          const SizedBox(height: 16),

          _PasswordField(
            label: 'Confirmar contraseña',
            hint: 'Repite la nueva contraseña',
            controller: confirmarController,
            visible: verConfirmar,
            onToggle: () {
              setState(() {
                verConfirmar = !verConfirmar;
              });
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: cargando ? null : cambiarPassword,
              icon: cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                cargando ? 'Actualizando...' : 'Guardar contraseña',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
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
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFCFEFF7),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                color: secondary,
              ),
              SizedBox(width: 10),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _TipItem(text: 'Usa una contraseña de mínimo 6 caracteres.'),
          _TipItem(text: 'No compartas tu clave con otras personas.'),
          _TipItem(text: 'Evita usar tu DNI o fecha de nacimiento como clave.'),
          _TipItem(text: 'Cambia tu contraseña periódicamente.'),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color background = Color(0xFFF4F8FB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !visible,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            filled: true,
            fillColor: background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: secondary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color textMuted = Color(0xFF52616B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: primary,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textMuted,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}