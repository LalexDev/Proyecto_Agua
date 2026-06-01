package com.jass.huacariz.service;

import com.jass.huacariz.entity.Cliente;
import com.jass.huacariz.entity.Recibo;
import com.jass.huacariz.entity.Suministro;
import com.jass.huacariz.repository.ClienteRepository;
import com.jass.huacariz.repository.ReciboRepository;
import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReciboPdfService {

    private final ReciboRepository reciboRepository;
    private final ClienteRepository clienteRepository;

    private static final Color PRIMARY = new Color(15, 61, 87);
    private static final Color SECONDARY = new Color(29, 161, 194);
    private static final Color BORDER = new Color(160, 190, 200);
    private static final Color LIGHT = new Color(245, 250, 252);

    @Transactional(readOnly = true)
    public byte[] generarPdfAdmin(Integer idRecibo) {
        Recibo recibo = obtenerRecibo(idRecibo);
        return construirPdf(recibo);
    }

    @Transactional(readOnly = true)
    public byte[] generarPdfCliente(Integer idRecibo) {
        Cliente cliente = obtenerClienteAutenticado();
        Recibo recibo = obtenerRecibo(idRecibo);

        if (!perteneceAlCliente(cliente, recibo)) {
            throw new RuntimeException("No tienes permiso para descargar este recibo.");
        }

        return construirPdf(recibo);
    }

    private Recibo obtenerRecibo(Integer idRecibo) {
        return reciboRepository.findById(idRecibo)
                .orElseThrow(() -> new RuntimeException("No existe el recibo con ID: " + idRecibo));
    }

    private Cliente obtenerClienteAutenticado() {
        String codigoUsuario = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return clienteRepository.findByUsuarioCodigoUsuario(codigoUsuario)
                .orElseThrow(() -> new RuntimeException("No existe cliente asociado al usuario autenticado."));
    }

    private boolean perteneceAlCliente(Cliente cliente, Recibo recibo) {
        if (cliente == null || recibo == null || recibo.getSuministro() == null) {
            return false;
        }

        return cliente.getSuministros()
                .stream()
                .anyMatch(suministro -> suministro.getId().equals(recibo.getSuministro().getId()));
    }

    private byte[] construirPdf(Recibo recibo) {
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();

            Document document = new Document(PageSize.A4, 28, 28, 28, 28);
            PdfWriter writer = PdfWriter.getInstance(document, baos);

            document.open();

            PdfPTable marco = new PdfPTable(1);
            marco.setWidthPercentage(100);
            PdfPCell contenedor = new PdfPCell();
            contenedor.setBorderColor(SECONDARY);
            contenedor.setBorderWidth(1.4f);
            contenedor.setPadding(10);

            contenedor.addElement(cabecera(recibo));
            contenedor.addElement(espacio(8));
            contenedor.addElement(bloqueDatosYGrafico(recibo));
            contenedor.addElement(espacio(8));
            contenedor.addElement(resumenPeriodo(recibo));
            contenedor.addElement(espacio(8));
            contenedor.addElement(tablaConceptos(recibo));
            contenedor.addElement(espacio(8));
            contenedor.addElement(bloqueMensajeYTotal(writer, recibo));
            contenedor.addElement(espacio(8));
            contenedor.addElement(pie(recibo));

            marco.addCell(contenedor);
            document.add(marco);

            document.close();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("No se pudo generar el PDF del recibo: " + e.getMessage(), e);
        }
    }

    private PdfPTable cabecera(Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{70, 30});

        PdfPCell left = new PdfPCell();
        left.setBorder(Rectangle.NO_BORDER);
        left.setPadding(0);

        Paragraph titulo = new Paragraph("💧  J A S S   H U A C A R I Z", font(20, Font.BOLD, PRIMARY));
        titulo.setSpacingAfter(2);
        left.addElement(titulo);
        left.addElement(new Paragraph("Servicio de agua potable · Recibo de cobranza", font(9, Font.BOLD, PRIMARY)));
        left.addElement(new Paragraph("Cajamarca, Perú · Sistema de Gestión de Agua", font(8, Font.NORMAL, Color.DARK_GRAY)));

        PdfPCell right = new PdfPCell();
        right.setBorderColor(BORDER);
        right.setPadding(8);
        right.setHorizontalAlignment(Element.ALIGN_CENTER);

        Paragraph periodoLabel = new Paragraph("PERIODO DE\nFACTURACIÓN", font(9, Font.BOLD, PRIMARY));
        periodoLabel.setAlignment(Element.ALIGN_CENTER);
        right.addElement(periodoLabel);

        Paragraph periodo = new Paragraph(periodo(recibo), font(14, Font.BOLD, PRIMARY));
        periodo.setAlignment(Element.ALIGN_CENTER);
        right.addElement(periodo);

        table.addCell(left);
        table.addCell(right);

        return table;
    }

    private PdfPTable bloqueDatosYGrafico(Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{48, 52});

        table.addCell(datosServicio(recibo));
        table.addCell(historialConsumo(recibo));

        return table;
    }

    private PdfPCell datosServicio(Recibo recibo) {
        PdfPCell cell = new PdfPCell();
        cell.setBorderColor(BORDER);
        cell.setPadding(8);

        cell.addElement(new Paragraph("Datos del servicio", font(10, Font.BOLD, PRIMARY)));
        cell.addElement(linea("Cliente", cliente(recibo)));
        cell.addElement(linea("DNI", dni(recibo)));
        cell.addElement(linea("Recibo", safe(recibo.getCodigoRecibo())));
        cell.addElement(linea("Suministro", codigoSuministro(recibo)));
        cell.addElement(linea("Dirección", direccion(recibo)));
        cell.addElement(linea("Sector", sector(recibo)));
        cell.addElement(linea("Estado", safe(recibo.getEstadoRecibo())));

        return cell;
    }

    private PdfPCell historialConsumo(Recibo recibo) throws DocumentException {
        PdfPCell cell = new PdfPCell();
        cell.setBorderColor(BORDER);
        cell.setPadding(8);

        Paragraph title = new Paragraph("Historial gráfico de consumo últimos 3 meses", font(10, Font.BOLD, PRIMARY));
        title.setAlignment(Element.ALIGN_CENTER);
        cell.addElement(title);
        cell.addElement(espacio(5));

        PdfPTable barras = new PdfPTable(3);
        barras.setWidthPercentage(78);
        barras.setHorizontalAlignment(Element.ALIGN_CENTER);

        List<Recibo> ultimos = reciboRepository.findBySuministroId(recibo.getSuministro().getId())
                .stream()
                .sorted((a, b) -> {
                    int pa = valorEntero(a.getAnio()) * 100 + valorEntero(a.getMes());
                    int pb = valorEntero(b.getAnio()) * 100 + valorEntero(b.getMes());
                    return Integer.compare(pa, pb);
                })
                .skip(Math.max(0, reciboRepository.findBySuministroId(recibo.getSuministro().getId()).size() - 3))
                .toList();

        if (ultimos.isEmpty()) {
            ultimos = List.of(recibo);
        }

        for (Recibo item : ultimos) {
            PdfPCell c = new PdfPCell(new Phrase(formatDecimal(item.getConsumoM3()), font(8, Font.BOLD, PRIMARY)));
            c.setHorizontalAlignment(Element.ALIGN_CENTER);
            c.setBorder(Rectangle.NO_BORDER);
            barras.addCell(c);
        }

        for (Recibo item : ultimos) {
            PdfPCell c = new PdfPCell(new Phrase("█", font(20, Font.BOLD, SECONDARY)));
            c.setHorizontalAlignment(Element.ALIGN_CENTER);
            c.setBorder(Rectangle.NO_BORDER);
            barras.addCell(c);
        }

        for (Recibo item : ultimos) {
            PdfPCell c = new PdfPCell(new Phrase(nombreMesCorto(item.getMes()) + " " + String.valueOf(item.getAnio()).substring(2), font(7, Font.NORMAL, Color.DARK_GRAY)));
            c.setHorizontalAlignment(Element.ALIGN_CENTER);
            c.setBorder(Rectangle.NO_BORDER);
            barras.addCell(c);
        }

        cell.addElement(barras);

        return cell;
    }

    private PdfPTable resumenPeriodo(Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(5);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{18, 18, 22, 22, 20});

        addResumenCell(table, "Periodo", periodo(recibo));
        addResumenCell(table, "Consumo", formatDecimal(recibo.getConsumoM3()) + " m³");
        addResumenCell(table, "Emisión", fecha(recibo.getFechaEmision()));
        addResumenCell(table, "Vencimiento", fecha(recibo.getFechaVencimiento()));
        addResumenCell(table, "Total", "S/ " + moneda(recibo.getTotal()));

        return table;
    }

    private PdfPTable tablaConceptos(Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{26, 54, 20});

        addHeader(table, "Concepto");
        addHeader(table, "Descripción");
        addHeader(table, "Importe");

        addConcepto(table, "Consumo de agua", "Consumo registrado: " + formatDecimal(recibo.getConsumoM3()) + " m³", recibo.getSubtotalAgua());
        addConcepto(table, "Mantenimiento", "Cargo de mantenimiento del sistema", recibo.getCargoMantenimiento());
        addConcepto(table, "Lector", "Cargo por registro de lectura", recibo.getCargoLector());
        addConcepto(table, "Otros cargos", "Otros cargos administrativos o adicionales", recibo.getCargoOtros());
        addConcepto(table, "Mora", "Cargo por vencimiento, si corresponde", recibo.getMora());

        return table;
    }

    private PdfPTable bloqueMensajeYTotal(PdfWriter writer, Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{60, 40});

        PdfPCell mensaje = new PdfPCell();
        mensaje.setBorderColor(BORDER);
        mensaje.setPadding(8);
        mensaje.addElement(new Paragraph("Estimado usuario:", font(9, Font.BOLD, PRIMARY)));
        mensaje.addElement(new Paragraph(
                "Cumpla con realizar sus pagos antes de la fecha de vencimiento para evitar mora, suspensión del servicio o restricciones administrativas. Conserve este recibo como constancia de cobranza.",
                font(8, Font.NORMAL, Color.DARK_GRAY)
        ));

        String codigoBarras = codigoBarras(recibo);
        try {
            Barcode128 barcode = new Barcode128();
            barcode.setCode(codigoBarras);
            barcode.setCodeType(Barcode128.CODE128);
            Image img = barcode.createImageWithBarcode(writer.getDirectContent(), null, null);
            img.scalePercent(110);
            mensaje.addElement(espacio(6));
            mensaje.addElement(img);
            Paragraph code = new Paragraph(codigoBarras, font(8, Font.BOLD, PRIMARY));
            code.setAlignment(Element.ALIGN_CENTER);
            mensaje.addElement(code);
        } catch (Exception ignored) {
            mensaje.addElement(new Paragraph(codigoBarras, font(8, Font.BOLD, PRIMARY)));
        }

        PdfPCell total = new PdfPCell();
        total.setBorderColor(SECONDARY);
        total.setBorderWidth(1.2f);
        total.setPadding(10);
        total.addElement(lineaTotal("Subtotal agua", recibo.getSubtotalAgua(), false));
        total.addElement(lineaTotal("Cargos", cargos(recibo), false));
        total.addElement(espacio(8));

        Paragraph totalText = new Paragraph("Total a pagar        S/ " + moneda(recibo.getTotal()), font(18, Font.BOLD, PRIMARY));
        total.addElement(totalText);
        total.addElement(espacio(8));
        total.addElement(new Paragraph("Vence                         " + fecha(recibo.getFechaVencimiento()), font(10, Font.BOLD, PRIMARY)));

        table.addCell(mensaje);
        table.addCell(total);

        return table;
    }

    private PdfPTable pie(Recibo recibo) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);

        PdfPCell left = new PdfPCell(new Phrase("Atención: Documento emitido por el sistema de gestión de agua JASS Huacariz.", font(7, Font.NORMAL, Color.DARK_GRAY)));
        left.setBorderColor(BORDER);
        left.setPadding(5);

        PdfPCell right = new PdfPCell(new Phrase("Validación: Código de barras " + codigoBarras(recibo), font(7, Font.NORMAL, Color.DARK_GRAY)));
        right.setBorderColor(BORDER);
        right.setPadding(5);

        table.addCell(left);
        table.addCell(right);

        return table;
    }

    private void addResumenCell(PdfPTable table, String label, String value) {
        PdfPCell cell = new PdfPCell();
        cell.setBorderColor(BORDER);
        cell.setPadding(7);
        cell.addElement(new Paragraph(label, font(8, Font.BOLD, PRIMARY)));
        cell.addElement(new Paragraph(value, font(9, Font.BOLD, Color.DARK_GRAY)));
        table.addCell(cell);
    }

    private void addHeader(PdfPTable table, String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font(8, Font.BOLD, PRIMARY)));
        cell.setBackgroundColor(LIGHT);
        cell.setBorderColor(BORDER);
        cell.setPadding(5);
        table.addCell(cell);
    }

    private void addConcepto(PdfPTable table, String concepto, String descripcion, BigDecimal importe) {
        PdfPCell c1 = new PdfPCell(new Phrase(concepto, font(8, Font.NORMAL, Color.DARK_GRAY)));
        PdfPCell c2 = new PdfPCell(new Phrase(descripcion, font(8, Font.NORMAL, Color.DARK_GRAY)));
        PdfPCell c3 = new PdfPCell(new Phrase("S/ " + moneda(importe), font(8, Font.BOLD, PRIMARY)));

        c1.setBorderColor(BORDER);
        c2.setBorderColor(BORDER);
        c3.setBorderColor(BORDER);

        c1.setPadding(5);
        c2.setPadding(5);
        c3.setPadding(5);

        c3.setHorizontalAlignment(Element.ALIGN_RIGHT);

        table.addCell(c1);
        table.addCell(c2);
        table.addCell(c3);
    }

    private Paragraph linea(String label, String value) {
        Paragraph p = new Paragraph();
        p.add(new Chunk(label + ": ", font(8, Font.BOLD, PRIMARY)));
        p.add(new Chunk(value, font(8, Font.BOLD, Color.DARK_GRAY)));
        return p;
    }

    private Paragraph lineaTotal(String label, BigDecimal value, boolean grande) {
        Paragraph p = new Paragraph(label + "                                      S/ " + moneda(value), font(grande ? 12 : 9, Font.BOLD, PRIMARY));
        return p;
    }

    private Paragraph espacio(float height) {
        Paragraph p = new Paragraph(" ");
        p.setSpacingAfter(height);
        return p;
    }

    private Font font(int size, int style, Color color) {
        return FontFactory.getFont(FontFactory.HELVETICA, size, style, color);
    }

    private String safe(Object value) {
        if (value == null) return "-";
        String text = value.toString().trim();
        return text.isEmpty() ? "-" : text;
    }

    private String cliente(Recibo recibo) {
        Suministro s = recibo.getSuministro();
        if (s == null || s.getCliente() == null) return "-";

        String nombres = safe(s.getCliente().getNombres());
        String apellidos = safe(s.getCliente().getApellidos());

        return (nombres + " " + apellidos).replace("-", "").trim();
    }

    private String dni(Recibo recibo) {
        Suministro s = recibo.getSuministro();
        return s != null && s.getCliente() != null ? safe(s.getCliente().getDni()) : "-";
    }

    private String codigoSuministro(Recibo recibo) {
        return recibo.getSuministro() != null ? safe(recibo.getSuministro().getCodigoSuministro()) : "-";
    }

    private String direccion(Recibo recibo) {
        return recibo.getSuministro() != null ? safe(recibo.getSuministro().getDireccionSuministro()) : "-";
    }

    private String sector(Recibo recibo) {
        return recibo.getSuministro() != null && recibo.getSuministro().getSector() != null
                ? safe(recibo.getSuministro().getSector().getNombre())
                : "-";
    }

    private String periodo(Recibo recibo) {
        return nombreMes(recibo.getMes()) + " " + recibo.getAnio();
    }

    private String nombreMes(Integer mes) {
        String[] meses = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"};
        int index = mes == null ? 0 : Math.max(0, Math.min(11, mes - 1));
        return meses[index];
    }

    private String nombreMesCorto(Integer mes) {
        String[] meses = {"Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"};
        int index = mes == null ? 0 : Math.max(0, Math.min(11, mes - 1));
        return meses[index];
    }

    private String fecha(Object fecha) {
        if (fecha == null) return "-";

        try {
            if (fecha instanceof java.time.LocalDate localDate) {
                return localDate.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
            }

            if (fecha instanceof java.time.LocalDateTime localDateTime) {
                return localDateTime.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
            }
        } catch (Exception ignored) {}

        return fecha.toString();
    }

    private String moneda(BigDecimal value) {
        return valor(value).setScale(2, RoundingMode.HALF_UP).toString();
    }

    private String formatDecimal(BigDecimal value) {
        return valor(value).setScale(3, RoundingMode.HALF_UP).toString();
    }

    private BigDecimal valor(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private BigDecimal cargos(Recibo recibo) {
        return valor(recibo.getCargoMantenimiento())
                .add(valor(recibo.getCargoLector()))
                .add(valor(recibo.getCargoOtros()))
                .add(valor(recibo.getMora()));
    }

    private int valorEntero(Integer value) {
        return value == null ? 0 : value;
    }

    private String codigoBarras(Recibo recibo) {
        return safe(recibo.getCodigoRecibo()) + "-" + codigoSuministro(recibo);
    }
}