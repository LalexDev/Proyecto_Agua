import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'features/auth/change_password_page.dart';

import 'features/home/home_page.dart';
import 'features/recibos/recibos_page.dart';
import 'features/recibos/recibo_detail_page.dart';
import 'features/recibos/pdf_viewer_page.dart';
import 'features/pagos/pago_cip_page.dart';
import 'features/perfil/perfil_page.dart';

import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/admin_clientes_page.dart';
import 'features/admin/admin_tarifas_page.dart';
import 'features/admin/admin_recibos_page.dart';
import 'features/admin/admin_reportes_page.dart';

import 'features/lector/lector_home_page.dart';
import 'features/lector/buscar_suministro_page.dart';
import 'features/lector/registrar_lectura_page.dart';
import 'features/lector/historial_lecturas_page.dart';
import 'features/lector/detalle_suministro_page.dart';
import 'features/lector/comprobante_recibo_page.dart';

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
        // LOGIN
        '/login': (_) => LoginPage(),

        // ADMINISTRADOR
        '/admin-dashboard': (_) => AdminDashboardPage(),
        '/admin-clientes': (_) => AdminClientesPage(),
        '/admin-tarifas': (_) => AdminTarifasPage(),
        '/admin-recibos': (_) => AdminRecibosPage(),
        '/admin-reportes': (_) => AdminReportesPage(),

        // LECTURADOR
        '/lector-home': (_) => LectorHomePage(),
        '/buscar-suministro': (_) => BuscarSuministroPage(),
        '/detalle-suministro': (_) => DetalleSuministroPage(),
        '/registrar-lectura': (_) => RegistrarLecturaPage(),
        '/historial-lecturas': (_) => HistorialLecturasPage(),
        '/comprobante-recibo': (_) => ComprobanteReciboPage(),

        // CLIENTE
        '/home': (_) => HomePage(),
        '/recibos': (_) => RecibosPage(),
        '/recibo-detalle': (_) => ReciboDetailPage(),
        '/pdf-viewer': (_) => PdfViewerPage(),
        '/pago-cip': (_) => PagoCipPage(),
        '/perfil': (_) => PerfilPage(),
        '/cambiar-password': (_) => ChangePasswordPage(),
      },
    );
  }
}