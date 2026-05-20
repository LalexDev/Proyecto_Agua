import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePerfilResponse,
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
  perfil: ClientePerfilResponse | null = null;

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDetalle();
  }

  cargarDetalle(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!id || Number.isNaN(id)) {
      this.error = 'No se encontró el identificador del recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';

    forkJoin({
      perfil: this.clientePortal.obtenerMiPerfil(),
      recibos: this.clientePortal.listarMisRecibos()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ perfil, recibos }) => {
          this.perfil = perfil;

          const encontrado = recibos.find(r => Number(r.id) === id);

          if (!encontrado) {
            this.error = 'No se encontró el recibo solicitado.';
            this.recibo = null;
            this.cdr.detectChanges();
            return;
          }

          this.recibo = encontrado;
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del recibo.';
          this.cdr.detectChanges();
        }
      });
  }

  estadoClase(estado: string): string {
    return estado?.toLowerCase() === 'pagado' ? 'pagado' : 'pendiente';
  }

  periodo(): string {
    if (!this.recibo) {
      return '';
    }

    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return `${meses[this.recibo.mes - 1] ?? 'Mes'} ${this.recibo.anio}`;
  }

  nombreCliente(): string {
    if (!this.perfil) {
      return '-';
    }

    return `${this.perfil.nombres} ${this.perfil.apellidos}`;
  }

  puedePagar(): boolean {
    return this.recibo?.estadoRecibo === 'PENDIENTE';
  }

  imprimirRecibo(): void {
    if (!this.recibo) {
      return;
    }

    const recibo = this.recibo;
    const perfil = this.perfil;

    const ventana = window.open('', '_blank', 'width=900,height=700');

    if (!ventana) {
      this.error = 'El navegador bloqueó la ventana de impresión.';
      return;
    }

    const html = `
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
            padding: 30px;
            font-family: Arial, sans-serif;
            color: #0f2f3d;
            background: #f3f7fa;
          }

          .receipt {
            max-width: 820px;
            margin: auto;
            background: white;
            border-radius: 18px;
            padding: 34px;
            border: 1px solid #dbe7ec;
          }

          .top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            border-bottom: 2px solid #e5eef3;
            padding-bottom: 20px;
            margin-bottom: 22px;
          }

          .brand {
            display: flex;
            gap: 14px;
            align-items: center;
          }

          .logo {
            width: 58px;
            height: 58px;
            border-radius: 16px;
            background: #1ba3c7;
            color: white;
            display: grid;
            place-items: center;
            font-size: 28px;
          }

          h1, h2, h3, p {
            margin: 0;
          }

          h1 {
            font-size: 26px;
            letter-spacing: 1px;
          }

          .muted {
            color: #64748b;
            font-size: 13px;
            margin-top: 5px;
          }

          .status {
            padding: 9px 16px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
            text-align: center;
          }

          .pagado {
            background: #dcfce7;
            color: #166534;
          }

          .pendiente {
            background: #fef3c7;
            color: #92400e;
          }

          .receipt-code {
            text-align: right;
          }

          .receipt-code h2 {
            font-size: 22px;
            margin-bottom: 8px;
          }

          .grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 14px;
            margin-bottom: 22px;
          }

          .box {
            background: #f6fafc;
            border-radius: 12px;
            padding: 14px;
          }

          .box span {
            display: block;
            font-size: 12px;
            color: #64748b;
            margin-bottom: 6px;
          }

          .box strong {
            font-size: 14px;
          }

          .section-title {
            font-size: 17px;
            margin: 22px 0 12px;
            color: #0f2f3d;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
          }

          th {
            text-align: left;
            background: #f6fafc;
            padding: 12px;
            color: #64748b;
            font-size: 13px;
          }

          td {
            padding: 12px;
            border-bottom: 1px solid #e8eff3;
            font-size: 14px;
          }

          .right {
            text-align: right;
          }

          .total-row td {
            font-size: 20px;
            font-weight: 900;
            color: #0f2f3d;
            border-bottom: none;
            padding-top: 18px;
          }

          .footer {
            margin-top: 26px;
            padding-top: 18px;
            border-top: 1px dashed #cbd5e1;
            color: #64748b;
            font-size: 12px;
            text-align: center;
            line-height: 1.6;
          }

          .actions {
            max-width: 820px;
            margin: 18px auto 0;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 12px;
            padding: 12px 18px;
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
            body {
              background: white;
              padding: 0;
            }

            .receipt {
              border: none;
              border-radius: 0;
              max-width: 100%;
            }

            .actions {
              display: none;
            }
          }
        </style>
      </head>

      <body>
        <div class="receipt">
          <div class="top">
            <div class="brand">
              <div class="logo">💧</div>
              <div>
                <h1>JASS Huacariz</h1>
                <p class="muted">Servicio de agua potable</p>
                <p class="muted">Comprobante informativo de consumo</p>
              </div>
            </div>

            <div class="receipt-code">
              <h2>${this.textoSeguro(recibo.codigoRecibo)}</h2>
              <div class="status ${this.estadoClase(recibo.estadoRecibo)}">
                ${this.textoSeguro(recibo.estadoRecibo)}
              </div>
            </div>
          </div>

          <h3 class="section-title">Datos del cliente</h3>

          <div class="grid">
            <div class="box">
              <span>Cliente</span>
              <strong>${this.textoSeguro(this.nombreCliente())}</strong>
            </div>

            <div class="box">
              <span>DNI / Usuario</span>
              <strong>${this.textoSeguro(perfil?.dni || perfil?.codigoUsuario || '-')}</strong>
            </div>

            <div class="box">
              <span>Teléfono</span>
              <strong>${this.textoSeguro(perfil?.telefono || '-')}</strong>
            </div>

            <div class="box">
              <span>Correo</span>
              <strong>${this.textoSeguro(perfil?.correo || '-')}</strong>
            </div>
          </div>

          <h3 class="section-title">Datos del suministro</h3>

          <div class="grid">
            <div class="box">
              <span>Código de suministro</span>
              <strong>${this.textoSeguro(recibo.codigoSuministro)}</strong>
            </div>

            <div class="box">
              <span>Dirección</span>
              <strong>${this.textoSeguro(recibo.direccionSuministro)}</strong>
            </div>

            <div class="box">
              <span>Periodo</span>
              <strong>${this.textoSeguro(this.periodo())}</strong>
            </div>

            <div class="box">
              <span>Consumo registrado</span>
              <strong>${Number(recibo.consumoM3).toFixed(2)} m³</strong>
            </div>

            <div class="box">
              <span>Fecha de emisión</span>
              <strong>${this.formatearFecha(recibo.fechaEmision)}</strong>
            </div>

            <div class="box">
              <span>Fecha de vencimiento</span>
              <strong>${this.textoSeguro(recibo.fechaVencimiento)}</strong>
            </div>
          </div>

          <h3 class="section-title">Detalle del importe</h3>

          <table>
            <thead>
              <tr>
                <th>Concepto</th>
                <th class="right">Importe</th>
              </tr>
            </thead>

            <tbody>
              <tr>
                <td>Subtotal agua</td>
                <td class="right">S/ ${Number(recibo.subtotalAgua).toFixed(2)}</td>
              </tr>

              <tr>
                <td>Cargo mantenimiento</td>
                <td class="right">S/ ${Number(recibo.cargoMantenimiento).toFixed(2)}</td>
              </tr>

              <tr>
                <td>Cargo lector</td>
                <td class="right">S/ ${Number(recibo.cargoLector).toFixed(2)}</td>
              </tr>

              <tr>
                <td>Mora</td>
                <td class="right">S/ ${Number(recibo.mora).toFixed(2)}</td>
              </tr>

              <tr class="total-row">
                <td>Total a pagar</td>
                <td class="right">S/ ${Number(recibo.total).toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <div class="footer">
            Documento generado desde el sistema web JASS Huacariz.<br>
            Este comprobante es informativo y resume el consumo registrado en el periodo correspondiente.
          </div>
        </div>

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

  private formatearFecha(fecha: string): string {
    if (!fecha) {
      return '-';
    }

    const date = new Date(fecha);

    if (Number.isNaN(date.getTime())) {
      return fecha;
    }

    return date.toLocaleString('es-PE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
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