import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import {
  HistorialLectura,
  LecturaAdmin
} from '../../../core/services/lectura-admin';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

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

  lecturaSeleccionada: any = null;

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
          this.error = 'No se pudo cargar el historial de lecturas. Verifica el backend y tu sesión ADMIN.';
          this.lecturas = [];
          this.lecturasFiltradas = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.lecturasFiltradas = this.lecturas.filter((item: any) => {
      const coincideTexto =
        !texto ||
        String(item.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(item.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(item.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(item.cliente || '').toLowerCase().includes(texto) ||
        String(item.nombreCliente || '').toLowerCase().includes(texto) ||
        String(item.dniCliente || '').toLowerCase().includes(texto) ||
        String(item.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(item.sector || '').toLowerCase().includes(texto) ||
        String(item.estadoRecibo || '').toLowerCase().includes(texto);

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

  abrirDetalleLectura(item: any): void {
    this.lecturaSeleccionada = item;
  }

  cerrarDetalleLectura(): void {
    this.lecturaSeleccionada = null;
  }

  imprimirReciboLectura(item: any): void {
    if (!item || !item.codigoRecibo) {
      alert('Esta lectura no tiene recibo asociado para imprimir.');
      return;
    }

    const reciboTemporal: any = {
      codigoRecibo: item.codigoRecibo,
      codigoSuministro: item.codigoSuministro,
      direccionSuministro: item.direccionSuministro || item.aliasSuministro || '-',
      aliasSuministro: item.aliasSuministro || '',
      sector: item.sector || '-',
      nombreCliente: item.nombreCliente || item.cliente || 'No disponible',
      dniCliente: item.dniCliente || '-',
      anio: item.anio,
      mes: item.mes,
      consumoM3: item.consumoM3 || 0,
      subtotalAgua: item.subtotalAgua || item.totalAgua || 0,
      cargoMantenimiento: item.cargoMantenimiento || 0,
      cargoLector: item.cargoLector || 0,
      cargoOtros: item.cargoOtros || 0,
      mora: item.mora || 0,
      total: item.totalRecibo || item.total || 0,
      estadoRecibo: item.estadoRecibo || 'PENDIENTE',
      fechaEmision: item.fechaEmision || item.fechaLectura || '-',
      fechaVencimiento: item.fechaVencimiento || '-',
      codigoBarras: item.codigoBarras || `${item.codigoRecibo || ''}-${item.codigoSuministro || ''}`
    };

    imprimirReciboJass(reciboTemporal, this.lecturas);
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  totalConsumo(): number {
    return this.lecturasFiltradas.reduce((total: number, item: any) => {
      return total + Number(item.consumoM3 || 0);
    }, 0);
  }

  totalEmitido(): number {
    return this.lecturasFiltradas.reduce((total: number, item: any) => {
      return total + Number(item.totalRecibo || item.total || 0);
    }, 0);
  }

  totalPendientes(): number {
    return this.lecturasFiltradas.filter((item: any) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  totalPagados(): number {
    return this.lecturasFiltradas.filter((item: any) => {
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
    const fechaArchivo = new Date().toISOString().slice(0, 10);
    const fechaTexto = new Date().toLocaleString('es-PE');

    const data: any[][] = [];

    data.push(['JASS HUACARIZ - HISTORIAL DE LECTURAS']);
    data.push([`Fecha de exportación: ${fechaTexto}`]);
    data.push([]);

    const resumenTituloRow = data.length;
    data.push(['RESUMEN GENERAL']);

    const resumenHeaderRow = data.length;
    data.push(['Indicador', 'Valor', '', 'Indicador', 'Valor']);

    data.push(['Lecturas registradas', this.lecturasFiltradas.length, '', 'Pendientes', this.totalPendientes()]);
    data.push(['Consumo total m³', Number(this.totalConsumo().toFixed(3)), '', 'Pagados', this.totalPagados()]);
    data.push([
      'Total emitido S/',
      Number(this.totalEmitido().toFixed(2)),
      '',
      'Filtros aplicados',
      `${this.filtroMes ? this.nombreMes(Number(this.filtroMes)) : 'Todos los meses'} / ${this.filtroAnio || 'Todos los años'}`
    ]);
    data.push([]);

    const detalleTituloRow = data.length;
    data.push(['DETALLE DE LECTURAS']);

    const headerRow = data.length;
    data.push([
      'Suministro',
      'Alias',
      'Dirección',
      'Cliente',
      'DNI',
      'Sector',
      'Periodo',
      'Lectura anterior',
      'Lectura actual',
      'Consumo m³',
      'Recibo',
      'Total S/',
      'Estado'
    ]);

    const firstDataRow = data.length;

    this.lecturasFiltradas.forEach((item: any) => {
      data.push([
        item.codigoSuministro || '',
        item.aliasSuministro || '',
        item.direccionSuministro || '',
        item.nombreCliente || item.cliente || '',
        item.dniCliente || '',
        item.sector || '',
        `${this.nombreMes(Number(item.mes))} ${item.anio}`,
        Number(item.lecturaAnterior || 0),
        Number(item.lecturaActual || 0),
        Number(item.consumoM3 || 0),
        item.codigoRecibo || '-',
        Number(item.totalRecibo || item.total || 0),
        item.estadoRecibo || 'PENDIENTE'
      ]);
    });

    if (this.lecturasFiltradas.length === 0) {
      data.push(['No hay lecturas registradas']);
    }

    const ws: any = XLSX.utils.aoa_to_sheet(data);

    ws['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 12 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 12 } },
      { s: { r: resumenTituloRow, c: 0 }, e: { r: resumenTituloRow, c: 12 } },
      { s: { r: detalleTituloRow, c: 0 }, e: { r: detalleTituloRow, c: 12 } }
    ];

    ws['!cols'] = [
      { wch: 18 },
      { wch: 22 },
      { wch: 30 },
      { wch: 28 },
      { wch: 14 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 15 },
      { wch: 18 },
      { wch: 14 },
      { wch: 14 }
    ];

    const border: any = {
      top: { style: 'thin', color: { rgb: 'D9E6EC' } },
      bottom: { style: 'thin', color: { rgb: 'D9E6EC' } },
      left: { style: 'thin', color: { rgb: 'D9E6EC' } },
      right: { style: 'thin', color: { rgb: 'D9E6EC' } }
    };

    const tituloStyle: any = {
      font: { bold: true, sz: 18, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '07384A' } },
      alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
      border
    };

    const subtituloStyle: any = {
      font: { bold: true, sz: 11, color: { rgb: '64748B' } },
      alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
      border
    };

    const seccionStyle: any = {
      font: { bold: true, sz: 13, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '1BA3C7' } },
      alignment: { horizontal: 'left', vertical: 'center', wrapText: true },
      border
    };

    const headerStyle: any = {
      font: { bold: true, color: { rgb: '0F2F3D' } },
      fill: { fgColor: { rgb: 'E8F7FB' } },
      alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
      border
    };

    const normalStyle: any = {
      alignment: { vertical: 'center', wrapText: true },
      border
    };

    const moneyStyle: any = {
      alignment: { vertical: 'center', wrapText: true },
      numFmt: '"S/ "#,##0.00',
      border
    };

    const numberStyle: any = {
      alignment: { vertical: 'center', wrapText: true },
      numFmt: '#,##0.000',
      border
    };

    const setStyle = (row: number, col: number, style: any): void => {
      const ref = XLSX.utils.encode_cell({ r: row, c: col });

      if (!ws[ref]) {
        ws[ref] = { t: 's', v: '' };
      }

      ws[ref].s = style;
    };

    const styleRow = (row: number, fromCol: number, toCol: number, style: any): void => {
      for (let col = fromCol; col <= toCol; col++) {
        setStyle(row, col, style);
      }
    };

    styleRow(0, 0, 12, tituloStyle);
    styleRow(1, 0, 12, subtituloStyle);
    styleRow(resumenTituloRow, 0, 12, seccionStyle);
    styleRow(detalleTituloRow, 0, 12, seccionStyle);
    styleRow(resumenHeaderRow, 0, 4, headerStyle);
    styleRow(headerRow, 0, 12, headerStyle);

    for (let row = resumenHeaderRow + 1; row <= resumenHeaderRow + 3; row++) {
      for (let col = 0; col <= 4; col++) {
        setStyle(row, col, {
          ...normalStyle,
          font: col === 0 || col === 3
            ? { bold: true, color: { rgb: '0F2F3D' } }
            : { color: { rgb: '0F2F3D' } },
          fill: { fgColor: { rgb: row % 2 === 0 ? 'FFFFFF' : 'F8FCFD' } }
        });
      }
    }

    const lastRow = data.length - 1;

    for (let row = firstDataRow; row <= lastRow; row++) {
      for (let col = 0; col <= 12; col++) {
        let style: any = {
          ...normalStyle,
          fill: { fgColor: { rgb: row % 2 === 0 ? 'FFFFFF' : 'F8FCFD' } }
        };

        if ([7, 8, 9].includes(col)) {
          style = {
            ...numberStyle,
            fill: { fgColor: { rgb: row % 2 === 0 ? 'FFFFFF' : 'F8FCFD' } }
          };
        }

        if (col === 11) {
          style = {
            ...moneyStyle,
            fill: { fgColor: { rgb: row % 2 === 0 ? 'FFFFFF' : 'F8FCFD' } }
          };
        }

        setStyle(row, col, style);
      }

      const estado = String(data[row][12] || '').toUpperCase();
      const estadoRef = XLSX.utils.encode_cell({ r: row, c: 12 });

      if (ws[estadoRef]) {
        ws[estadoRef].s = {
          font: {
            bold: true,
            color: {
              rgb: estado === 'PAGADO'
                ? '166534'
                : estado === 'VENCIDO'
                  ? 'B91C1C'
                  : 'C2410C'
            }
          },
          fill: {
            fgColor: {
              rgb: estado === 'PAGADO'
                ? 'DCFCE7'
                : estado === 'VENCIDO'
                  ? 'FEE2E2'
                  : 'FFEDD5'
            }
          },
          alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
          border
        };
      }
    }

    ws['!autofilter'] = {
      ref: `A${headerRow + 1}:M${data.length}`
    };

    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Historial lecturas');

    XLSX.writeFile(wb, `historial_lecturas_jass_huacariz_${fechaArchivo}.xlsx`);
  }

  imprimirReporte(): void {
    const fecha = new Date().toLocaleString('es-PE');

    const filas = this.lecturasFiltradas.map((item: any) => `
      <tr>
        <td>${this.textoSeguro(item.codigoSuministro || '')}</td>
        <td>${this.textoSeguro(item.aliasSuministro || item.direccionSuministro || '')}</td>
        <td>${this.textoSeguro(item.nombreCliente || item.cliente || '')}</td>
        <td>${this.textoSeguro(item.dniCliente || '')}</td>
        <td>${this.textoSeguro(item.sector || '')}</td>
        <td>${this.nombreMes(Number(item.mes))} ${item.anio}</td>
        <td>${Number(item.lecturaAnterior || 0).toFixed(3)} m³</td>
        <td>${Number(item.lecturaActual || 0).toFixed(3)} m³</td>
        <td>${Number(item.consumoM3 || 0).toFixed(3)} m³</td>
        <td>${this.textoSeguro(item.codigoRecibo || '-')}</td>
        <td>S/ ${Number(item.totalRecibo || item.total || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(item.estadoRecibo || 'PENDIENTE')}</td>
      </tr>
    `).join('');

    const ventana = window.open('', '_blank', 'width=1200,height=800');

    if (!ventana) {
      this.error = 'No se pudo abrir la ventana de impresión. Revisa si el navegador bloqueó ventanas emergentes.';
      return;
    }

    ventana.document.open();
    ventana.document.write(`
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
            font-family: Arial, Helvetica, sans-serif;
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
              <p>Fecha de emisión: ${fecha}</p>
            </div>
          </div>

          <strong>Administración</strong>
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
            ${filas || '<tr><td colspan="12">No hay lecturas registradas.</td></tr>'}
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

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}