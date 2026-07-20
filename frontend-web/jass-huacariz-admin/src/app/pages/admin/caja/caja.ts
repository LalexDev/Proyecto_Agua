import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize, forkJoin } from 'rxjs';
import * as XLSX from 'xlsx-js-style';
import { Pago, PagoResponse } from '../../../core/services/pago';

import {
  MovimientoCaja,
  MovimientoCajaRequest,
  MovimientoCajaResponse
} from '../../../core/services/movimiento-caja';

@Component({
  selector: 'app-caja',
  imports: [CommonModule, FormsModule],
  templateUrl: './caja.html',
  styleUrl: './caja.scss',
})
export class Caja implements OnInit {
  movimientos: MovimientoCajaResponse[] = [];
  movimientosFiltrados: MovimientoCajaResponse[] = [];
  pagos: PagoResponse[] = [];

  cargando = false;
  guardando = false;
  error = '';
  exito = '';

  busqueda = '';
  filtroEstado = 'TODOS';
  filtroAnio: number | 'TODOS' = new Date().getFullYear();
filtroMes: number | 'TODOS' = 'TODOS';

meses = [
  { valor: 1, nombre: 'Enero' },
  { valor: 2, nombre: 'Febrero' },
  { valor: 3, nombre: 'Marzo' },
  { valor: 4, nombre: 'Abril' },
  { valor: 5, nombre: 'Mayo' },
  { valor: 6, nombre: 'Junio' },
  { valor: 7, nombre: 'Julio' },
  { valor: 8, nombre: 'Agosto' },
  { valor: 9, nombre: 'Septiembre' },
  { valor: 10, nombre: 'Octubre' },
  { valor: 11, nombre: 'Noviembre' },
  { valor: 12, nombre: 'Diciembre' }
];

  modalAbierto = false;

  formulario: MovimientoCajaRequest = {
    tipoMovimiento: 'EGRESO',
    categoria: 'MANTENIMIENTO',
    descripcion: '',
    monto: 0,
    responsable: '',
    comprobanteUrl: ''
  };

categorias = [
  'NUEVO PADRON',
  'MANTENIMIENTOS',
  'MATERIALES',
  'PAGO_PERSONAL',
  'SERVICIOS',
  'MOVILIDAD',
  'REPARACION',
  'DONACION',
  'APORTE',
  'MULTAS',
  'OTROS'
];

  constructor(
    private cajaService: MovimientoCaja,
    private cdr: ChangeDetectorRef,
    private pagoService: Pago
  ) {}

  ngOnInit(): void {
    this.cargarMovimientos();
  }

cargarMovimientos(): void {
  this.cargando = true;
  this.error = '';
  this.exito = '';

  forkJoin({
    movimientos: this.cajaService.listar(),
    pagos: this.pagoService.listarPagos()
  })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: ({ movimientos, pagos }) => {
        this.movimientos = movimientos || [];
        this.pagos = pagos || [];
        this.aplicarFiltros();
      },
      error: () => {
        this.error = 'No se pudieron cargar los movimientos de caja.';
        this.movimientos = [];
        this.movimientosFiltrados = [];
        this.pagos = [];
      }
    });
}

aplicarFiltros(): void {
  const texto = this.busqueda.trim().toLowerCase();

  this.movimientosFiltrados = this.movimientos.filter((movimiento) => {
    const coincideTexto =
      !texto ||
      String(movimiento.categoria || '').toLowerCase().includes(texto) ||
      String(movimiento.descripcion || '').toLowerCase().includes(texto) ||
      String(movimiento.responsable || '').toLowerCase().includes(texto) ||
      String(movimiento.tipoMovimiento || '').toLowerCase().includes(texto) ||
      String(movimiento.estado || '').toLowerCase().includes(texto) ||
      String(movimiento.monto || '').toLowerCase().includes(texto);

    const coincideEstado =
      this.filtroEstado === 'TODOS' ||
      movimiento.estado === this.filtroEstado;

    const coincidePeriodo = this.pertenecePeriodo(movimiento.fechaMovimiento);

    return coincideTexto && coincideEstado && coincidePeriodo;
  });
}

limpiarFiltros(): void {
  this.busqueda = '';
  this.filtroEstado = 'TODOS';
  this.filtroAnio = new Date().getFullYear();
  this.filtroMes = 'TODOS';
  this.aplicarFiltros();
}

  abrirModal(): void {
    this.modalAbierto = true;
    this.error = '';
    this.exito = '';

    this.formulario = {
      tipoMovimiento: 'EGRESO',
      categoria: 'MANTENIMIENTO',
      descripcion: '',
      monto: 0,
      responsable: '',
      comprobanteUrl: ''
    };
  }

  cerrarModal(): void {
    this.modalAbierto = false;
  }

  guardarMovimiento(): void {
    if (!this.formulario.categoria?.trim()) {
      this.error = 'Seleccione una categoría.';
      return;
    }

    if (!this.formulario.descripcion?.trim()) {
      this.error = 'Ingrese el detalle o motivo del movimiento.';
      return;
    }

    if (!this.formulario.monto || Number(this.formulario.monto) <= 0) {
      this.error = 'Ingrese un monto mayor a 0.';
      return;
    }

    const tipoMovimiento = String(this.formulario.tipoMovimiento || '').toUpperCase();
    const montoMovimiento = Number(this.formulario.monto || 0);

    if (tipoMovimiento === 'EGRESO' && montoMovimiento > this.saldoDisponible()) {
    this.error = `Saldo insuficiente. Disponible: S/ ${this.saldoDisponible().toFixed(2)}. No puede registrar un gasto de S/ ${montoMovimiento.toFixed(2)}.`;
    return;
    }

    const payload: MovimientoCajaRequest = {
      tipoMovimiento: this.formulario.tipoMovimiento || 'EGRESO',
      categoria: this.formulario.categoria.trim(),
      descripcion: this.formulario.descripcion.trim(),
      monto: Number(this.formulario.monto),
      responsable: this.formulario.responsable?.trim() || '',
      comprobanteUrl: this.formulario.comprobanteUrl?.trim() || ''
    };

    this.guardando = true;
    this.error = '';
    this.exito = '';

    this.cajaService.crear(payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Movimiento registrado correctamente.';
          this.cerrarModal();
          this.cargarMovimientos();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar el movimiento.';
        }
      });
  }

  anularMovimiento(movimiento: MovimientoCajaResponse): void {
    if (!confirm(`¿Anular el movimiento de S/ ${Number(movimiento.monto).toFixed(2)}?`)) {
      return;
    }

    this.cajaService.anular(movimiento.id).subscribe({
      next: () => {
        this.exito = 'Movimiento anulado correctamente.';
        this.cargarMovimientos();
      },
      error: (err) => {
        this.error = err?.error?.error || 'No se pudo anular el movimiento.';
      }
    });
  }

  totalEgresos(): number {
    return this.movimientos
      .filter((m) => m.estado === 'ACTIVO' && m.tipoMovimiento === 'EGRESO')
      .reduce((total, m) => total + Number(m.monto || 0), 0);
  }

  totalIngresosManuales(): number {
    return this.movimientos
      .filter((m) => m.estado === 'ACTIVO' && m.tipoMovimiento === 'INGRESO')
      .reduce((total, m) => total + Number(m.monto || 0), 0);
  }

  esPagoValido(pago: PagoResponse): boolean {
  const estado = String(pago.estadoPago || '').toUpperCase();

  return estado === 'PAGADO' ||
         estado === 'PAGADO_CONFIRMADO' ||
         estado === 'CONFIRMADO';
}

totalRecaudadoPagos(): number {
  return this.pagos
    .filter((pago) => this.esPagoValido(pago))
    .reduce((total, pago) => {
      return total + Number(pago.monto || 0);
    }, 0);
}

saldoDisponible(): number {
  const saldo = this.totalRecaudadoPagos()
    + this.totalIngresosManuales()
    - this.totalEgresos();

  return saldo < 0 ? 0 : saldo;
}

  totalMovimientosActivos(): number {
    return this.movimientos.filter((m) => m.estado === 'ACTIVO').length;
  }

  fechaTexto(fecha: string): string {
    if (!fecha) {
      return '-';
    }

    const valor = new Date(fecha);

    if (isNaN(valor.getTime())) {
      return '-';
    }

    return valor.toLocaleString('es-PE');
  }

exportarExcel(): void {
  const fechaEmision = new Date().toLocaleString('es-PE');
  const periodo = this.textoPeriodo();

  const movimientos = this.movimientosFiltrados;
  const resumenCategoria = this.resumenPorCategoria();

  const filas: any[][] = [
    ['AGUA POTABLE HUACARIZ - REPORTE DE CAJA / TESORERÍA'],
    ['Sistema de gestión de agua potable - Control financiero de ingresos y gastos'],
    [`Periodo/Filtro: ${periodo}`],
    [`Fecha de exportación: ${fechaEmision}`],
    [],
    ['RESUMEN FINANCIERO'],
    ['Concepto', 'Monto S/'],
    ['Pagos recibidos por recibos', this.totalRecaudadoPagosPeriodo()],
    ['Otros ingresos', this.totalIngresosManualesPeriodo()],
    ['Total ingresos', this.totalIngresosPeriodo()],
    ['Gastos / retiros', this.totalEgresosPeriodo()],
    ['Saldo del periodo', this.saldoDisponiblePeriodo()],
    [],
    ['RESUMEN POR CATEGORÍA'],
    ['Categoría', 'Ingresos S/', 'Gastos S/', 'Saldo S/'],
    ...resumenCategoria.map((item) => [
      item.categoria,
      item.ingresos,
      item.egresos,
      item.saldo
    ]),
    [],
    ['DETALLE DE MOVIMIENTOS'],
    ['N°', 'Fecha', 'Tipo', 'Categoría', 'Detalle', 'Responsable', 'Monto S/', 'Estado'],
    ...movimientos.map((m, index) => [
      index + 1,
      this.fechaTexto(m.fechaMovimiento),
      m.tipoMovimiento,
      m.categoria,
      m.descripcion,
      m.responsable || '-',
      Number(m.monto || 0),
      m.estado
    ])
  ];

  const ws: any = XLSX.utils.aoa_to_sheet(filas);

  ws['!cols'] = [
    { wch: 8 },
    { wch: 26 },
    { wch: 18 },
    { wch: 22 },
    { wch: 48 },
    { wch: 24 },
    { wch: 16 },
    { wch: 16 }
  ];

  ws['!merges'] = [
    { s: { r: 0, c: 0 }, e: { r: 0, c: 7 } },
    { s: { r: 1, c: 0 }, e: { r: 1, c: 7 } },
    { s: { r: 5, c: 0 }, e: { r: 5, c: 7 } },
    { s: { r: 13, c: 0 }, e: { r: 13, c: 7 } }
  ];

  const azulPrincipal = '0EA5B7';
  const azulOscuro = '083344';
  const azulClaro = 'E0F7FA';
  const verdeClaro = 'DCFCE7';
  const rojoClaro = 'FEE2E2';
  const amarilloClaro = 'FEF3C7';
  const blanco = 'FFFFFF';
  const textoOscuro = '0F172A';
  const borde = 'D7E3EA';

  const aplicarBorde = () => ({
    top: { style: 'thin', color: { rgb: borde } },
    bottom: { style: 'thin', color: { rgb: borde } },
    left: { style: 'thin', color: { rgb: borde } },
    right: { style: 'thin', color: { rgb: borde } }
  });

  const rango = XLSX.utils.decode_range(ws['!ref']);

  for (let r = rango.s.r; r <= rango.e.r; r++) {
    for (let c = rango.s.c; c <= rango.e.c; c++) {
      const ref = XLSX.utils.encode_cell({ r, c });

      if (!ws[ref]) {
        ws[ref] = { t: 's', v: '' };
      }

      ws[ref].s = {
        font: {
          name: 'Calibri',
          sz: 11,
          color: { rgb: textoOscuro }
        },
        alignment: {
          vertical: 'center',
          wrapText: true
        },
        border: aplicarBorde()
      };
    }
  }

  // Título principal
  ws['A1'].s = {
    font: {
      name: 'Calibri',
      sz: 18,
      bold: true,
      color: { rgb: blanco }
    },
    fill: { fgColor: { rgb: azulPrincipal } },
    alignment: {
      horizontal: 'center',
      vertical: 'center'
    },
    border: aplicarBorde()
  };

  ws['A2'].s = {
    font: {
      name: 'Calibri',
      sz: 12,
      bold: true,
      color: { rgb: blanco }
    },
    fill: { fgColor: { rgb: azulOscuro } },
    alignment: {
      horizontal: 'center',
      vertical: 'center'
    },
    border: aplicarBorde()
  };

  ['A3', 'A4'].forEach((cell) => {
    if (ws[cell]) {
      ws[cell].s = {
        font: {
          name: 'Calibri',
          sz: 11,
          bold: true,
          color: { rgb: textoOscuro }
        },
        fill: { fgColor: { rgb: azulClaro } },
        alignment: {
          vertical: 'center'
        },
        border: aplicarBorde()
      };
    }
  });

  // Secciones oscuras
  ['A6', 'A14'].forEach((cell) => {
    if (ws[cell]) {
      ws[cell].s = {
        font: {
          name: 'Calibri',
          sz: 13,
          bold: true,
          color: { rgb: blanco }
        },
        fill: { fgColor: { rgb: azulOscuro } },
        alignment: {
          horizontal: 'center',
          vertical: 'center'
        },
        border: aplicarBorde()
      };
    }
  });

  const detalleHeaderRow = filas.findIndex((fila) => fila[0] === 'N°');

  const headerRows = [6, 14];

  if (detalleHeaderRow >= 0) {
    headerRows.push(detalleHeaderRow);
  }

  // Encabezados de tablas
  headerRows.forEach((rowIndex) => {
    for (let c = 0; c <= 7; c++) {
      const ref = XLSX.utils.encode_cell({ r: rowIndex, c });

      if (ws[ref]) {
        ws[ref].s = {
          font: {
            name: 'Calibri',
            sz: 11,
            bold: true,
            color: { rgb: blanco }
          },
          fill: { fgColor: { rgb: azulPrincipal } },
          alignment: {
            horizontal: 'center',
            vertical: 'center',
            wrapText: true
          },
          border: {
            top: { style: 'thin', color: { rgb: blanco } },
            bottom: { style: 'thin', color: { rgb: blanco } },
            left: { style: 'thin', color: { rgb: blanco } },
            right: { style: 'thin', color: { rgb: blanco } }
          }
        };
      }
    }
  });

  // Resumen financiero con colores
  const resumenInicio = 7;
  const resumenFin = 11;

  for (let r = resumenInicio; r <= resumenFin; r++) {
    const concepto = String(ws[`A${r + 1}`]?.v || '').toLowerCase();

    for (let c = 0; c <= 1; c++) {
      const ref = XLSX.utils.encode_cell({ r, c });

      if (!ws[ref]) continue;

      let fill = azulClaro;

      if (concepto.includes('ingreso')) {
        fill = verdeClaro;
      }

      if (concepto.includes('gasto') || concepto.includes('retiro')) {
        fill = rojoClaro;
      }

      if (concepto.includes('saldo')) {
        fill = amarilloClaro;
      }

      ws[ref].s = {
        font: {
          name: 'Calibri',
          sz: 11,
          bold: c === 0,
          color: { rgb: textoOscuro }
        },
        fill: { fgColor: { rgb: fill } },
        alignment: {
          vertical: 'center'
        },
        border: aplicarBorde()
      };
    }
  }

  // Formato moneda en columnas numéricas
  for (let r = 0; r <= rango.e.r; r++) {
    ['B', 'C', 'D', 'G'].forEach((col) => {
      const ref = `${col}${r + 1}`;

      if (ws[ref] && typeof ws[ref].v === 'number') {
        ws[ref].z = '"S/ "#,##0.00';
      }
    });
  }

  // Pintar detalle por tipo y estado
  if (detalleHeaderRow >= 0) {
    for (let r = detalleHeaderRow + 1; r <= rango.e.r; r++) {
      const tipo = String(ws[XLSX.utils.encode_cell({ r, c: 2 })]?.v || '').toUpperCase();
      const estado = String(ws[XLSX.utils.encode_cell({ r, c: 7 })]?.v || '').toUpperCase();

      for (let c = 0; c <= 7; c++) {
        const ref = XLSX.utils.encode_cell({ r, c });

        if (!ws[ref]) continue;

        if (tipo === 'INGRESO') {
          ws[ref].s.fill = { fgColor: { rgb: verdeClaro } };
        }

        if (tipo === 'EGRESO') {
          ws[ref].s.fill = { fgColor: { rgb: rojoClaro } };
        }

        if (estado === 'ANULADO') {
          ws[ref].s.fill = { fgColor: { rgb: amarilloClaro } };
        }
      }
    }
  }

  ws['!rows'] = [
    { hpt: 28 },
    { hpt: 22 },
    { hpt: 22 },
    { hpt: 22 },
    { hpt: 10 },
    { hpt: 24 }
  ];

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Caja');

  const fecha = new Date().toISOString().slice(0, 10);
  XLSX.writeFile(wb, `reporte_caja_${fecha}.xlsx`);
}

imprimir(): void {
  const periodo = this.textoPeriodo();
  const fecha = new Date().toLocaleString('es-PE');

  const resumenCategoria = this.resumenPorCategoria().map((item) => `
    <div class="category-card">
      <span>${item.categoria}</span>
      <div>
        <small>Ingresos</small>
        <strong class="income">S/ ${item.ingresos.toFixed(2)}</strong>
      </div>
      <div>
        <small>Gastos</small>
        <strong class="expense">S/ ${item.egresos.toFixed(2)}</strong>
      </div>
      <div>
        <small>Saldo</small>
        <strong class="${item.saldo < 0 ? 'negative' : ''}">S/ ${item.saldo.toFixed(2)}</strong>
      </div>
    </div>
  `).join('');

  const filas = this.movimientosFiltrados.map((m, index) => `
    <tr>
      <td>${index + 1}</td>
      <td>${this.fechaTexto(m.fechaMovimiento)}</td>
      <td><span class="chip ${String(m.tipoMovimiento).toLowerCase()}">${m.tipoMovimiento}</span></td>
      <td>${m.categoria}</td>
      <td>${m.descripcion}</td>
      <td>${m.responsable || '-'}</td>
      <td class="money">S/ ${Number(m.monto || 0).toFixed(2)}</td>
      <td><span class="status ${String(m.estado).toLowerCase()}">${m.estado}</span></td>
    </tr>
  `).join('');

  const ventana = window.open('', '_blank', 'width=1200,height=850');

  if (!ventana) {
    alert('El navegador bloqueó la ventana de impresión.');
    return;
  }

  ventana.document.open();
  ventana.document.write(`
    <html>
    <head>
      <title>Reporte de Caja</title>
      <style>
        * {
          box-sizing: border-box;
        }

        body {
          margin: 0;
          padding: 32px;
          font-family: Arial, Helvetica, sans-serif;
          color: #0f172a;
          background: #f1f7fb;
        }

        .report {
          background: #ffffff;
          border-radius: 22px;
          overflow: hidden;
          border: 1px solid #dbeafe;
          box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08);
        }

        .hero {
          background: linear-gradient(135deg, #0f7f95, #06b6d4);
          color: #ffffff;
          padding: 28px 32px;
        }

        .hero h1 {
          margin: 0;
          font-size: 26px;
          letter-spacing: .5px;
        }

        .hero p {
          margin: 8px 0 0;
          opacity: .92;
          font-weight: 700;
        }

        .meta {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 12px;
          padding: 18px 32px;
          background: #e0f7fa;
          border-bottom: 1px solid #bae6fd;
          font-weight: 800;
        }

        .content {
          padding: 28px 32px;
        }

        .section-title {
          margin: 0 0 16px;
          font-size: 18px;
          font-weight: 950;
          color: #083344;
          letter-spacing: .3px;
        }

        .cards {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 14px;
          margin-bottom: 28px;
        }

        .card {
          border-radius: 18px;
          border: 1px solid #dbeafe;
          background: #f8fafc;
          padding: 16px;
        }

        .card span {
          display: block;
          color: #64748b;
          font-size: 12px;
          font-weight: 850;
          margin-bottom: 8px;
        }

        .card strong {
          display: block;
          font-size: 22px;
          font-weight: 950;
          color: #0f172a;
        }

        .card.blue strong {
          color: #2563eb;
        }

        .card.green strong {
          color: #16a34a;
        }

        .card.red strong {
          color: #dc2626;
        }

        .card.saldo {
          background: linear-gradient(135deg, #0f766e, #06b6d4);
          color: #ffffff;
          border: none;
        }

        .card.saldo span,
        .card.saldo strong {
          color: #ffffff;
        }

        .category-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 12px;
          margin-bottom: 28px;
        }

        .category-card {
          border: 1px solid #dbeafe;
          border-radius: 16px;
          padding: 14px;
          background: #f8fafc;
        }

        .category-card > span {
          display: block;
          font-weight: 950;
          margin-bottom: 10px;
          color: #083344;
        }

        .category-card small {
          color: #64748b;
          font-size: 11px;
          font-weight: 800;
        }

        .category-card strong {
          display: block;
          margin-bottom: 6px;
          font-size: 13px;
        }

        .income {
          color: #16a34a;
        }

        .expense,
        .negative {
          color: #dc2626;
        }

        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 12px;
          overflow: hidden;
          border-radius: 14px;
        }

        th {
          background: #0f7f95;
          color: #ffffff;
          padding: 11px 10px;
          text-align: left;
          font-weight: 950;
        }

        td {
          border-bottom: 1px solid #dbeafe;
          padding: 10px;
          vertical-align: top;
        }

        tbody tr:nth-child(even) {
          background: #f8fafc;
        }

        .money {
          font-weight: 950;
          white-space: nowrap;
        }

        .chip,
        .status {
          display: inline-flex;
          padding: 6px 10px;
          border-radius: 999px;
          font-size: 11px;
          font-weight: 950;
        }

        .chip.ingreso {
          background: #dcfce7;
          color: #15803d;
        }

        .chip.egreso {
          background: #fee2e2;
          color: #dc2626;
        }

        .status.activo {
          background: #dcfce7;
          color: #15803d;
        }

        .status.anulado {
          background: #fef3c7;
          color: #b45309;
        }

        .actions {
          margin-top: 24px;
          text-align: right;
        }

        .print-btn {
          background: linear-gradient(135deg, #2563eb, #06b6d4);
          color: #ffffff;
          border: none;
          border-radius: 14px;
          padding: 12px 18px;
          font-weight: 950;
          cursor: pointer;
        }

        @media print {
          body {
            background: #ffffff;
            padding: 0;
          }

          .report {
            box-shadow: none;
            border-radius: 0;
          }

          .actions {
            display: none;
          }
        }
      </style>
    </head>

    <body>
      <div class="report">
        <div class="hero">
          <h1>AGUA POTABLE HUACARIZ - REPORTE DE CAJA</h1>
          <p>Sistema de gestión de agua potable - Tesorería y control financiero</p>
        </div>

        <div class="meta">
          <div>Periodo: ${periodo}</div>
          <div>Fecha de emisión: ${fecha}</div>
        </div>

        <div class="content">
          <h2 class="section-title">Resumen financiero</h2>

          <div class="cards">
            <div class="card blue">
              <span>Pagos recibidos</span>
              <strong>S/ ${this.totalRecaudadoPagosPeriodo().toFixed(2)}</strong>
            </div>

            <div class="card green">
              <span>Otros ingresos</span>
              <strong>S/ ${this.totalIngresosManualesPeriodo().toFixed(2)}</strong>
            </div>

            <div class="card red">
              <span>Gastos / retiros</span>
              <strong>S/ ${this.totalEgresosPeriodo().toFixed(2)}</strong>
            </div>

            <div class="card saldo">
              <span>Saldo del periodo</span>
              <strong>S/ ${this.saldoDisponiblePeriodo().toFixed(2)}</strong>
            </div>
          </div>

          <h2 class="section-title">Resumen por categoría</h2>

          <div class="category-grid">
            ${resumenCategoria || '<p>No hay categorías para mostrar.</p>'}
          </div>

          <h2 class="section-title">Detalle de movimientos</h2>

          <table>
            <thead>
              <tr>
                <th>N°</th>
                <th>Fecha</th>
                <th>Tipo</th>
                <th>Categoría</th>
                <th>Detalle</th>
                <th>Responsable</th>
                <th>Monto</th>
                <th>Estado</th>
              </tr>
            </thead>

            <tbody>
              ${filas || '<tr><td colspan="8">Sin movimientos registrados.</td></tr>'}
            </tbody>
          </table>

          <div class="actions">
            <button onclick="window.print()" class="print-btn">
              Imprimir / guardar PDF
            </button>
          </div>
        </div>
      </div>
    </body>
    </html>
  `);

  ventana.document.close();
}

  fechaValida(fecha: string): Date | null {
  if (!fecha) {
    return null;
  }

  const valor = new Date(fecha);

  if (isNaN(valor.getTime())) {
    return null;
  }

  return valor;
}

pertenecePeriodo(fecha: string): boolean {
  const valor = this.fechaValida(fecha);

  if (!valor) {
    return false;
  }

  const coincideAnio =
    this.filtroAnio === 'TODOS' ||
    valor.getFullYear() === Number(this.filtroAnio);

  const coincideMes =
    this.filtroMes === 'TODOS' ||
    valor.getMonth() + 1 === Number(this.filtroMes);

  return coincideAnio && coincideMes;
}

aniosDisponibles(): number[] {
  const aniosMovimientos = this.movimientos
    .map((m) => this.fechaValida(m.fechaMovimiento)?.getFullYear())
    .filter((anio): anio is number => !!anio);

  const aniosPagos = this.pagos
    .map((p) => this.fechaValida(p.fechaPago)?.getFullYear())
    .filter((anio): anio is number => !!anio);

  const actual = new Date().getFullYear();

  return Array.from(new Set([...aniosMovimientos, ...aniosPagos, actual]))
    .sort((a, b) => b - a);
}

nombreMes(valor: number | 'TODOS'): string {
  if (valor === 'TODOS') {
    return 'Todos los meses';
  }

  return this.meses.find((mes) => mes.valor === Number(valor))?.nombre || 'Mes inválido';
}

textoPeriodo(): string {
  const anio = this.filtroAnio === 'TODOS' ? 'Todos los años' : String(this.filtroAnio);
  const mes = this.nombreMes(this.filtroMes);

  return `${mes} - ${anio}`;
}

movimientosActivosPeriodo(): MovimientoCajaResponse[] {
  return this.movimientos.filter((m) => {
    return String(m.estado || '').toUpperCase() === 'ACTIVO' &&
           this.pertenecePeriodo(m.fechaMovimiento);
  });
}

pagosPeriodo(): PagoResponse[] {
  return this.pagos.filter((pago) => {
    return this.esPagoValido(pago) &&
           this.pertenecePeriodo(pago.fechaPago);
  });
}

totalRecaudadoPagosPeriodo(): number {
  return this.pagosPeriodo().reduce((total, pago) => {
    return total + Number(pago.monto || 0);
  }, 0);
}

totalIngresosManualesPeriodo(): number {
  return this.movimientosActivosPeriodo()
    .filter((m) => String(m.tipoMovimiento || '').toUpperCase() === 'INGRESO')
    .reduce((total, m) => total + Number(m.monto || 0), 0);
}

totalEgresosPeriodo(): number {
  return this.movimientosActivosPeriodo()
    .filter((m) => String(m.tipoMovimiento || '').toUpperCase() === 'EGRESO')
    .reduce((total, m) => total + Number(m.monto || 0), 0);
}

totalIngresosPeriodo(): number {
  return this.totalRecaudadoPagosPeriodo() + this.totalIngresosManualesPeriodo();
}

saldoDisponiblePeriodo(): number {
  return this.totalIngresosPeriodo() - this.totalEgresosPeriodo();
}

resumenPorCategoria(): { categoria: string; ingresos: number; egresos: number; saldo: number }[] {
  const resumen: Record<string, { ingresos: number; egresos: number }> = {};

  this.movimientosActivosPeriodo().forEach((m) => {
    const categoria = m.categoria || 'SIN CATEGORÍA';

    if (!resumen[categoria]) {
      resumen[categoria] = {
        ingresos: 0,
        egresos: 0
      };
    }

    const tipo = String(m.tipoMovimiento || '').toUpperCase();

    if (tipo === 'INGRESO') {
      resumen[categoria].ingresos += Number(m.monto || 0);
    }

    if (tipo === 'EGRESO') {
      resumen[categoria].egresos += Number(m.monto || 0);
    }
  });

  return Object.keys(resumen)
    .map((categoria) => ({
      categoria,
      ingresos: resumen[categoria].ingresos,
      egresos: resumen[categoria].egresos,
      saldo: resumen[categoria].ingresos - resumen[categoria].egresos
    }))
    .sort((a, b) => (b.ingresos + b.egresos) - (a.ingresos + a.egresos));
}
}