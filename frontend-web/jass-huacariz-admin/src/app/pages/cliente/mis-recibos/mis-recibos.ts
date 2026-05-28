import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

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
  exito = '';

  busqueda = '';
  filtroEstado = 'TODOS';

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
    this.exito = '';

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
        estado === this.filtroEstado;

      const coincideTexto =
        !texto ||
        String(recibo.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(recibo.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(recibo.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(recibo.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(recibo.sector || '').toLowerCase().includes(texto) ||
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

  consumoPromedio(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return this.consumoTotal() / this.recibos.length;
  }

  totalCargos(recibo: ReciboClienteResponse): number {
    return Number(recibo.cargoMantenimiento || 0) +
      Number(recibo.cargoLector || 0) +
      Number(recibo.cargoOtros || 0) +
      Number(recibo.mora || 0);
  }

  reciboPendienteMasReciente(): ReciboClienteResponse | null {
    const pendientes = this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .sort((a, b) => Number(b.id) - Number(a.id));

    return pendientes.length ? pendientes[0] : null;
  }

  ultimosRecibos(): ReciboClienteResponse[] {
    return [...this.recibos]
      .sort((a, b) => Number(b.id) - Number(a.id))
      .slice(0, 5);
  }

  recibosParaGrafico(): ReciboClienteResponse[] {
    return [...this.recibos]
      .sort((a, b) => Number(a.id) - Number(b.id))
      .slice(-6);
  }

  consumoMaximo(): number {
    if (!this.recibosParaGrafico().length) {
      return 0;
    }

    return Math.max(...this.recibosParaGrafico().map((recibo) => Number(recibo.consumoM3 || 0)));
  }

  anchoConsumo(recibo: ReciboClienteResponse): string {
    const maximo = this.consumoMaximo();

    if (maximo <= 0) {
      return '8%';
    }

    const porcentaje = (Number(recibo.consumoM3 || 0) / maximo) * 100;
    return `${Math.max(porcentaje, 8)}%`;
  }

  porcentajePagados(): number {
    if (!this.totalRecibos()) {
      return 0;
    }

    return (this.recibosPagados() / this.totalRecibos()) * 100;
  }

  porcentajePendientes(): number {
    if (!this.totalRecibos()) {
      return 0;
    }

    return (this.recibosPendientes() / this.totalRecibos()) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.totalRecibos()) {
      return 0;
    }

    return (this.recibosVencidos() / this.totalRecibos()) * 100;
  }

  graficoEstados(): string {
    if (!this.totalRecibos()) {
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

  imprimirRecibo(recibo: ReciboClienteResponse): void {
    imprimirReciboJass(recibo, this.recibos);
  }

  imprimirReporte(): void {
    const filas = this.recibosFiltrados.map((recibo) => `
      <tr>
        <td>${this.textoSeguro(recibo.codigoRecibo)}</td>
        <td>${this.textoSeguro(recibo.codigoSuministro || '-')}</td>
        <td>${this.textoSeguro(recibo.direccionSuministro || '-')}</td>
        <td>${this.periodo(recibo)}</td>
        <td>${Number(recibo.consumoM3 || 0).toFixed(3)} m³</td>
        <td>S/ ${Number(recibo.total || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(recibo.fechaVencimiento || '-')}</td>
        <td>${this.textoSeguro(recibo.estadoRecibo || 'PENDIENTE')}</td>
      </tr>
    `).join('');

    const ventana = window.open('', '_blank', 'width=1200,height=850');

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
          * { box-sizing: border-box; }

          body {
            margin: 0;
            padding: 28px;
            font-family: Arial, Helvetica, sans-serif;
            color: #0f2f44;
            background: #ffffff;
          }

          .header {
            display: flex;
            justify-content: space-between;
            gap: 20px;
            border-bottom: 3px solid #13a8c8;
            padding-bottom: 16px;
            margin-bottom: 20px;
          }

          .brand {
            display: flex;
            gap: 12px;
            align-items: center;
          }

          .logo {
            width: 52px;
            height: 52px;
            border-radius: 14px;
            background: #13a8c8;
            display: grid;
            place-items: center;
            color: white;
            font-size: 25px;
          }

          h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 900;
          }

          p {
            margin: 4px 0;
            color: #64748b;
            font-size: 13px;
          }

          .summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin: 20px 0;
          }

          .card {
            border: 1px solid #dbe7ec;
            border-radius: 12px;
            padding: 12px;
            background: #f8fcfd;
          }

          .card span {
            display: block;
            color: #64748b;
            font-size: 12px;
          }

          .card strong {
            display: block;
            margin-top: 6px;
            font-size: 18px;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
          }

          th {
            background: #e8f7fb;
            padding: 9px;
            border: 1px solid #dbe7ec;
            text-align: left;
          }

          td {
            padding: 8px;
            border: 1px solid #e2eef3;
          }

          .actions {
            margin-top: 18px;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 11px 16px;
            font-weight: 800;
            cursor: pointer;
          }

          .print {
            background: #13a8c8;
            color: white;
          }

          .close {
            background: #e2e8f0;
            color: #0f2f44;
          }

          @media print {
            body { padding: 10px; }
            .actions { display: none; }
            table { font-size: 10px; }
          }
        </style>
      </head>

      <body>
        <div class="header">
          <div class="brand">
            <div class="logo">💧</div>
            <div>
              <h1>JASS Huacariz</h1>
              <p>Reporte de recibos del cliente</p>
              <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
            </div>
          </div>

          <strong>Portal cliente</strong>
        </div>

        <div class="summary">
          <div class="card"><span>Total recibos</span><strong>${this.totalRecibos()}</strong></div>
          <div class="card"><span>Pendientes</span><strong>${this.recibosPendientes()}</strong></div>
          <div class="card"><span>Pagados</span><strong>${this.recibosPagados()}</strong></div>
          <div class="card"><span>Deuda pendiente</span><strong>S/ ${this.totalPendiente().toFixed(2)}</strong></div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Recibo</th>
              <th>Suministro</th>
              <th>Dirección</th>
              <th>Periodo</th>
              <th>Consumo</th>
              <th>Total</th>
              <th>Vencimiento</th>
              <th>Estado</th>
            </tr>
          </thead>

          <tbody>
            ${filas || '<tr><td colspan="8">No hay recibos para mostrar.</td></tr>'}
          </tbody>
        </table>

        <div class="actions">
          <button class="close" onclick="window.close()">Cerrar</button>
          <button class="print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);
    ventana.document.close();
  }

  exportarExcel(): void {
    const data = this.recibosFiltrados.map((recibo) => ({
      'Código recibo': recibo.codigoRecibo || '',
      'Suministro': recibo.codigoSuministro || '',
      'Dirección': recibo.direccionSuministro || '',
      'Alias': recibo.aliasSuministro || '',
      'Sector': recibo.sector || '',
      'Periodo': this.periodo(recibo),
      'Consumo m³': Number(recibo.consumoM3 || 0),
      'Subtotal agua': Number(recibo.subtotalAgua || 0),
      'Mantenimiento': Number(recibo.cargoMantenimiento || 0),
      'Cargo lector': Number(recibo.cargoLector || 0),
      'Otros cargos': Number(recibo.cargoOtros || 0),
      'Mora': Number(recibo.mora || 0),
      'Total': Number(recibo.total || 0),
      'Estado': recibo.estadoRecibo || '',
      'Emisión': recibo.fechaEmision || '',
      'Vencimiento': recibo.fechaVencimiento || '',
      'Código barras': recibo.codigoBarras || ''
    }));

    const worksheet: any = XLSX.utils.json_to_sheet(data.length ? data : [{ Mensaje: 'No hay recibos para exportar' }]);
    const workbook = XLSX.utils.book_new();

    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);

    worksheet['!cols'] = Array.from({ length: range.e.c + 1 }, () => ({ wch: 22 }));
    worksheet['!autofilter'] = { ref };

    const border = {
      top: { style: 'thin', color: { rgb: 'D9EAF0' } },
      bottom: { style: 'thin', color: { rgb: 'D9EAF0' } },
      left: { style: 'thin', color: { rgb: 'D9EAF0' } },
      right: { style: 'thin', color: { rgb: 'D9EAF0' } }
    };

    for (let r = range.s.r; r <= range.e.r; r++) {
      for (let c = range.s.c; c <= range.e.c; c++) {
        const cell = XLSX.utils.encode_cell({ r, c });

        if (!worksheet[cell]) {
          worksheet[cell] = { t: 's', v: '' };
        }

        worksheet[cell].s = {
          border,
          alignment: { vertical: 'center', wrapText: true },
          ...(r === 0
            ? {
                font: { bold: true, color: { rgb: '0F2F44' } },
                fill: { fgColor: { rgb: 'E8F7FB' } },
                alignment: { horizontal: 'center', vertical: 'center', wrapText: true }
              }
            : {})
        };
      }
    }

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Mis recibos');

    const fecha = new Date().toISOString().slice(0, 10);
    XLSX.writeFile(workbook, `mis_recibos_jass_huacariz_${fecha}.xlsx`);
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

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}