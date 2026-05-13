import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'features/auth/change_password_page.dart';
import 'features/home/home_page.dart';
import 'features/recibos/recibos_page.dart';
import 'features/recibos/recibo_detail_page.dart';
import 'features/recibos/pdf_viewer_page.dart';
import 'features/pagos/pago_cip_page.dart';
import 'features/perfil/perfil_page.dart';
import 'shared/theme/app_theme.dart';

class JassHuacarizApp extends StatelessWidget {
  const JassHuacarizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JASS Huacariz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/recibos': (_) => const RecibosPage(),
        '/recibo-detalle': (_) => const ReciboDetailPage(),
        '/pdf-viewer': (_) => const PdfViewerPage(),
        '/pago-cip': (_) => const PagoCipPage(),
        '/perfil': (_) => const PerfilPage(),
        '/cambiar-password': (_) => const ChangePasswordPage(),
      },
    );
  }
}