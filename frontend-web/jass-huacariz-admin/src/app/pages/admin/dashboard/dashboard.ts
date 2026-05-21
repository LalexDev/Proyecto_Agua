import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { forkJoin, finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import { Cliente, ClienteResponse } from '../../../core/services/cliente';
import { Recibo, ReciboResponse } from '../../../core/services/recibo';
import { Pago, PagoResponse } from '../../../core/services/pago';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, RouterModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class Dashboard implements OnInit {
  clientes: ClienteResponse[] = [];
  recibos: ReciboResponse[] = [];
  pagos: PagoResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clienteService: Cliente,
    private reciboService: Recibo,
    private pagoService: Pago,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDashboard();
  }

  cargarDashboard(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      recibos: this.reciboService.listarRecibos(),
      pagos: this.pagoService.listarPagos()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ clientes, recibos, pagos }) => {
          this.clientes = clientes || [];
          this.recibos = recibos || [];
          this.pagos = pagos || [];
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el dashboard. Verifica el backend y tu sesión ADMIN.';
          this.cdr.detectChanges();
        }
      });
  }

  cerrarSesion(): void {
    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  totalClientes(): number {
    return this.clientes.length;
  }

  totalSuministros(): number {
    return this.clientes.reduce((total, cliente: any) => {
      return total + (cliente.suministros?.length || 0);
    }, 0);
  }

  totalRecibos(): number {
    return this.recibos.length;
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibos.filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  totalPagado(): number {
    return this.pagos.reduce((total, pago: any) => {
      return total + Number(pago.monto || 0);
    }, 0);
  }

  totalEmitido(): number {
    return this.recibos.reduce((total, recibo: any) => {
      return total + Number(recibo.total || 0);
    }, 0);
  }

  saldoPendiente(): number {
    const saldo = this.totalEmitido() - this.totalPagado();
    return saldo < 0 ? 0 : saldo;
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, recibo: any) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  consumoPromedio(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return this.consumoTotal() / this.recibos.length;
  }

  porcentajeRecaudado(): number {
    if (this.totalEmitido() <= 0) {
      return 0;
    }

    return Math.min(100, Math.max(0, (this.totalPagado() / this.totalEmitido()) * 100));
  }

  porcentajePendientes(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosPendientes() / this.totalRecibos()) * 100;
  }

  porcentajePagados(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosPagados() / this.totalRecibos()) * 100;
  }

  porcentajeVencidos(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosVencidos() / this.totalRecibos()) * 100;
  }

  donutCobranza(): string {
    return `conic-gradient(#1ba3c7 ${this.porcentajeRecaudado()}%, #143f50 0)`;
  }

  ultimosRecibos(): ReciboResponse[] {
    return [...this.recibos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 5);
  }

  ultimosPagos(): PagoResponse[] {
    return [...this.pagos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 4);
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

  periodo(recibo: ReciboResponse): string {
    const r: any = recibo;
    return `${this.nombreMes(Number(r.mes))} ${r.anio}`;
  }

  exportarExcel(): void {
    const filas = [
      ['JASS Huacariz'],
      ['Resumen del Dashboard Administrativo'],
      [`Fecha de emisión: ${new Date().toLocaleString('es-PE')}`],
      [],
      ['INDICADORES PRINCIPALES'],
      ['Indicador', 'Valor', '', 'Indicador', 'Valor'],
      ['Total clientes', this.totalClientes(), '', 'Total suministros', this.totalSuministros()],
      ['Total recibos', this.totalRecibos(), '', 'Recibos pendientes', this.recibosPendientes()],
      ['Recibos pagados', this.recibosPagados(), '', 'Recibos vencidos', this.recibosVencidos()],
      ['Total emitido', `S/ ${this.totalEmitido().toFixed(2)}`, '', 'Total pagado', `S/ ${this.totalPagado().toFixed(2)}`],
      ['Saldo pendiente', `S/ ${this.saldoPendiente().toFixed(2)}`, '', 'Consumo promedio', `${this.consumoPromedio().toFixed(3)} m³`],
      [],
      ['ÚLTIMOS RECIBOS'],
      ['Recibo', 'Suministro', 'Periodo', 'Consumo', 'Total', 'Estado'],
      ...this.ultimosRecibos().map((recibo: any) => [
        recibo.codigoRecibo || '-',
        recibo.codigoSuministro || '-',
        `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`,
        `${Number(recibo.consumoM3 || 0).toFixed(3)} m³`,
        `S/ ${Number(recibo.total || 0).toFixed(2)}`,
        recibo.estadoRecibo || '-'
      ])
    ];

    const worksheet: any = XLSX.utils.aoa_to_sheet(filas);

    worksheet['!cols'] = [
      { wch: 26 },
      { wch: 28 },
      { wch: 8 },
      { wch: 26 },
      { wch: 24 },
      { wch: 18 }
    ];

    worksheet['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 5 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 5 } },
      { s: { r: 2, c: 0 }, e: { r: 2, c: 5 } },
      { s: { r: 4, c: 0 }, e: { r: 4, c: 5 } },
      { s: { r: 12, c: 0 }, e: { r: 12, c: 5 } }
    ];

    const estilos = this.estilosExcel();

    this.aplicarEstiloRango(worksheet, 0, 0, filas.length - 1, 5, estilos.celda);
    this.aplicarEstiloRango(worksheet, 0, 0, 0, 5, estilos.titulo);
    this.aplicarEstiloRango(worksheet, 1, 0, 1, 5, estilos.subtitulo);
    this.aplicarEstiloRango(worksheet, 2, 0, 2, 5, estilos.fecha);
    this.aplicarEstiloRango(worksheet, 4, 0, 4, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, 5, 0, 5, 4, estilos.cabeceraTabla);
    this.aplicarEstiloRango(worksheet, 6, 0, 10, 4, estilos.resumen);
    this.aplicarEstiloRango(worksheet, 12, 0, 12, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, 13, 0, 13, 5, estilos.cabeceraTabla);

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Dashboard');

    const fechaArchivo = new Date().toISOString().slice(0, 10);
    XLSX.writeFile(workbook, `dashboard_jass_huacariz_${fechaArchivo}.xlsx`);
  }

  imprimirDashboard(): void {
    const filasRecibos = this.ultimosRecibos().map((recibo: any) => `
      <tr>
        <td>${this.textoSeguro(recibo.codigoRecibo || '-')}</td>
        <td>${this.textoSeguro(recibo.codigoSuministro || '-')}</td>
        <td>${this.nombreMes(Number(recibo.mes))} ${recibo.anio}</td>
        <td>${Number(recibo.consumoM3 || 0).toFixed(3)} m³</td>
        <td>S/ ${Number(recibo.total || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(recibo.estadoRecibo || '-')}</td>
      </tr>
    `).join('');

    const ventana = window.open('', '_blank', 'width=1100,height=800');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Dashboard - JASS Huacariz</title>
        <style>
          * { box-sizing: border-box; }
          body {
            margin: 0;
            padding: 28px;
            font-family: Arial, sans-serif;
            color: #0f2f3d;
            background: #ffffff;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #1ba3c7;
            padding-bottom: 16px;
            margin-bottom: 20px;
          }
          .brand {
            display: flex;
            align-items: center;
            gap: 12px;
          }
          .logo {
            width: 52px;
            height: 52px;
            border-radius: 14px;
            background: #1ba3c7;
            color: white;
            display: grid;
            place-items: center;
            font-size: 26px;
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
            margin-bottom: 22px;
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
            color: #0f2f3d;
            padding: 9px;
            text-align: left;
            border: 1px solid #dbe7ec;
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
            background: #1ba3c7;
            color: white;
          }
          .close {
            background: #e2e8f0;
            color: #0f2f3d;
          }
          @media print {
            body { padding: 10px; }
            .actions { display: none; }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="brand">
            <div class="logo">💧</div>
            <div>
              <h1>JASS Huacariz</h1>
              <p>Resumen del Dashboard Administrativo</p>
              <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
            </div>
          </div>
          <div>
            <strong>Administración</strong>
          </div>
        </div>

        <div class="summary">
          <div class="card"><span>Total clientes</span><strong>${this.totalClientes()}</strong></div>
          <div class="card"><span>Total suministros</span><strong>${this.totalSuministros()}</strong></div>
          <div class="card"><span>Recibos pendientes</span><strong>${this.recibosPendientes()}</strong></div>
          <div class="card"><span>Total pagado</span><strong>S/ ${this.totalPagado().toFixed(2)}</strong></div>
          <div class="card"><span>Total emitido</span><strong>S/ ${this.totalEmitido().toFixed(2)}</strong></div>
          <div class="card"><span>Saldo pendiente</span><strong>S/ ${this.saldoPendiente().toFixed(2)}</strong></div>
          <div class="card"><span>Consumo total</span><strong>${this.consumoTotal().toFixed(3)} m³</strong></div>
          <div class="card"><span>Consumo promedio</span><strong>${this.consumoPromedio().toFixed(3)} m³</strong></div>
        </div>

        <h2>Últimos recibos generados</h2>
        <table>
          <thead>
            <tr>
              <th>Recibo</th>
              <th>Suministro</th>
              <th>Periodo</th>
              <th>Consumo</th>
              <th>Total</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            ${filasRecibos || '<tr><td colspan="6">Sin recibos registrados.</td></tr>'}
          </tbody>
        </table>

        <div class="actions">
          <button class="close" onclick="window.close()">Cerrar</button>
          <button class="print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `;

    ventana.document.open();
    ventana.document.write(html);
    ventana.document.close();
  }

  private nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  private aplicarEstiloRango(
    worksheet: any,
    filaInicio: number,
    columnaInicio: number,
    filaFin: number,
    columnaFin: number,
    estilo: any
  ): void {
    for (let r = filaInicio; r <= filaFin; r++) {
      for (let c = columnaInicio; c <= columnaFin; c++) {
        const celda = XLSX.utils.encode_cell({ r, c });

        if (!worksheet[celda]) {
          worksheet[celda] = { t: 's', v: '' };
        }

        worksheet[celda].s = estilo;
      }
    }
  }

  private estilosExcel(): any {
    const borde = {
      top: { style: 'thin', color: { rgb: 'D9EAF0' } },
      bottom: { style: 'thin', color: { rgb: 'D9EAF0' } },
      left: { style: 'thin', color: { rgb: 'D9EAF0' } },
      right: { style: 'thin', color: { rgb: 'D9EAF0' } }
    };

    return {
      titulo: {
        font: { bold: true, sz: 20, color: { rgb: 'FFFFFF' } },
        fill: { fgColor: { rgb: '0B3A4A' } },
        alignment: { horizontal: 'center', vertical: 'center' },
        border: borde
      },
      subtitulo: {
        font: { bold: true, sz: 13, color: { rgb: '0F2F3D' } },
        fill: { fgColor: { rgb: 'E8F7FB' } },
        alignment: { horizontal: 'center', vertical: 'center' },
        border: borde
      },
      fecha: {
        font: { italic: true, sz: 11, color: { rgb: '64748B' } },
        alignment: { horizontal: 'center', vertical: 'center' },
        border: borde
      },
      seccion: {
        font: { bold: true, sz: 13, color: { rgb: 'FFFFFF' } },
        fill: { fgColor: { rgb: '1BA3C7' } },
        alignment: { horizontal: 'left', vertical: 'center' },
        border: borde
      },
      cabeceraTabla: {
        font: { bold: true, color: { rgb: 'FFFFFF' } },
        fill: { fgColor: { rgb: '0F766E' } },
        alignment: { horizontal: 'center', vertical: 'center' },
        border: borde
      },
      resumen: {
        font: { color: { rgb: '0F2F3D' } },
        fill: { fgColor: { rgb: 'F8FCFD' } },
        alignment: { vertical: 'center' },
        border: borde
      },
      celda: {
        font: { color: { rgb: '0F2F3D' } },
        alignment: { vertical: 'center' },
        border: borde
      }
    };
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