import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'features/auth/change_password_page.dart';

import 'features/home/home_page.dart';
import 'features/perfil/perfil_page.dart';

import 'features/recibos/recibos_page.dart';
import 'features/recibos/recibo_detail_page.dart';
import 'features/recibos/pdf_viewer_page.dart';

import 'features/pagos/pago_cip_page.dart';

import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/admin_clientes_page.dart';
import 'features/admin/admin_tarifas_page.dart';
import 'features/admin/admin_recibos_page.dart';
import 'features/admin/admin_reportes_page.dart';

import 'features/lector/lector_home_page.dart';
import 'features/lector/buscar_suministro_page.dart';
import 'features/lector/detalle_suministro_page.dart';
import 'features/lector/registrar_lectura_page.dart';
import 'features/lector/comprobante_recibo_page.dart';
import 'features/lector/historial_lecturas_page.dart';
import 'features/lector/qr_scanner_page.dart';

class JassHuacarizApp extends StatelessWidget {
  const JassHuacarizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JASS Huacariz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DA1C2),
          primary: const Color(0xFF0F3D57),
          secondary: const Color(0xFF1DA1C2),
        ),
      ),
      initialRoute: '/login',
      routes: {
        // Auth
        '/login': (_) => const LoginPage(),
        '/cambiar-password': (_) => const ChangePasswordPage(),

        // Cliente
        '/home': (_) => const HomePage(),
        '/recibos': (_) => const RecibosPage(),
        '/recibo-detalle': (_) => const ReciboDetailPage(),
        '/pago-cip': (_) => const PagoCipPage(),
        '/perfil': (_) => const PerfilPage(),
        '/pdf-viewer': (_) => const PdfViewerPage(),

        // Admin
        '/admin-dashboard': (_) => const AdminDashboardPage(),
        '/admin-clientes': (_) => const AdminClientesPage(),
        '/admin-tarifas': (_) => const AdminTarifasPage(),
        '/admin-recibos': (_) => const AdminRecibosPage(),
        '/admin-reportes': (_) => const AdminReportesPage(),

        // Lecturador
        '/lector-home': (_) => const LectorHomePage(),
        '/buscar-suministro': (_) => const BuscarSuministroPage(),
        '/qr-scanner': (_) => const QrScannerPage(),
        '/detalle-suministro': (_) => const DetalleSuministroPage(),
        '/registrar-lectura': (_) => const RegistrarLecturaPage(),
        '/comprobante-recibo': (_) => const ComprobanteReciboPage(),
        '/historial-lecturas': (_) => const HistorialLecturasPage(),
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const JassHuacarizApp();
  }
}