import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/storage/secure_storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();
  final SecureStorageService storageService = SecureStorageService();

  bool mostrarPassword = false;
  bool cargando = false;

Future<void> iniciarSesion() async {
  final usuario = usuarioController.text.trim();
  final password = passwordController.text.trim();

  if (usuario.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingresa usuario y contraseña.'),
        backgroundColor: Color(0xFFD93025),
      ),
    );
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
    final rolNormalizado = role?.toUpperCase().trim() ?? '';

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    if (rolNormalizado.contains('ADMIN')) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    if (rolNormalizado.contains('LECTURADOR') ||
        rolNormalizado.contains('LECTOR')) {
      Navigator.pushReplacementNamed(context, '/lector-home');
      return;
    }

    if (rolNormalizado.contains('CLIENTE') ||
        rolNormalizado.contains('USUARIO') ||
        rolNormalizado.contains('USER')) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rol no reconocido: $role'),
        backgroundColor: const Color(0xFFD93025),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al iniciar sesión: $e'),
        backgroundColor: const Color(0xFFD93025),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0F3D57);
    const Color secondary = Color(0xFF1DA1C2);
    const Color background = Color(0xFFF4F8FB);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
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
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.20),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Center(
                              child: Text(
                                '💧',
                                style: TextStyle(fontSize: 44),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'JASS Huacariz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sistema móvil para clientes del servicio de agua potable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFE7F8FF),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingresa con tu DNI o usuario y contraseña.',
                            style: TextStyle(
                              color: Color(0xFF7B8794),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Usuario o DNI',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: usuarioController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: 'Ej. 12345678',
                              prefixIcon: const Icon(Icons.person_outline),
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

                          const SizedBox(height: 18),

                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: !mostrarPassword,
                            decoration: InputDecoration(
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
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

                          const SizedBox(height: 26),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: cargando ? null : iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: cargando
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿No tienes cuenta?',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Contacta a tu administrador para crear una cuenta.',
                                  style: TextStyle(
                                    color: Color(0xFF7B8794),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Proyecto Agua · JASS Huacariz',
                      style: TextStyle(
                        color: Color(0xFF7B8794),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}