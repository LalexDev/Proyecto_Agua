import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx';

import {
  HistorialLectura,
  LecturaAdmin
} from '../../../core/services/lectura-admin';

@Component({
  selector: 'app-historial-lecturas',
  imports: [CommonModule, FormsModule],
  templateUrl: './historial-lecturas.html',
  styleUrl: './historial-lecturas.scss',
})
export class HistorialLecturas implements OnInit {
  lecturas: HistorialLectura[] = [];
  lecturasFiltradas: HistorialLectura[] = [];

  busqueda = '';
  filtroAnio: number | '' = '';
  filtroMes: number | '' = '';

  cargando = false;
  error = '';

  constructor(
    private lecturaAdmin: LecturaAdmin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarHistorial();
  }

  cargarHistorial(): void {
    this.cargando = true;
    this.error = '';

    this.lecturaAdmin.listarHistorial()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturas = data || [];
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el historial de lecturas.';
          this.lecturas = [];
          this.lecturasFiltradas = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.lecturasFiltradas = this.lecturas.filter((item) => {
      const coincideTexto =
        !texto ||
        String(item.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(item.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(item.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(item.cliente || '').toLowerCase().includes(texto) ||
        String(item.dniCliente || '').toLowerCase().includes(texto) ||
        String(item.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(item.sector || '').toLowerCase().includes(texto);

      const coincideAnio =
        !this.filtroAnio || Number(item.anio) === Number(this.filtroAnio);

      const coincideMes =
        !this.filtroMes || Number(item.mes) === Number(this.filtroMes);

      return coincideTexto && coincideAnio && coincideMes;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroAnio = '';
    this.filtroMes = '';
    this.aplicarFiltros();
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  totalConsumo(): number {
    return this.lecturasFiltradas.reduce((total, item) => {
      return total + Number(item.consumoM3 || 0);
    }, 0);
  }

  totalEmitido(): number {
    return this.lecturasFiltradas.reduce((total, item) => {
      return total + Number(item.totalRecibo || 0);
    }, 0);
  }

  totalPendientes(): number {
    return this.lecturasFiltradas.filter((item) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  totalPagados(): number {
    return this.lecturasFiltradas.filter((item) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
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

  exportarExcel(): void {
    if (!this.lecturasFiltradas.length) {
      alert('No hay datos para exportar.');
      return;
    }

    const data = this.lecturasFiltradas.map((item) => ({
      'Código suministro': item.codigoSuministro || '',
      'Alias suministro': item.aliasSuministro || '',
      'Dirección': item.direccionSuministro || '',
      'Cliente': item.cliente || '',
      'DNI': item.dniCliente || '',
      'Sector': item.sector || '',
      'Año': item.anio || '',
      'Mes': this.nombreMes(item.mes),
      'Periodo': `${this.nombreMes(item.mes)} ${item.anio}`,
      'Lectura anterior': Number(item.lecturaAnterior || 0),
      'Lectura actual': Number(item.lecturaActual || 0),
      'Consumo m³': Number(item.consumoM3 || 0),
      'Código recibo': item.codigoRecibo || '',
      'Total recibo': Number(item.totalRecibo || 0),
      'Estado recibo': item.estadoRecibo || 'PENDIENTE',
      'Fecha registro': item.fechaRegistro || ''
    }));

    const worksheet = XLSX.utils.json_to_sheet(data);
    const workbook = XLSX.utils.book_new();

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Historial lecturas');

    const fecha = new Date().toISOString().slice(0, 10);
    XLSX.writeFile(workbook, `historial_lecturas_jass_huacariz_${fecha}.xlsx`);
  }

  imprimirReporte(): void {
    if (!this.lecturasFiltradas.length) {
      alert('No hay datos para imprimir.');
      return;
    }

    const filas = this.lecturasFiltradas.map((item) => `
      <tr>
        <td>${this.textoSeguro(item.codigoSuministro)}</td>
        <td>${this.textoSeguro(item.aliasSuministro || item.direccionSuministro || '-')}</td>
        <td>${this.textoSeguro(item.cliente)}</td>
        <td>${this.textoSeguro(item.dniCliente)}</td>
        <td>${this.textoSeguro(item.sector)}</td>
        <td>${this.nombreMes(item.mes)} ${item.anio}</td>
        <td>${Number(item.lecturaAnterior || 0).toFixed(3)} m³</td>
        <td>${Number(item.lecturaActual || 0).toFixed(3)} m³</td>
        <td>${Number(item.consumoM3 || 0).toFixed(3)} m³</td>
        <td>${this.textoSeguro(item.codigoRecibo || '-')}</td>
        <td>S/ ${Number(item.totalRecibo || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(item.estadoRecibo || 'PENDIENTE')}</td>
      </tr>
    `).join('');

    const ventana = window.open('', '_blank', 'width=1200,height=800');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Historial de lecturas - JASS Huacariz</title>

        <style>
          * {
            box-sizing: border-box;
          }

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
            font-size: 11px;
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
            vertical-align: top;
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
            body {
              padding: 10px;
            }

            .actions {
              display: none;
            }

            table {
              font-size: 10px;
            }
          }
        </style>
      </head>

      <body>
        <div class="header">
          <div class="brand">
            <div class="logo">💧</div>
            <div>
              <h1>JASS Huacariz</h1>
              <p>Reporte de historial de lecturas</p>
              <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
            </div>
          </div>

          <div>
            <strong>Administración</strong>
          </div>
        </div>

        <div class="summary">
          <div class="card">
            <span>Total lecturas</span>
            <strong>${this.lecturasFiltradas.length}</strong>
          </div>

          <div class="card">
            <span>Consumo total</span>
            <strong>${this.totalConsumo().toFixed(3)} m³</strong>
          </div>

          <div class="card">
            <span>Total emitido</span>
            <strong>S/ ${this.totalEmitido().toFixed(2)}</strong>
          </div>

          <div class="card">
            <span>Pendientes / Pagados</span>
            <strong>${this.totalPendientes()} / ${this.totalPagados()}</strong>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Suministro</th>
              <th>Alias / Dirección</th>
              <th>Cliente</th>
              <th>DNI</th>
              <th>Sector</th>
              <th>Periodo</th>
              <th>Lectura anterior</th>
              <th>Lectura actual</th>
              <th>Consumo</th>
              <th>Recibo</th>
              <th>Total</th>
              <th>Estado</th>
            </tr>
          </thead>

          <tbody>
            ${filas}
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

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}