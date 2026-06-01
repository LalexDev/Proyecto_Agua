import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);

  final MobileScannerController scannerController = MobileScannerController();

  bool procesado = false;

  String normalizarCodigoQr(String valor) {
    final texto = valor.trim();

    if (texto.isEmpty) return '';

    try {
      final uri = Uri.parse(texto);

      if (uri.hasScheme && uri.host.isNotEmpty) {
        final codigoParam = uri.queryParameters['codigo'];

        if (codigoParam != null && codigoParam.trim().isNotEmpty) {
          return codigoParam.trim().toUpperCase();
        }

        if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last.trim().toUpperCase();
        }
      }
    } catch (_) {}

    return texto.toUpperCase();
  }

  void procesarQr(String raw) {
    if (procesado) return;

    final codigo = normalizarCodigoQr(raw);

    if (codigo.isEmpty) return;

    setState(() {
      procesado = true;
    });

    Navigator.pop(context, codigo);
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear QR',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await scannerController.toggleTorch();
            },
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Linterna',
          ),
          IconButton(
            onPressed: () async {
              await scannerController.switchCamera();
            },
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;

              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;

              if (raw == null) return;

              procesarQr(raw);
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: secondary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Apunta la cámara al QR del suministro. El sistema leerá el código y buscará al usuario automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}