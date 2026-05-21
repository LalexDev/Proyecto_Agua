import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

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
      return total + Number(item.totalRecibo || 0);
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

    const filas: any[][] = [];

    filas.push(['JASS HUACARIZ - HISTORIAL DE LECTURAS']);
    filas.push(['Reporte administrativo de lecturas, consumos y recibos generados']);
    filas.push([`Fecha de exportación: ${fechaTexto}`]);
    filas.push([]);

    const filaResumenTitulo = filas.length;
    filas.push(['RESUMEN GENERAL']);

    const filaResumenCabecera = filas.length;
    filas.push(['Indicador', 'Valor', '', 'Indicador', 'Valor']);

    filas.push(['Lecturas registradas', this.lecturasFiltradas.length, '', 'Pendientes', this.totalPendientes()]);
    filas.push(['Consumo total m³', Number(this.totalConsumo().toFixed(3)), '', 'Pagados', this.totalPagados()]);
    filas.push(['Total emitido S/', Number(this.totalEmitido().toFixed(2)), '', 'Filtros aplicados', `${this.filtroMes ? this.nombreMes(Number(this.filtroMes)) : 'Todos los meses'} / ${this.filtroAnio || 'Todos los años'}`]);
    filas.push([]);

    const filaDetalleTitulo = filas.length;
    filas.push(['DETALLE DE LECTURAS']);

    const filaDetalleCabecera = filas.length;
    filas.push([
      'Suministro',
      'Alias / Dirección',
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

    const primeraFilaDatos = filas.length;

    this.lecturasFiltradas.forEach((item: any) => {
      filas.push([
        item.codigoSuministro || '',
        item.aliasSuministro || item.direccionSuministro || '',
        item.cliente || '',
        item.dniCliente || '',
        item.sector || '',
        `${this.nombreMes(Number(item.mes))} ${item.anio}`,
        Number(item.lecturaAnterior || 0),
        Number(item.lecturaActual || 0),
        Number(item.consumoM3 || 0),
        item.codigoRecibo || '-',
        Number(item.totalRecibo || 0),
        item.estadoRecibo || 'PENDIENTE'
      ]);
    });

    if (this.lecturasFiltradas.length === 0) {
      filas.push(['No hay lecturas registradas']);
    }

    const worksheet: any = XLSX.utils.aoa_to_sheet(filas);

    worksheet['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 11 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 11 } },
      { s: { r: 2, c: 0 }, e: { r: 2, c: 11 } },
      { s: { r: filaResumenTitulo, c: 0 }, e: { r: filaResumenTitulo, c: 11 } },
      { s: { r: filaDetalleTitulo, c: 0 }, e: { r: filaDetalleTitulo, c: 11 } }
    ];

    worksheet['!cols'] = [
      { wch: 20 },
      { wch: 32 },
      { wch: 28 },
      { wch: 14 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 16 },
      { wch: 18 },
      { wch: 14 },
      { wch: 15 }
    ];

    worksheet['!rows'] = [
      { hpt: 30 },
      { hpt: 22 },
      { hpt: 22 },
      { hpt: 10 }
    ];

    worksheet['!autofilter'] = {
      ref: `A${filaDetalleCabecera + 1}:L${filas.length}`
    };

    this.aplicarEstilosExcel(
      worksheet,
      filaResumenTitulo,
      filaResumenCabecera,
      filaDetalleTitulo,
      filaDetalleCabecera,
      primeraFilaDatos,
      filas.length - 1,
      filas
    );

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Historial lecturas');

    const detalleCompleto = this.lecturasFiltradas.map((item: any) => ({
      'Código suministro': item.codigoSuministro || '',
      'Alias suministro': item.aliasSuministro || '',
      'Dirección': item.direccionSuministro || '',
      'Cliente': item.cliente || '',
      'DNI': item.dniCliente || '',
      'Sector': item.sector || '',
      'Año': item.anio || '',
      'Mes': this.nombreMes(Number(item.mes)),
      'Lectura anterior': Number(item.lecturaAnterior || 0),
      'Lectura actual': Number(item.lecturaActual || 0),
      'Consumo m³': Number(item.consumoM3 || 0),
      'Código recibo': item.codigoRecibo || '',
      'Total recibo': Number(item.totalRecibo || 0),
      'Estado recibo': item.estadoRecibo || 'PENDIENTE',
      'Fecha registro': item.fechaRegistro || ''
    }));

    const worksheetDetalle = this.crearHojaDetalle(detalleCompleto);
    XLSX.utils.book_append_sheet(workbook, worksheetDetalle, 'Detalle completo');

    XLSX.writeFile(workbook, `historial_lecturas_jass_huacariz_${fechaArchivo}.xlsx`);
  }

  imprimirReporte(): void {
    if (!this.lecturasFiltradas.length) {
      alert('No hay datos para imprimir.');
      return;
    }

    const filas = this.lecturasFiltradas.map((item: any) => `
      <tr>
        <td>${this.textoSeguro(item.codigoSuministro)}</td>
        <td>${this.textoSeguro(item.aliasSuministro || item.direccionSuministro || '-')}</td>
        <td>${this.textoSeguro(item.cliente)}</td>
        <td>${this.textoSeguro(item.dniCliente)}</td>
        <td>${this.textoSeguro(item.sector)}</td>
        <td>${this.nombreMes(Number(item.mes))} ${item.anio}</td>
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
              <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
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
            ${filas}
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

  private crearHojaDetalle(data: any[]): any {
    const datos = data.length ? data : [{ Mensaje: 'Sin datos registrados' }];
    const worksheet: any = XLSX.utils.json_to_sheet(datos);
    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);

    worksheet['!cols'] = Array.from({ length: range.e.c + 1 }, () => ({ wch: 24 }));
    worksheet['!autofilter'] = { ref };

    const estilos = this.estilosExcel();

    this.aplicarEstiloRango(worksheet, 0, 0, 0, range.e.c, estilos.cabeceraTabla);

    if (range.e.r >= 1) {
      this.aplicarEstiloRango(worksheet, 1, 0, range.e.r, range.e.c, estilos.celda);
    }

    return worksheet;
  }

  private aplicarEstilosExcel(
    worksheet: any,
    filaResumenTitulo: number,
    filaResumenCabecera: number,
    filaDetalleTitulo: number,
    filaDetalleCabecera: number,
    primeraFilaDatos: number,
    ultimaFilaDatos: number,
    filas: any[][]
  ): void {
    const estilos = this.estilosExcel();
    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);

    this.aplicarEstiloRango(worksheet, 0, 0, range.e.r, range.e.c, estilos.celda);

    this.aplicarEstiloRango(worksheet, 0, 0, 0, 11, estilos.titulo);
    this.aplicarEstiloRango(worksheet, 1, 0, 1, 11, estilos.subtitulo);
    this.aplicarEstiloRango(worksheet, 2, 0, 2, 11, estilos.fecha);

    this.aplicarEstiloRango(worksheet, filaResumenTitulo, 0, filaResumenTitulo, 11, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaResumenCabecera, 0, filaResumenCabecera, 4, estilos.cabeceraTabla);
    this.aplicarEstiloRango(worksheet, filaResumenCabecera + 1, 0, filaResumenCabecera + 3, 4, estilos.resumen);

    this.aplicarEstiloRango(worksheet, filaDetalleTitulo, 0, filaDetalleTitulo, 11, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaDetalleCabecera, 0, filaDetalleCabecera, 11, estilos.cabeceraTabla);

    if (ultimaFilaDatos >= primeraFilaDatos) {
      this.aplicarEstiloRango(worksheet, primeraFilaDatos, 0, ultimaFilaDatos, 11, estilos.celda);

      for (let fila = primeraFilaDatos; fila <= ultimaFilaDatos; fila++) {
        [6, 7, 8].forEach((columna) => {
          const celda = XLSX.utils.encode_cell({ r: fila, c: columna });
          if (worksheet[celda]) {
            worksheet[celda].z = '#,##0.000';
          }
        });

        const celdaTotal = XLSX.utils.encode_cell({ r: fila, c: 10 });
        if (worksheet[celdaTotal]) {
          worksheet[celdaTotal].z = '"S/ "#,##0.00';
        }

        const estado = String(filas[fila][11] || '').toUpperCase();
        const celdaEstado = XLSX.utils.encode_cell({ r: fila, c: 11 });

        if (worksheet[celdaEstado]) {
          worksheet[celdaEstado].s = {
            ...estilos.estado,
            font: {
              bold: true,
              color: {
                rgb: estado === 'PAGADO' ? '166534' : estado === 'VENCIDO' ? 'B91C1C' : 'C2410C'
              }
            },
            fill: {
              fgColor: {
                rgb: estado === 'PAGADO' ? 'DCFCE7' : estado === 'VENCIDO' ? 'FEE2E2' : 'FFEDD5'
              }
            }
          };
        }
      }
    }
  }

  private aplicarEstiloRango(
    worksheet: any,
    filaInicio: number,
    columnaInicio: number,
    filaFin: number,
    columnaFin: number,
    estilo: any
  ): void {
    for (let fila = filaInicio; fila <= filaFin; fila++) {
      for (let columna = columnaInicio; columna <= columnaFin; columna++) {
        const celda = XLSX.utils.encode_cell({ r: fila, c: columna });

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
        fill: { fgColor: { rgb: '07384A' } },
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
        alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
        border: borde
      },
      resumen: {
        font: { color: { rgb: '0F2F3D' } },
        fill: { fgColor: { rgb: 'F8FCFD' } },
        alignment: { vertical: 'center', wrapText: true },
        border: borde
      },
      celda: {
        font: { color: { rgb: '0F2F3D' } },
        alignment: { vertical: 'center', wrapText: true },
        border: borde
      },
      estado: {
        alignment: { horizontal: 'center', vertical: 'center' },
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