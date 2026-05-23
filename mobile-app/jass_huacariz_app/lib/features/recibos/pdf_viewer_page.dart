import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/services/recibo_pdf_service.dart';

class ReciboPdfViewerPage extends StatefulWidget {
  const ReciboPdfViewerPage({super.key});

  @override
  State<ReciboPdfViewerPage> createState() => _ReciboPdfViewerPageState();
}

class _ReciboPdfViewerPageState extends State<ReciboPdfViewerPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);

  Map<String, dynamic> recibo = {};
  Uint8List? pdfBytes;

  bool cargando = true;
  bool generado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (generado) return;
    generado = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      recibo = args;
    } else if (args is Map) {
      recibo = Map<String, dynamic>.from(args);
    } else {
      recibo = {};
    }

    _generarPdf();
  }

  String _codigoRecibo() {
    final value =
        recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'];

    final text = value?.toString().trim() ?? 'recibo';

    if (text.isEmpty) return 'recibo';

    return text.replaceAll('/', '-').replaceAll(' ', '_');
  }

  Future<void> _generarPdf() async {
    try {
      final bytes = await ReciboPdfService.generar(recibo);

      if (!mounted) return;

      setState(() {
        pdfBytes = bytes;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: const Color(0xFFD93025),
        ),
      );
    }
  }

  Future<void> _compartirPdf() async {
    if (pdfBytes == null) return;

    await Printing.sharePdf(
      bytes: pdfBytes!,
      filename: '${_codigoRecibo()}.pdf',
    );
  }

  Future<void> _imprimirPdf() async {
    if (pdfBytes == null) return;

    await Printing.layoutPdf(
      name: '${_codigoRecibo()}.pdf',
      onLayout: (_) async => pdfBytes!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FB),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Recibo PDF'),
        actions: [
          IconButton(
            onPressed: cargando ? null : _imprimirPdf,
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Imprimir',
          ),
          IconButton(
            onPressed: cargando ? null : _compartirPdf,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir / Guardar',
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : pdfBytes == null
              ? const Center(
                  child: Text('No se pudo generar el PDF.'),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _compartirPdf,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Descargar / Compartir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _imprimirPdf,
                              icon: const Icon(Icons.print_rounded),
                              label: const Text('Imprimir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        pdfFileName: '${_codigoRecibo()}.pdf',
                        build: (_) async => pdfBytes!,
                      ),
                    ),
                  ],
                ),
    );
  }
}