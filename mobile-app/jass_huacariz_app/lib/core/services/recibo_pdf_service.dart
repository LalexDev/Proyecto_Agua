import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReciboPdfService {
  static String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Future<Uint8List> generar(Map<String, dynamic> recibo) async {
    final pdf = pw.Document();

    final codigoRecibo = _txt(
      recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'],
      'SIN-RECIBO',
    );

    final codigoSuministro = _txt(
      recibo['codigoSuministro'] ?? recibo['suministroCodigo'],
      'SIN-SUMINISTRO',
    );

    final titular = _txt(
      recibo['titular'] ??
          recibo['cliente'] ??
          recibo['nombreCliente'] ??
          recibo['nombres'],
      'Usuario del servicio',
    );

    final direccion = _txt(
      recibo['direccionSuministro'] ?? recibo['direccion'],
      'Dirección no registrada',
    );

    final periodo = _txt(
      recibo['periodo'] ?? '${recibo['mes'] ?? '-'} ${recibo['anio'] ?? ''}',
    );

    final emision = _txt(recibo['fechaEmision'] ?? recibo['emision']);
    final vencimiento = _txt(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
    );

    final consumo = _num(recibo['consumoM3'] ?? recibo['consumo']);
    final total = _num(recibo['total'] ?? recibo['montoTotal']);

    final subtotalAgua = _num(
      recibo['subtotalAgua'] ??
          recibo['volumenAgua'] ??
          recibo['montoAgua'] ??
          recibo['total'],
    );

    final mantenimiento = _num(
      recibo['cargoMantenimiento'] ?? recibo['mantenimiento'],
    );

    final lector = _num(
      recibo['cargoLector'] ?? recibo['pagoLecturador'],
    );

    final mora = _num(recibo['mora'] ?? recibo['montoMora']);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EAF7FB'),
              border: pw.Border.all(
                color: PdfColor.fromHex('#0F3D57'),
                width: 1.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 42,
                      height: 42,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#1DA1C2'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'JH',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'JASS HUACARIZ',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#1DA1C2'),
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Servicio de Agua Potable',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#0F3D57'),
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _mini('Recibo', codigoRecibo),
                        _mini('Suministro', codigoSuministro),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColor.fromHex('#0F3D57')),

                _section('DATOS DEL CLIENTE', [
                  _line('Titular', titular),
                  _line('Suministro', codigoSuministro),
                  _line('Dirección', direccion),
                ]),

                pw.SizedBox(height: 10),

                _section('INFORMACIÓN DEL PERIODO', [
                  _line('Periodo', periodo),
                  _line('Fecha emisión', emision),
                  _line('Vencimiento', vencimiento),
                  _line('Consumo', '${consumo.toStringAsFixed(2)} m³'),
                ]),

                pw.SizedBox(height: 10),

                _section('DETALLE DE FACTURACIÓN', [
                  _line(
                    'Volumen de agua potable',
                    'S/ ${subtotalAgua.toStringAsFixed(2)}',
                  ),
                  _line(
                    'Mantenimiento',
                    'S/ ${mantenimiento.toStringAsFixed(2)}',
                  ),
                  _line(
                    'Pago al lecturador',
                    'S/ ${lector.toStringAsFixed(2)}',
                  ),
                  _line(
                    'Mora',
                    'S/ ${mora.toStringAsFixed(2)}',
                  ),
                ]),

                pw.SizedBox(height: 14),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF3DF'),
                    border: pw.Border.all(color: PdfColor.fromHex('#FFB84D')),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'TOTAL A PAGAR',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#0F3D57'),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Text(
                        'S/ ${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#0F3D57'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                pw.Container(
                  height: 42,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey600),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: List.generate(70, (index) {
                      return pw.Container(
                        width: index % 3 == 0 ? 2 : 1,
                        height: 34,
                        color: PdfColors.black,
                      );
                    }),
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Text(
                  'Estimado usuario, pague su recibo antes de la fecha de vencimiento para evitar mora o suspensión del servicio.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.blueGrey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0F3D57'),
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _line(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.blueGrey700,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0F3D57'),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mini(String label, String value) {
    return pw.Text(
      '$label: $value',
      style: pw.TextStyle(
        color: PdfColor.fromHex('#0F3D57'),
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }
}