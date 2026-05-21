import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-mis-recibos',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './mis-recibos.html',
  styleUrl: './mis-recibos.scss',
})
export class MisRecibos implements OnInit {
  recibos: ReciboClienteResponse[] = [];
  recibosFiltrados: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  filtroEstado = 'TODOS';
  busqueda = '';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarRecibos();
  }

  cargarRecibos(): void {
    this.cargando = true;
    this.error = '';

    this.clientePortal.listarMisRecibos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.recibos = (data || []).sort((a, b) => Number(b.id) - Number(a.id));
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar tus recibos.';
          this.recibos = [];
          this.recibosFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.recibosFiltrados = this.recibos.filter((recibo) => {
      const estado = String(recibo.estadoRecibo || '').toUpperCase();

      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        this.filtroEstado === '' ||
        estado === this.filtroEstado;

      const coincideTexto =
        !texto ||
        String(recibo.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(recibo.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(recibo.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(recibo.estadoRecibo || '').toLowerCase().includes(texto) ||
        String(recibo.total || '').toLowerCase().includes(texto) ||
        String(recibo.consumoM3 || '').toLowerCase().includes(texto) ||
        this.periodo(recibo).toLowerCase().includes(texto);

      return coincideEstado && coincideTexto;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = 'TODOS';
    this.aplicarFiltros();
  }

  totalRecibos(): number {
    return this.recibos.length;
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  totalPendiente(): number {
    return this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  totalPagado(): number {
    return this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, recibo) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  reciboPendienteMasReciente(): ReciboClienteResponse | null {
    const pendientes = this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .sort((a, b) => Number(b.id) - Number(a.id));

    return pendientes.length ? pendientes[0] : null;
  }

  porcentajePagados(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPagados() / this.recibos.length) * 100;
  }

  porcentajePendientes(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibos.length) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosVencidos() / this.recibos.length) * 100;
  }

  graficoEstados(): string {
    if (!this.recibos.length) {
      return 'conic-gradient(#e2e8f0 0% 100%)';
    }

    const pagados = this.porcentajePagados();
    const pendientes = this.porcentajePendientes();
    const vencidos = this.porcentajeVencidos();

    const finPagados = pagados;
    const finPendientes = pagados + pendientes;
    const finVencidos = pagados + pendientes + vencidos;

    return `
      conic-gradient(
        #16a34a 0% ${finPagados}%,
        #f59e0b ${finPagados}% ${finPendientes}%,
        #dc2626 ${finPendientes}% ${finVencidos}%,
        #e2e8f0 ${finVencidos}% 100%
      )
    `;
  }

  estadoClase(estado: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    return 'pendiente';
  }

  puedePagar(recibo: ReciboClienteResponse): boolean {
    return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
  }

  periodo(recibo: ReciboClienteResponse): string {
    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  exportarExcel(): void {
    const fecha = new Date().toISOString().slice(0, 10);
    const data = this.recibosFiltrados.length ? this.recibosFiltrados : this.recibos;

    let filas = '';

    data.forEach((recibo) => {
      filas += `
        <tr>
          <td>${this.textoSeguro(recibo.codigoRecibo)}</td>
          <td>${this.textoSeguro(recibo.codigoSuministro)}</td>
          <td>${this.textoSeguro(recibo.direccionSuministro)}</td>
          <td>${this.textoSeguro(this.periodo(recibo))}</td>
          <td>${Number(recibo.consumoM3 || 0).toFixed(3)}</td>
          <td>${Number(recibo.subtotalAgua || 0).toFixed(2)}</td>
          <td>${Number(recibo.cargoMantenimiento || 0).toFixed(2)}</td>
          <td>${Number(recibo.cargoLector || 0).toFixed(2)}</td>
          <td>${Number(recibo.mora || 0).toFixed(2)}</td>
          <td>${Number(recibo.total || 0).toFixed(2)}</td>
          <td>${this.textoSeguro(recibo.fechaVencimiento || '-')}</td>
          <td>${this.textoSeguro(recibo.estadoRecibo || '-')}</td>
        </tr>
      `;
    });

    const html = `
      <html>
        <head>
          <meta charset="UTF-8">
          <style>
            table { border-collapse: collapse; width: 100%; font-family: Arial; }
            th { background: #07384A; color: white; font-weight: bold; padding: 10px; border: 1px solid #dbe7ec; }
            td { padding: 9px; border: 1px solid #dbe7ec; }
            .titulo { background: #1BA3C7; color: white; font-size: 18px; font-weight: bold; text-align: center; }
          </style>
        </head>
        <body>
          <table>
            <tr><td class="titulo" colspan="12">JASS HUACARIZ - MIS RECIBOS</td></tr>
            <tr><td colspan="12">Fecha de exportación: ${new Date().toLocaleString('es-PE')}</td></tr>
            <tr>
              <th>Recibo</th>
              <th>Suministro</th>
              <th>Dirección</th>
              <th>Periodo</th>
              <th>Consumo m³</th>
              <th>Subtotal agua</th>
              <th>Mantenimiento</th>
              <th>Lector</th>
              <th>Mora</th>
              <th>Total</th>
              <th>Vencimiento</th>
              <th>Estado</th>
            </tr>
            ${filas}
          </table>
        </body>
      </html>
    `;

    const blob = new Blob([html], {
      type: 'application/vnd.ms-excel;charset=utf-8;'
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.href = url;
    link.download = `mis_recibos_jass_huacariz_${fecha}.xls`;
    link.click();

    URL.revokeObjectURL(url);
  }

  imprimirReporte(): void {
    const data = this.recibosFiltrados.length ? this.recibosFiltrados : this.recibos;

    let filas = '';

    data.forEach((recibo) => {
      filas += `
        <tr>
          <td>${this.textoSeguro(recibo.codigoRecibo)}</td>
          <td>${this.textoSeguro(recibo.codigoSuministro)}</td>
          <td>${this.textoSeguro(this.periodo(recibo))}</td>
          <td>${Number(recibo.consumoM3 || 0).toFixed(3)} m³</td>
          <td>S/ ${Number(recibo.total || 0).toFixed(2)}</td>
          <td>${this.textoSeguro(recibo.fechaVencimiento || '-')}</td>
          <td>${this.textoSeguro(recibo.estadoRecibo || '-')}</td>
        </tr>
      `;
    });

    const ventana = window.open('', '_blank', 'width=1200,height=800');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Mis recibos - JASS Huacariz</title>
        <style>
          body {
            font-family: Arial, Helvetica, sans-serif;
            padding: 24px;
            color: #0f2f44;
          }

          .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #1ba3c7;
            padding-bottom: 16px;
            margin-bottom: 20px;
          }

          h1 {
            margin: 0;
            font-size: 24px;
          }

          p {
            margin: 4px 0;
            color: #64748b;
          }

          .summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            margin-bottom: 18px;
          }

          .box {
            border: 1px solid #dbe7ec;
            border-radius: 10px;
            padding: 10px;
          }

          .box span {
            display: block;
            color: #64748b;
            font-size: 12px;
          }

          .box strong {
            font-size: 18px;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
          }

          th {
            background: #e8f7fb;
            color: #0f2f44;
            padding: 9px;
            border: 1px solid #dbe7ec;
            text-align: left;
          }

          td {
            padding: 8px;
            border: 1px solid #dbe7ec;
          }

          .actions {
            margin-top: 18px;
            text-align: right;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 11px 16px;
            font-weight: 800;
            cursor: pointer;
            background: #1ba3c7;
            color: white;
          }

          @media print {
            .actions {
              display: none;
            }
          }
        </style>
      </head>

      <body>
        <div class="header">
          <div>
            <h1>JASS Huacariz</h1>
            <p>Reporte de mis recibos</p>
            <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
          </div>
          <strong>Portal cliente</strong>
        </div>

        <div class="summary">
          <div class="box"><span>Total recibos</span><strong>${this.totalRecibos()}</strong></div>
          <div class="box"><span>Pendientes</span><strong>${this.recibosPendientes()}</strong></div>
          <div class="box"><span>Pagados</span><strong>${this.recibosPagados()}</strong></div>
          <div class="box"><span>Deuda</span><strong>S/ ${this.totalPendiente().toFixed(2)}</strong></div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Recibo</th>
              <th>Suministro</th>
              <th>Periodo</th>
              <th>Consumo</th>
              <th>Total</th>
              <th>Vencimiento</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            ${filas || '<tr><td colspan="7">No hay recibos registrados.</td></tr>'}
          </tbody>
        </table>

        <div class="actions">
          <button onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);
    ventana.document.close();
  }

  imprimirRecibo(recibo: ReciboClienteResponse): void {
    const ventana = window.open('', '_blank', 'width=1100,height=900');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const consumo = Number(recibo.consumoM3 || 0);
    const total = Number(recibo.total || 0);
    const subtotalAgua = Number(recibo.subtotalAgua || 0);
    const mantenimiento = Number(recibo.cargoMantenimiento || 0);
    const lector = Number(recibo.cargoLector || 0);
    const mora = Number(recibo.mora || 0);
    const cargos = mantenimiento + lector + mora;

    const barrasConsumo = [45, 30, 58, 42, 66, 34, 50, 71, 44, 63, 52, 47];

    const barrasHtml = barrasConsumo.map((alto, index) => {
      const color = index % 2 === 0 ? '#111827' : '#1ba3c7';
      return `<span style="height:${alto}px;background:${color}"></span>`;
    }).join('');

    const codigoBarra = String(recibo.codigoRecibo || 'RECIBO')
      .split('')
      .map((_, index) => {
        const ancho = index % 3 === 0 ? 4 : index % 2 === 0 ? 2 : 1;
        return `<i style="width:${ancho}px"></i>`;
      })
      .join('');

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Recibo ${this.textoSeguro(recibo.codigoRecibo)}</title>

        <style>
          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            background: #edf4f7;
            font-family: Arial, Helvetica, sans-serif;
            color: #0f2f44;
          }

          .top-actions {
            width: 920px;
            margin: 18px auto 10px;
            display: flex;
            justify-content: center;
            gap: 12px;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 11px 18px;
            font-weight: 900;
            cursor: pointer;
            font-size: 13px;
          }

          .download {
            background: #1ba3c7;
            color: white;
          }

          .print {
            background: #ffffff;
            color: #0f2f44;
            border: 1px solid #cfe5ee;
          }

          .receipt-page {
            width: 920px;
            min-height: 1180px;
            margin: 0 auto 30px;
            background: #f9fdff;
            border: 3px solid #148aad;
            padding: 22px;
            box-shadow: 0 20px 50px rgba(15, 47, 68, 0.18);
          }

          .receipt-header {
            display: grid;
            grid-template-columns: 1fr 190px;
            gap: 18px;
            border-bottom: 2px solid #b9dde8;
            padding-bottom: 14px;
            margin-bottom: 14px;
          }

          .brand {
            display: flex;
            align-items: center;
            gap: 12px;
          }

          .brand-logo {
            width: 52px;
            height: 52px;
            border-radius: 12px;
            background: #e8f7fb;
            display: grid;
            place-items: center;
            font-size: 30px;
            border: 1px solid #b9dde8;
          }

          .brand h1 {
            margin: 0;
            letter-spacing: 2px;
            color: #148aad;
            font-size: 28px;
            font-weight: 900;
          }

          .brand p {
            margin: 3px 0 0;
            color: #64748b;
            font-size: 12px;
            font-weight: 700;
          }

          .period-box {
            border: 1px solid #d8d395;
            background: #fff176;
            padding: 10px;
            text-align: center;
          }

          .period-box span {
            display: block;
            font-size: 12px;
            color: #64748b;
            font-weight: 800;
          }

          .period-box strong {
            display: block;
            margin-top: 3px;
            color: #0f2f44;
            font-size: 18px;
            font-weight: 900;
          }

          .top-info {
            display: grid;
            grid-template-columns: 1.2fr 1fr;
            gap: 12px;
            margin-bottom: 12px;
          }

          .box {
            border: 1px solid #b9dde8;
            background: #f6fbfd;
            padding: 12px;
            min-height: 118px;
          }

          .box-title {
            display: block;
            font-weight: 900;
            color: #0f2f44;
            margin-bottom: 8px;
            font-size: 14px;
          }

          .info-line {
            display: grid;
            grid-template-columns: 120px 1fr;
            gap: 8px;
            font-size: 12px;
            margin: 5px 0;
          }

          .info-line span {
            color: #64748b;
            font-weight: 800;
          }

          .info-line strong {
            color: #0f2f44;
            font-weight: 900;
          }

          .chart-box {
            border: 1px solid #b9dde8;
            background: #f6fbfd;
            padding: 12px;
          }

          .chart-title {
            font-size: 12px;
            font-weight: 900;
            text-align: center;
            margin-bottom: 8px;
          }

          .bars {
            height: 88px;
            display: flex;
            align-items: flex-end;
            justify-content: center;
            gap: 8px;
            border-bottom: 2px solid #94b9c4;
            padding: 0 8px;
          }

          .bars span {
            width: 20px;
            display: block;
            border-radius: 4px 4px 0 0;
          }

          .reading-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            border: 1px solid #b9dde8;
            margin-bottom: 12px;
          }

          .reading-grid div {
            padding: 9px;
            border-right: 1px solid #b9dde8;
            background: #f6fbfd;
          }

          .reading-grid div:last-child {
            border-right: none;
          }

          .reading-grid span {
            display: block;
            font-size: 11px;
            color: #64748b;
            font-weight: 800;
            margin-bottom: 5px;
          }

          .reading-grid strong {
            font-size: 13px;
            color: #0f2f44;
            font-weight: 900;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
            font-size: 12px;
          }

          th {
            background: #e8f7fb;
            color: #0f2f44;
            padding: 9px;
            border: 1px solid #b9dde8;
            font-weight: 900;
            text-align: left;
          }

          td {
            padding: 9px;
            border: 1px solid #b9dde8;
            background: #fbfeff;
          }

          .money {
            text-align: right;
            font-weight: 900;
          }

          .bottom-layout {
            display: grid;
            grid-template-columns: 1fr 270px;
            gap: 14px;
            align-items: end;
          }

          .notes {
            border: 1px solid #b9dde8;
            background: #f6fbfd;
            padding: 12px;
            min-height: 118px;
            font-size: 12px;
            color: #0f2f44;
            line-height: 1.45;
          }

          .notes strong {
            display: block;
            margin-bottom: 6px;
          }

          .barcode {
            margin-top: 14px;
            height: 66px;
            background: #ffffff;
            border: 1px solid #d7e9ef;
            display: flex;
            align-items: center;
            gap: 2px;
            padding: 8px;
            overflow: hidden;
          }

          .barcode i {
            height: 48px;
            background: #111827;
            display: block;
          }

          .barcode-text {
            text-align: center;
            font-size: 11px;
            color: #64748b;
            font-weight: 800;
            margin-top: 5px;
          }

          .total-box {
            border: 2px solid #148aad;
            background: #ffffff;
          }

          .total-row {
            display: grid;
            grid-template-columns: 1fr 1.5fr;
            border-bottom: 1px solid #b9dde8;
          }

          .total-row:last-child {
            border-bottom: none;
          }

          .total-row span {
            padding: 10px;
            background: #e8f7fb;
            font-weight: 900;
            font-size: 12px;
          }

          .total-row strong {
            padding: 10px;
            text-align: right;
            font-size: 14px;
          }

          .total-row.final span {
            background: #fff176;
            color: #0f2f44;
          }

          .total-row.final strong {
            font-size: 28px;
            color: #0f2f44;
          }

          .footer {
            margin-top: 16px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            font-size: 11px;
            color: #64748b;
          }

          .footer div {
            border: 1px solid #b9dde8;
            background: #f6fbfd;
            padding: 10px;
          }

          @media print {
            body {
              background: #ffffff;
            }

            .top-actions {
              display: none;
            }

            .receipt-page {
              width: 100%;
              min-height: auto;
              margin: 0;
              box-shadow: none;
              border: 3px solid #148aad;
            }
          }
        </style>
      </head>

      <body>
        <div class="top-actions">
          <button class="download" onclick="window.print()">Descargar PDF</button>
          <button class="print" onclick="window.print()">Imprimir</button>
        </div>

        <main class="receipt-page">
          <section class="receipt-header">
            <div class="brand">
              <div class="brand-logo">💧</div>

              <div>
                <h1>JASS HUACARIZ</h1>
                <p>Servicio de agua potable · Recibo de cobranza</p>
                <p>Cajamarca, Perú · Sistema de Gestión de Agua</p>
              </div>
            </div>

            <div class="period-box">
              <span>PERIODO DE FACTURACIÓN</span>
              <strong>${this.textoSeguro(this.periodo(recibo))}</strong>
            </div>
          </section>

          <section class="top-info">
            <div class="box">
              <span class="box-title">Datos del servicio</span>

              <div class="info-line">
                <span>Recibo:</span>
                <strong>${this.textoSeguro(recibo.codigoRecibo)}</strong>
              </div>

              <div class="info-line">
                <span>Suministro:</span>
                <strong>${this.textoSeguro(recibo.codigoSuministro)}</strong>
              </div>

              <div class="info-line">
                <span>Dirección:</span>
                <strong>${this.textoSeguro(recibo.direccionSuministro)}</strong>
              </div>

              <div class="info-line">
                <span>Estado:</span>
                <strong>${this.textoSeguro(recibo.estadoRecibo || 'PENDIENTE')}</strong>
              </div>
            </div>

            <div class="chart-box">
              <div class="chart-title">Historial gráfico de consumo referencial</div>

              <div class="bars">
                ${barrasHtml}
              </div>
            </div>
          </section>

          <section class="reading-grid">
            <div>
              <span>Periodo</span>
              <strong>${this.textoSeguro(this.periodo(recibo))}</strong>
            </div>

            <div>
              <span>Consumo</span>
              <strong>${consumo.toFixed(3)} m³</strong>
            </div>

            <div>
              <span>Emisión</span>
              <strong>${this.textoSeguro(recibo.fechaEmision || '-')}</strong>
            </div>

            <div>
              <span>Vencimiento</span>
              <strong>${this.textoSeguro(recibo.fechaVencimiento || '-')}</strong>
            </div>

            <div>
              <span>Total</span>
              <strong>S/ ${total.toFixed(2)}</strong>
            </div>
          </section>

          <table>
            <thead>
              <tr>
                <th>Concepto</th>
                <th>Descripción</th>
                <th>Importe</th>
              </tr>
            </thead>

            <tbody>
              <tr>
                <td>Consumo de agua</td>
                <td>Consumo registrado: ${consumo.toFixed(3)} m³</td>
                <td class="money">S/ ${subtotalAgua.toFixed(2)}</td>
              </tr>

              <tr>
                <td>Mantenimiento</td>
                <td>Cargo de mantenimiento del sistema</td>
                <td class="money">S/ ${mantenimiento.toFixed(2)}</td>
              </tr>

              <tr>
                <td>Lector</td>
                <td>Cargo por registro de lectura</td>
                <td class="money">S/ ${lector.toFixed(2)}</td>
              </tr>

              <tr>
                <td>Mora</td>
                <td>Cargo por vencimiento, si corresponde</td>
                <td class="money">S/ ${mora.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <section class="bottom-layout">
            <div>
              <div class="notes">
                <strong>Estimado usuario:</strong>
                Cumpla con realizar sus pagos antes de la fecha de vencimiento para evitar mora,
                suspensión del servicio o restricciones administrativas. Conserve este recibo como
                constancia de cobranza del servicio de agua potable.
              </div>

              <div class="barcode">
                ${codigoBarra}
              </div>

              <div class="barcode-text">
                ${this.textoSeguro(recibo.codigoRecibo)} · ${this.textoSeguro(recibo.codigoSuministro)}
              </div>
            </div>

            <div class="total-box">
              <div class="total-row">
                <span>Subtotal agua</span>
                <strong>S/ ${subtotalAgua.toFixed(2)}</strong>
              </div>

              <div class="total-row">
                <span>Cargos</span>
                <strong>S/ ${cargos.toFixed(2)}</strong>
              </div>

              <div class="total-row final">
                <span>Total a pagar</span>
                <strong>S/ ${total.toFixed(2)}</strong>
              </div>

              <div class="total-row">
                <span>Vence</span>
                <strong>${this.textoSeguro(recibo.fechaVencimiento || '-')}</strong>
              </div>
            </div>
          </section>

          <section class="footer">
            <div>
              <strong>Atención:</strong>
              Este documento es emitido por el sistema de gestión de agua JASS Huacariz.
            </div>

            <div>
              <strong>Validación:</strong>
              Código de recibo ${this.textoSeguro(recibo.codigoRecibo)} · Suministro ${this.textoSeguro(recibo.codigoSuministro)}.
            </div>
          </section>
        </main>
      </body>
      </html>
    `);

    ventana.document.close();
  }

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}