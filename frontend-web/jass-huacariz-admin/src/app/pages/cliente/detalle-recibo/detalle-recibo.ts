import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-detalle-recibo',
  imports: [CommonModule, RouterModule],
  templateUrl: './detalle-recibo.html',
  styleUrl: './detalle-recibo.scss',
})
export class DetalleRecibo implements OnInit {
  recibo: ReciboClienteResponse | null = null;

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDetalle();
  }

  cargarDetalle(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!id) {
      this.error = 'No se encontró el identificador del recibo.';
      return;
    }

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
          const recibos = data || [];
          this.recibo = recibos.find((item) => Number(item.id) === id) || null;

          if (!this.recibo) {
            this.error = 'No se encontró el recibo solicitado.';
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del recibo.';
          this.recibo = null;
          this.cdr.detectChanges();
        }
      });
  }

  volver(): void {
    this.router.navigate(['/cliente/mis-recibos']);
  }

  irPagar(): void {
    if (!this.recibo) {
      return;
    }

    this.router.navigate(['/cliente/pagar-recibo', this.recibo.id]);
  }

  puedePagar(): boolean {
    if (!this.recibo) {
      return false;
    }

    return String(this.recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
  }

  periodo(): string {
    if (!this.recibo) {
      return '-';
    }

    return `${this.nombreMes(Number(this.recibo.mes))} ${this.recibo.anio}`;
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

  totalCargos(): number {
    if (!this.recibo) {
      return 0;
    }

    return Number(this.recibo.cargoMantenimiento || 0) +
      Number(this.recibo.cargoLector || 0) +
      Number(this.recibo.mora || 0);
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  imprimirRecibo(): void {
    if (!this.recibo) {
      return;
    }

    const recibo = this.recibo;
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
          * { box-sizing: border-box; }

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
          }

          .total-row.final strong {
            font-size: 28px;
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
            body { background: #ffffff; }
            .top-actions { display: none; }

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
              <strong>${this.textoSeguro(this.periodo())}</strong>
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
              <div class="bars">${barrasHtml}</div>
            </div>
          </section>

          <section class="reading-grid">
            <div><span>Periodo</span><strong>${this.textoSeguro(this.periodo())}</strong></div>
            <div><span>Consumo</span><strong>${consumo.toFixed(3)} m³</strong></div>
            <div><span>Emisión</span><strong>${this.textoSeguro(recibo.fechaEmision || '-')}</strong></div>
            <div><span>Vencimiento</span><strong>${this.textoSeguro(recibo.fechaVencimiento || '-')}</strong></div>
            <div><span>Total</span><strong>S/ ${total.toFixed(2)}</strong></div>
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

              <div class="barcode">${codigoBarra}</div>

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