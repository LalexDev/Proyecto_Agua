import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/services/recibo_pdf_service.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color background = Color(0xFFEFF7FB);

  Map<String, dynamic> recibo = {};
  Uint8List? pdfBytes;

  bool cargando = true;
  bool generado = false;
  String error = '';

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

    _cargarPdfReal();
  }

  String _codigoRecibo() {
    final value =
        recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'];

    final text = value?.toString().trim() ?? 'recibo';

    if (text.isEmpty) return 'recibo';

    return text.replaceAll('/', '-').replaceAll(' ', '_');
  }

  Future<void> _cargarPdfReal() async {
    setState(() {
      cargando = true;
      error = '';
    });

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
        error = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar PDF: $error'),
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
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Recibo PDF',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: cargando ? null : _cargarPdfReal,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
          IconButton(
            onPressed: cargando || pdfBytes == null ? null : _imprimirPdf,
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Imprimir',
          ),
          IconButton(
            onPressed: cargando || pdfBytes == null ? null : _compartirPdf,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir / Guardar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFFFD1D1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFFD93025),
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo cargar el PDF real del recibo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.isEmpty ? 'Verifica el endpoint del backend.' : error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD93025),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargarPdfReal,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
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
                  label: const Text(
                    'Descargar / Compartir',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _imprimirPdf,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text(
                    'Imprimir',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    minimumSize: const Size(0, 48),
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
    );
  }
}