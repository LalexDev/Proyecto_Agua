import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

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
          this.recibos = (data || []).sort((a, b) => {
            const periodoA = Number(a.anio || 0) * 100 + Number(a.mes || 0);
            const periodoB = Number(b.anio || 0) * 100 + Number(b.mes || 0);

            if (periodoA !== periodoB) {
              return periodoB - periodoA;
            }

            return Number(b.id) - Number(a.id);
          });

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

  totalCargosRecibo(recibo: ReciboClienteResponse): number {
    return Number(recibo.cargoMantenimiento || 0) +
      Number(recibo.cargoLector || 0) +
      Number(recibo.cargoOtros || 0) +
      Number(recibo.mora || 0);
  }

  imprimirRecibo(recibo: ReciboClienteResponse): void {
    imprimirReciboJass(recibo, this.recibos);
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
          <td>${this.textoSeguro(recibo.aliasSuministro || '-')}</td>
          <td>${this.textoSeguro(recibo.sector || '-')}</td>
          <td>${this.textoSeguro(this.periodo(recibo))}</td>
          <td>${Number(recibo.consumoM3 || 0).toFixed(3)}</td>
          <td>${Number(recibo.subtotalAgua || 0).toFixed(2)}</td>
          <td>${Number(recibo.cargoMantenimiento || 0).toFixed(2)}</td>
          <td>${Number(recibo.cargoLector || 0).toFixed(2)}</td>
          <td>${Number(recibo.cargoOtros || 0).toFixed(2)}</td>
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
            <tr><td class="titulo" colspan="15">JASS HUACARIZ - MIS RECIBOS</td></tr>
            <tr><td colspan="15">Fecha de exportación: ${new Date().toLocaleString('es-PE')}</td></tr>
            <tr>
              <th>Recibo</th>
              <th>Suministro</th>
              <th>Dirección</th>
              <th>Alias</th>
              <th>Sector</th>
              <th>Periodo</th>
              <th>Consumo m³</th>
              <th>Subtotal agua</th>
              <th>Mantenimiento</th>
              <th>Lector</th>
              <th>Otros cargos</th>
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

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}