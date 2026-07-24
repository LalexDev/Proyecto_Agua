import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import {
  HistorialLectura,
  LecturaAdmin,
  LecturaPendiente
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

  pendientesLectura: LecturaPendiente[] = [];
  pendientesFiltrados: LecturaPendiente[] = [];

  busqueda = '';
  filtroAnio: number | '' = new Date().getFullYear();
  filtroMes: number | '' = new Date().getMonth() + 1;
  private readonly limiteHistorialInicial = 200;
  private readonly limiteHistorialFiltrado = 5000;
  filtrosCompletosAplicados = false;
  limitePendientes = 5000;
  private debounceHistorial: any;
  private debouncePendientes: any;

  busquedaPendientes = '';
  filtroPendienteAnio: number = new Date().getFullYear();
  filtroPendienteMes: number = new Date().getMonth() + 1;

  cargando = false;
  cargandoPendientes = false;

  error = '';
  errorPendientes = '';
  exitoPendientes = '';

  lecturaSeleccionada: HistorialLectura | null = null;
  pendienteSeleccionado: LecturaPendiente | null = null;

  constructor(
    private lecturaAdmin: LecturaAdmin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarHistorial();
    this.buscarPendientesLectura();
  }

  get limiteHistorial(): number {
    return this.filtrosCompletosAplicados ? this.limiteHistorialFiltrado : this.limiteHistorialInicial;
  }

  cargarHistorial(): void {
    this.cargando = true;
    this.error = '';

    this.lecturaAdmin.listarHistorial({
      anio: this.filtroAnio,
      mes: this.filtroMes,
      buscar: this.busqueda,
      limit: this.limiteHistorial
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturas = data || [];
          this.lecturasFiltradas = this.lecturas;
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

  buscarPendientesLectura(): void {
    this.errorPendientes = '';
    this.exitoPendientes = '';

    if (!this.filtroPendienteAnio || Number(this.filtroPendienteAnio) < 2024) {
      this.errorPendientes = 'Ingrese un año válido para consultar pendientes.';
      return;
    }

    if (!this.filtroPendienteMes || Number(this.filtroPendienteMes) < 1 || Number(this.filtroPendienteMes) > 12) {
      this.errorPendientes = 'Seleccione un mes válido para consultar pendientes.';
      return;
    }

    this.cargandoPendientes = true;

    this.lecturaAdmin.listarPendientesLectura(
      Number(this.filtroPendienteAnio),
      Number(this.filtroPendienteMes),
      this.busquedaPendientes,
      this.limitePendientes
    )
      .pipe(
        finalize(() => {
          this.cargandoPendientes = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.pendientesLectura = data || [];
          this.pendientesFiltrados = this.pendientesLectura;

          this.exitoPendientes = this.pendientesLectura.length > 0
            ? `Se encontraron ${this.pendientesLectura.length} suministro(s) sin lectura en ${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}.`
            : `Todos los suministros activos tienen lectura registrada en ${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}.`;

          this.cdr.detectChanges();
        },
        error: () => {
          this.errorPendientes = 'No se pudieron consultar los suministros sin lectura. Verifica el backend y tu sesión ADMIN.';
          this.exitoPendientes = '';
          this.pendientesLectura = [];
          this.pendientesFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    this.filtrosCompletosAplicados = true;
    clearTimeout(this.debounceHistorial);
    this.debounceHistorial = setTimeout(() => {
      this.cargarHistorial();
    }, 350);
  }

  aplicarFiltroPendientes(): void {
    clearTimeout(this.debouncePendientes);
    this.debouncePendientes = setTimeout(() => {
      this.buscarPendientesLectura();
    }, 350);
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroAnio = new Date().getFullYear();
    this.filtroMes = new Date().getMonth() + 1;
    this.filtrosCompletosAplicados = false;
    this.cargarHistorial();
  }

  limpiarFiltroPendientes(): void {
    this.busquedaPendientes = '';
    this.buscarPendientesLectura();
  }

  abrirDetalleLectura(item: HistorialLectura): void {
    this.lecturaSeleccionada = item;
  }

  cerrarDetalleLectura(): void {
    this.lecturaSeleccionada = null;
  }

  abrirDetallePendiente(item: LecturaPendiente): void {
    this.pendienteSeleccionado = item;
  }

  cerrarDetallePendiente(): void {
    this.pendienteSeleccionado = null;
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
      consumoM3: Number(item.consumoM3 || 0),
      subtotalAgua: Number(item.subtotalAgua || item.totalAgua || 0),
      cargoMantenimiento: Number(item.cargoMantenimiento || 0),
      cargoLector: Number(item.cargoLector || 0),
      cargoOtros: Number(item.cargoOtros || 0),
      mora: Number(item.mora || 0),
      total: Number(item.totalRecibo || item.total || 0),
      estadoRecibo: item.estadoRecibo || 'PENDIENTE',
      fechaEmision: item.fechaEmision || item.fechaLectura || item.fechaRegistro || '-',
      fechaVencimiento: item.fechaVencimiento || '-',
      codigoBarras: item.codigoBarras || `${item.codigoRecibo || ''}-${item.codigoSuministro || ''}`
    };

    imprimirReciboJass(reciboTemporal, this.lecturas);
  }

  exportarExcel(): void {
    const titulo = 'AGUA POTABLE HUACARIZ - HISTORIAL DE LECTURAS';
    const periodo = this.periodoHistorialTexto();
    const fecha = new Date().toLocaleString('es-PE');

    const data: any[][] = [
      [titulo],
      ['Sistema de gestión de agua potable - Control de lecturas y consumos'],
      [`Periodo/Filtro: ${periodo}`],
      [`Fecha de exportación: ${fecha}`],
      [],
      ['RESUMEN GENERAL'],
      ['Lecturas registradas', this.totalLecturas(), 'Consumo total (m³)', this.totalConsumo(), 'Consumo promedio (m³)', this.consumoPromedio()],
      ['Total emitido (S/)', this.totalEmitido(), 'Recibos pagados', this.totalPagados(), 'Recibos pendientes', this.totalPendientes()],
      [],
      [
        'N°',
        'Suministro',
        'Cliente',
        'DNI',
        'Sector',
        'Periodo',
        'Lectura anterior',
        'Lectura actual',
        'Consumo m³',
        'Código recibo',
        'Total S/',
        'Estado',
        'Fecha registro'
      ]
    ];

    this.lecturasFiltradas.forEach((item: any, index) => {
      data.push([
        index + 1,
        item.codigoSuministro || '',
        this.nombreCliente(item),
        item.dniCliente || '',
        item.sector || '',
        `${this.nombreMes(Number(item.mes))} ${item.anio}`,
        Number(item.lecturaAnterior || 0),
        Number(item.lecturaActual || 0),
        Number(item.consumoM3 || 0),
        item.codigoRecibo || '',
        Number(item.totalRecibo || item.total || 0),
        item.estadoRecibo || 'PENDIENTE',
        item.fechaRegistro || item.fechaLectura || ''
      ]);
    });

    const worksheet = XLSX.utils.aoa_to_sheet(data);
    const workbook = XLSX.utils.book_new();

    worksheet['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 12 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 12 } },
      { s: { r: 2, c: 0 }, e: { r: 2, c: 12 } },
      { s: { r: 3, c: 0 }, e: { r: 3, c: 12 } },
      { s: { r: 5, c: 0 }, e: { r: 5, c: 12 } }
    ];

    worksheet['!cols'] = [
      { wch: 6 },
      { wch: 18 },
      { wch: 30 },
      { wch: 14 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 15 },
      { wch: 18 },
      { wch: 14 },
      { wch: 14 },
      { wch: 24 }
    ];

    const range = XLSX.utils.decode_range(worksheet['!ref'] || 'A1:M1');

    for (let row = range.s.r; row <= range.e.r; row++) {
      for (let col = range.s.c; col <= range.e.c; col++) {
        const cellAddress = XLSX.utils.encode_cell({ r: row, c: col });

        if (!worksheet[cellAddress]) {
          worksheet[cellAddress] = { t: 's', v: '' };
        }

        worksheet[cellAddress].s = {
          font: {
            name: 'Arial',
            sz: 10,
            color: { rgb: '0F2F44' }
          },
          alignment: {
            vertical: 'center',
            wrapText: true
          },
          border: {
            top: { style: 'thin', color: { rgb: 'D7E3EA' } },
            bottom: { style: 'thin', color: { rgb: 'D7E3EA' } },
            left: { style: 'thin', color: { rgb: 'D7E3EA' } },
            right: { style: 'thin', color: { rgb: 'D7E3EA' } }
          }
        };
      }
    }

    this.aplicarEstiloFila(worksheet, 0, 0, 12, {
      font: { name: 'Arial', sz: 18, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '0F7FA0' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 1, 0, 12, {
      font: { name: 'Arial', sz: 11, bold: true, color: { rgb: 'E8F7FB' } },
      fill: { fgColor: { rgb: '0F7FA0' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 2, 0, 12, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'E8F7FB' } },
      alignment: { horizontal: 'left', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 3, 0, 12, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'F3F9FC' } },
      alignment: { horizontal: 'left', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 5, 0, 12, {
      font: { name: 'Arial', sz: 12, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '07384A' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 6, 0, 12, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'DCFCE7' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 7, 0, 12, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'E8F7FB' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 9, 0, 12, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '1583A3' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    for (let row = 10; row <= range.e.r; row++) {
      const fillColor = row % 2 === 0 ? 'F8FCFD' : 'FFFFFF';

      this.aplicarEstiloFila(worksheet, row, 0, 12, {
        fill: { fgColor: { rgb: fillColor } },
        alignment: { vertical: 'center', wrapText: true }
      });

      this.aplicarEstiloCelda(worksheet, row, 6, { numFmt: '#,##0.000' });
      this.aplicarEstiloCelda(worksheet, row, 7, { numFmt: '#,##0.000' });
      this.aplicarEstiloCelda(worksheet, row, 8, { numFmt: '#,##0.000' });
      this.aplicarEstiloCelda(worksheet, row, 10, { numFmt: 'S/ #,##0.00' });

      const estado = String(data[row]?.[11] || '').toUpperCase();

      if (estado === 'PAGADO') {
        this.aplicarEstiloCelda(worksheet, row, 11, {
          font: { bold: true, color: { rgb: '166534' } },
          fill: { fgColor: { rgb: 'DCFCE7' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      } else if (estado === 'VENCIDO') {
        this.aplicarEstiloCelda(worksheet, row, 11, {
          font: { bold: true, color: { rgb: 'B91C1C' } },
          fill: { fgColor: { rgb: 'FEE2E2' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      } else {
        this.aplicarEstiloCelda(worksheet, row, 11, {
          font: { bold: true, color: { rgb: 'C2410C' } },
          fill: { fgColor: { rgb: 'FFEDD5' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      }
    }

    worksheet['!rows'] = [
      { hpt: 30 },
      { hpt: 22 },
      { hpt: 22 },
      { hpt: 22 },
      { hpt: 8 },
      { hpt: 24 },
      { hpt: 24 },
      { hpt: 24 },
      { hpt: 8 },
      { hpt: 28 }
    ];

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Historial lecturas');

    XLSX.writeFile(
      workbook,
      `historial_lecturas_${this.nombreArchivoPeriodo()}.xlsx`
    );
  }

  exportarPendientesExcel(): void {
    const titulo = 'AGUA POTABLE HUACARIZ - SUMINISTROS SIN LECTURA';
    const periodo = `${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}`;
    const fecha = new Date().toLocaleString('es-PE');

    const data: any[][] = [
      [titulo],
      ['Control de usuarios/suministros sin lectura registrada por periodo'],
      [`Periodo consultado: ${periodo}`],
      [`Fecha de exportación: ${fecha}`],
      [],
      ['RESUMEN DE PENDIENTES'],
      ['Total sin lectura', this.totalSinLectura(), 'Instalados', this.pendientesInstalados(), 'Pendientes de instalación', this.pendientesPorInstalar()],
      [],
      [
        'N°',
        'Suministro',
        'Cliente',
        'DNI',
        'Alias',
        'Dirección',
        'Referencia',
        'Sector',
        'Periodo',
        'Estado',
        'Instalación',
        'Lectura anterior'
      ]
    ];

    this.pendientesFiltrados.forEach((item, index) => {
      data.push([
        index + 1,
        item.codigoSuministro || '',
        item.nombreCliente || '',
        item.dniCliente || '',
        item.aliasSuministro || '',
        item.direccionSuministro || '',
        item.referencia || '',
        item.sector || '',
        `${this.nombreMes(Number(item.mes))} ${item.anio}`,
        item.estado ? 'Activo' : 'Inactivo',
        this.estadoInstalacionTexto(item.estadoInstalacion),
        Number(item.lecturaAnterior || 0)
      ]);
    });

    const worksheet = XLSX.utils.aoa_to_sheet(data);
    const workbook = XLSX.utils.book_new();

    worksheet['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 11 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 11 } },
      { s: { r: 2, c: 0 }, e: { r: 2, c: 11 } },
      { s: { r: 3, c: 0 }, e: { r: 3, c: 11 } },
      { s: { r: 5, c: 0 }, e: { r: 5, c: 11 } }
    ];

    worksheet['!cols'] = [
      { wch: 6 },
      { wch: 18 },
      { wch: 30 },
      { wch: 14 },
      { wch: 22 },
      { wch: 32 },
      { wch: 30 },
      { wch: 18 },
      { wch: 18 },
      { wch: 12 },
      { wch: 24 },
      { wch: 18 }
    ];

    const range = XLSX.utils.decode_range(worksheet['!ref'] || 'A1:L1');

    for (let row = range.s.r; row <= range.e.r; row++) {
      for (let col = range.s.c; col <= range.e.c; col++) {
        const cellAddress = XLSX.utils.encode_cell({ r: row, c: col });

        if (!worksheet[cellAddress]) {
          worksheet[cellAddress] = { t: 's', v: '' };
        }

        worksheet[cellAddress].s = {
          font: {
            name: 'Arial',
            sz: 10,
            color: { rgb: '0F2F44' }
          },
          alignment: {
            vertical: 'center',
            wrapText: true
          },
          border: {
            top: { style: 'thin', color: { rgb: 'D7E3EA' } },
            bottom: { style: 'thin', color: { rgb: 'D7E3EA' } },
            left: { style: 'thin', color: { rgb: 'D7E3EA' } },
            right: { style: 'thin', color: { rgb: 'D7E3EA' } }
          }
        };
      }
    }

    this.aplicarEstiloFila(worksheet, 0, 0, 11, {
      font: { name: 'Arial', sz: 18, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: 'B45309' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 1, 0, 11, {
      font: { name: 'Arial', sz: 11, bold: true, color: { rgb: 'FFF7ED' } },
      fill: { fgColor: { rgb: 'B45309' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 2, 0, 11, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'FFEDD5' } },
      alignment: { horizontal: 'left', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 3, 0, 11, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'FFF7ED' } },
      alignment: { horizontal: 'left', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 5, 0, 11, {
      font: { name: 'Arial', sz: 12, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: '7C2D12' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 6, 0, 11, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: '0F2F44' } },
      fill: { fgColor: { rgb: 'FFEDD5' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    this.aplicarEstiloFila(worksheet, 8, 0, 11, {
      font: { name: 'Arial', sz: 10, bold: true, color: { rgb: 'FFFFFF' } },
      fill: { fgColor: { rgb: 'F59E0B' } },
      alignment: { horizontal: 'center', vertical: 'center' }
    });

    for (let row = 9; row <= range.e.r; row++) {
      const fillColor = row % 2 === 0 ? 'FFF7ED' : 'FFFFFF';

      this.aplicarEstiloFila(worksheet, row, 0, 11, {
        fill: { fgColor: { rgb: fillColor } },
        alignment: { vertical: 'center', wrapText: true }
      });

      this.aplicarEstiloCelda(worksheet, row, 11, { numFmt: '#,##0.000' });

      const instalacion = String(data[row]?.[10] || '').toUpperCase();

      if (instalacion === 'INSTALADO') {
        this.aplicarEstiloCelda(worksheet, row, 10, {
          font: { bold: true, color: { rgb: '166534' } },
          fill: { fgColor: { rgb: 'DCFCE7' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      } else if (instalacion === 'SUSPENDIDO') {
        this.aplicarEstiloCelda(worksheet, row, 10, {
          font: { bold: true, color: { rgb: 'B91C1C' } },
          fill: { fgColor: { rgb: 'FEE2E2' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      } else {
        this.aplicarEstiloCelda(worksheet, row, 10, {
          font: { bold: true, color: { rgb: 'C2410C' } },
          fill: { fgColor: { rgb: 'FFEDD5' } },
          alignment: { horizontal: 'center', vertical: 'center' }
        });
      }
    }

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sin lectura');

    XLSX.writeFile(
      workbook,
      `suministros_sin_lectura_${this.filtroPendienteAnio}_${this.filtroPendienteMes}.xlsx`
    );
  }

  imprimirReporte(): void {
    const ventana = window.open('', '_blank', 'width=1200,height=850');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const filas = this.lecturasFiltradas.map((item: any, index) => `
      <tr>
        <td>${index + 1}</td>
        <td>
          <strong>${this.textoSeguro(item.codigoSuministro)}</strong><br>
          <span>${this.textoSeguro(item.aliasSuministro || item.direccionSuministro || '-')}</span>
        </td>
        <td>
          <strong>${this.textoSeguro(this.nombreCliente(item))}</strong><br>
          <span>DNI: ${this.textoSeguro(item.dniCliente || '-')}</span>
        </td>
        <td>${this.textoSeguro(item.sector || '-')}</td>
        <td>${this.textoSeguro(this.nombreMes(Number(item.mes)))} ${this.textoSeguro(item.anio)}</td>
        <td>${Number(item.lecturaAnterior || 0).toFixed(3)} m³</td>
        <td>${Number(item.lecturaActual || 0).toFixed(3)} m³</td>
        <td><strong>${Number(item.consumoM3 || 0).toFixed(3)} m³</strong></td>
        <td>${this.textoSeguro(item.codigoRecibo || '-')}</td>
        <td><strong>S/ ${this.totalItem(item).toFixed(2)}</strong></td>
        <td><span class="badge ${this.estadoClase(item.estadoRecibo)}">${this.textoSeguro(item.estadoRecibo || 'PENDIENTE')}</span></td>
      </tr>
    `).join('');

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Historial de lecturas</title>
        <style>
          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            padding: 24px;
            font-family: Arial, sans-serif;
            color: #0f2f44;
            background: #f4f8fb;
          }

          .sheet {
            max-width: 1180px;
            margin: 0 auto;
            background: #ffffff;
            border: 2px solid #0f7fa0;
            padding: 22px;
          }

          .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 20px;
            border-bottom: 3px solid #0f7fa0;
            padding-bottom: 14px;
            margin-bottom: 18px;
          }

          .brand {
            display: flex;
            gap: 14px;
            align-items: center;
          }

          .logo {
            width: 58px;
            height: 58px;
            border: 1px solid #9bd3e2;
            border-radius: 12px;
            display: grid;
            place-items: center;
            color: #0f7fa0;
            font-size: 32px;
          }

          h1 {
            margin: 0;
            letter-spacing: 6px;
            color: #0f7fa0;
            font-size: 30px;
          }

          .brand p {
            margin: 4px 0 0;
            font-size: 13px;
            color: #0f2f44;
            font-weight: 700;
          }

          .period {
            min-width: 250px;
            border: 1px solid #9bd3e2;
            padding: 12px 18px;
            text-align: center;
            background: #f8fcfd;
          }

          .period span {
            display: block;
            font-size: 12px;
            font-weight: 800;
          }

          .period strong {
            display: block;
            margin-top: 5px;
            font-size: 20px;
            color: #0f2f44;
          }

          .summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin-bottom: 18px;
          }

          .box {
            border: 1px solid #b7d8e3;
            background: #f8fcfd;
            padding: 12px;
          }

          .box span {
            display: block;
            font-size: 12px;
            color: #64748b;
            font-weight: 700;
            margin-bottom: 5px;
          }

          .box strong {
            display: block;
            font-size: 20px;
            color: #0f2f44;
          }

          .box.main {
            background: #e8f7fb;
          }

          .title-bar {
            background: #0f7fa0;
            color: white;
            padding: 10px 12px;
            font-weight: 800;
            margin-bottom: 0;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
          }

          th {
            background: #e8f7fb;
            color: #0f2f44;
            text-align: left;
            border: 1px solid #b7d8e3;
            padding: 8px;
          }

          td {
            border: 1px solid #b7d8e3;
            padding: 8px;
            vertical-align: top;
          }

          tr:nth-child(even) td {
            background: #f8fcfd;
          }

          td span {
            color: #64748b;
            font-size: 11px;
          }

          .badge {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 800;
          }

          .badge.pagado {
            background: #dcfce7;
            color: #166534;
          }

          .badge.pendiente {
            background: #ffedd5;
            color: #c2410c;
          }

          .badge.vencido {
            background: #fee2e2;
            color: #b91c1c;
          }

          .footer {
            margin-top: 18px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
          }

          .footer div {
            border: 1px solid #b7d8e3;
            padding: 10px;
            font-size: 12px;
          }

          .print-actions {
            margin: 18px auto 0;
            max-width: 1180px;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 12px 18px;
            font-weight: 800;
            cursor: pointer;
          }

          .btn-print {
            background: #0f7fa0;
            color: white;
          }

          .btn-close {
            background: #e2e8f0;
            color: #0f2f44;
          }

          @media print {
            body {
              background: #ffffff;
              padding: 0;
            }

            .sheet {
              border: 1px solid #0f7fa0;
              max-width: none;
              width: 100%;
              padding: 12px;
            }

            .print-actions {
              display: none;
            }

            table {
              font-size: 10px;
            }

            th, td {
              padding: 5px;
            }

            .summary {
              grid-template-columns: repeat(4, 1fr);
            }
          }
        </style>
      </head>
      <body>
        <div class="sheet">
          <div class="header">
            <div class="brand">
              <div class="logo">💧</div>
              <div>
                <h1>AGUA POTABLE HUACARIZ</h1>
                <p>Servicio de agua potable  -  Sistema de Gestión de Agua</p>
                <p>Cajamarca, Perú</p>
              </div>
            </div>

            <div class="period">
              <span>REPORTE DE LECTURAS</span>
              <strong>${this.textoSeguro(this.periodoHistorialTexto())}</strong>
            </div>
          </div>

          <div class="summary">
            <div class="box main">
              <span>Lecturas registradas</span>
              <strong>${this.totalLecturas()}</strong>
            </div>

            <div class="box">
              <span>Consumo total</span>
              <strong>${this.totalConsumo().toFixed(3)} m³</strong>
            </div>

            <div class="box">
              <span>Total emitido</span>
              <strong>S/ ${this.totalEmitido().toFixed(2)}</strong>
            </div>

            <div class="box">
              <span>Consumo promedio</span>
              <strong>${this.consumoPromedio().toFixed(3)} m³</strong>
            </div>
          </div>

          <div class="title-bar">Detalle de lecturas registradas</div>

          <table>
            <thead>
              <tr>
                <th>N°</th>
                <th>Suministro</th>
                <th>Cliente</th>
                <th>Sector</th>
                <th>Periodo</th>
                <th>Lect. ant.</th>
                <th>Lect. act.</th>
                <th>Consumo</th>
                <th>Recibo</th>
                <th>Total</th>
                <th>Estado</th>
              </tr>
            </thead>

            <tbody>
              ${filas || '<tr><td colspan="11">No hay lecturas registradas para los filtros seleccionados.</td></tr>'}
            </tbody>
          </table>

          <div class="footer">
            <div>
              <strong>Observación:</strong>
              Documento generado por el sistema de gestión de agua Agua Potable Huacariz.
            </div>

            <div>
              <strong>Fecha de emisión:</strong>
              ${this.textoSeguro(new Date().toLocaleString('es-PE'))}
            </div>
          </div>
        </div>

        <div class="print-actions">
          <button class="btn-close" onclick="window.close()">Cerrar</button>
          <button class="btn-print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);

    ventana.document.close();
  }

  imprimirPendientes(): void {
    const ventana = window.open('', '_blank', 'width=1100,height=850');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const periodo = `${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}`;

    const filas = this.pendientesFiltrados.map((item, index) => `
      <tr>
        <td>${index + 1}</td>
        <td>
          <strong>${this.textoSeguro(item.codigoSuministro)}</strong><br>
          <span>${this.textoSeguro(item.aliasSuministro || '-')}</span>
        </td>
        <td>
          <strong>${this.textoSeguro(item.nombreCliente)}</strong><br>
          <span>DNI: ${this.textoSeguro(item.dniCliente || '-')}</span>
        </td>
        <td>
          <strong>${this.textoSeguro(item.direccionSuministro || '-')}</strong><br>
          <span>${this.textoSeguro(item.referencia || '-')}</span>
        </td>
        <td>${this.textoSeguro(item.sector || '-')}</td>
        <td><span class="badge ${this.estadoInstalacionClase(item.estadoInstalacion)}">${this.textoSeguro(this.estadoInstalacionTexto(item.estadoInstalacion))}</span></td>
        <td><strong>${Number(item.lecturaAnterior || 0).toFixed(3)} m³</strong></td>
      </tr>
    `).join('');

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Suministros sin lectura</title>
        <style>
          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            padding: 24px;
            font-family: Arial, sans-serif;
            color: #0f2f44;
            background: #f4f8fb;
          }

          .sheet {
            max-width: 1100px;
            margin: 0 auto;
            background: #ffffff;
            border: 2px solid #f59e0b;
            padding: 22px;
          }

          .header {
            display: flex;
            justify-content: space-between;
            gap: 20px;
            border-bottom: 3px solid #f59e0b;
            padding-bottom: 14px;
            margin-bottom: 18px;
          }

          .brand {
            display: flex;
            gap: 14px;
            align-items: center;
          }

          .logo {
            width: 58px;
            height: 58px;
            border: 1px solid #fed7aa;
            border-radius: 12px;
            display: grid;
            place-items: center;
            color: #f59e0b;
            font-size: 32px;
          }

          h1 {
            margin: 0;
            letter-spacing: 5px;
            color: #b45309;
            font-size: 28px;
          }

          .brand p {
            margin: 4px 0 0;
            font-size: 13px;
            color: #0f2f44;
            font-weight: 700;
          }

          .period {
            min-width: 250px;
            border: 1px solid #fed7aa;
            padding: 12px 18px;
            text-align: center;
            background: #fff7ed;
          }

          .period span {
            display: block;
            font-size: 12px;
            font-weight: 800;
          }

          .period strong {
            display: block;
            margin-top: 5px;
            font-size: 20px;
            color: #0f2f44;
          }

          .summary {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            margin-bottom: 18px;
          }

          .box {
            border: 1px solid #fed7aa;
            background: #fff7ed;
            padding: 12px;
          }

          .box span {
            display: block;
            font-size: 12px;
            color: #64748b;
            font-weight: 700;
            margin-bottom: 5px;
          }

          .box strong {
            display: block;
            font-size: 22px;
            color: #0f2f44;
          }

          .title-bar {
            background: #b45309;
            color: white;
            padding: 10px 12px;
            font-weight: 800;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
          }

          th {
            background: #ffedd5;
            color: #0f2f44;
            text-align: left;
            border: 1px solid #fed7aa;
            padding: 8px;
          }

          td {
            border: 1px solid #fed7aa;
            padding: 8px;
            vertical-align: top;
          }

          tr:nth-child(even) td {
            background: #fff7ed;
          }

          td span {
            color: #64748b;
            font-size: 11px;
          }

          .badge {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 800;
          }

          .badge.instalado {
            background: #dcfce7;
            color: #166534;
          }

          .badge.pendiente-instalacion {
            background: #ffedd5;
            color: #c2410c;
          }

          .badge.suspendido {
            background: #fee2e2;
            color: #b91c1c;
          }

          .footer {
            margin-top: 18px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
          }

          .footer div {
            border: 1px solid #fed7aa;
            padding: 10px;
            font-size: 12px;
          }

          .print-actions {
            margin: 18px auto 0;
            max-width: 1100px;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 12px 18px;
            font-weight: 800;
            cursor: pointer;
          }

          .btn-print {
            background: #b45309;
            color: white;
          }

          .btn-close {
            background: #e2e8f0;
            color: #0f2f44;
          }

          @media print {
            body {
              background: #ffffff;
              padding: 0;
            }

            .sheet {
              max-width: none;
              width: 100%;
              padding: 12px;
            }

            .print-actions {
              display: none;
            }

            table {
              font-size: 10px;
            }

            th, td {
              padding: 5px;
            }
          }
        </style>
      </head>
      <body>
        <div class="sheet">
          <div class="header">
            <div class="brand">
              <div class="logo">⚠️</div>
              <div>
                <h1>AGUA POTABLE HUACARIZ</h1>
                <p>Reporte de suministros sin lectura registrada</p>
                <p>Cajamarca, Perú  -  Sistema de Gestión de Agua</p>
              </div>
            </div>

            <div class="period">
              <span>PERIODO CONSULTADO</span>
              <strong>${this.textoSeguro(periodo)}</strong>
            </div>
          </div>

          <div class="summary">
            <div class="box">
              <span>Total sin lectura</span>
              <strong>${this.totalSinLectura()}</strong>
            </div>

            <div class="box">
              <span>Instalados</span>
              <strong>${this.pendientesInstalados()}</strong>
            </div>

            <div class="box">
              <span>Pendientes instalación</span>
              <strong>${this.pendientesPorInstalar()}</strong>
            </div>
          </div>

          <div class="title-bar">Detalle de suministros pendientes</div>

          <table>
            <thead>
              <tr>
                <th>N°</th>
                <th>Suministro</th>
                <th>Cliente</th>
                <th>Dirección / Referencia</th>
                <th>Sector</th>
                <th>Instalación</th>
                <th>Lectura anterior</th>
              </tr>
            </thead>

            <tbody>
              ${filas || '<tr><td colspan="7">No hay suministros pendientes de lectura para este periodo.</td></tr>'}
            </tbody>
          </table>

          <div class="footer">
            <div>
              <strong>Observación:</strong>
              Este reporte muestra suministros activos que no registran lectura en el periodo consultado.
            </div>

            <div>
              <strong>Fecha de emisión:</strong>
              ${this.textoSeguro(new Date().toLocaleString('es-PE'))}
            </div>
          </div>
        </div>

        <div class="print-actions">
          <button class="btn-close" onclick="window.close()">Cerrar</button>
          <button class="btn-print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);

    ventana.document.close();
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  nombreCliente(item: any): string {
    return item?.nombreCliente || item?.cliente || 'No disponible';
  }

  totalItem(item: any): number {
    return Number(item?.totalRecibo || item?.total || 0);
  }

  totalLecturas(): number {
    return this.lecturasFiltradas.length;
  }

  totalConsumo(): number {
    return this.lecturasFiltradas.reduce((total: number, item: any) => {
      return total + Number(item.consumoM3 || 0);
    }, 0);
  }

  consumoPromedio(): number {
    if (!this.lecturasFiltradas.length) {
      return 0;
    }

    return this.totalConsumo() / this.lecturasFiltradas.length;
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

  totalVencidos(): number {
    return this.lecturasFiltradas.filter((item: any) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  totalConRecibo(): number {
    return this.lecturasFiltradas.filter((item: any) => !!item.codigoRecibo).length;
  }

  totalSinLectura(): number {
    return this.pendientesFiltrados.length;
  }

  pendientesInstalados(): number {
    return this.pendientesFiltrados.filter((item) => {
      return this.estadoInstalacionTexto(item.estadoInstalacion).toUpperCase() === 'INSTALADO';
    }).length;
  }

  pendientesPorInstalar(): number {
    return this.pendientesFiltrados.filter((item) => {
      return this.estadoInstalacionTexto(item.estadoInstalacion).toUpperCase() !== 'INSTALADO';
    }).length;
  }

  porcentajePagados(): number {
    if (!this.totalConRecibo()) {
      return 0;
    }

    return (this.totalPagados() / this.totalConRecibo()) * 100;
  }

  porcentajePendientes(): number {
    if (!this.totalConRecibo()) {
      return 0;
    }

    return (this.totalPendientes() / this.totalConRecibo()) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.totalConRecibo()) {
      return 0;
    }

    return (this.totalVencidos() / this.totalConRecibo()) * 100;
  }

  graficoEstados(): string {
    if (!this.totalConRecibo()) {
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

  topConsumos(): any[] {
    return [...this.lecturasFiltradas]
      .sort((a: any, b: any) => Number(b.consumoM3 || 0) - Number(a.consumoM3 || 0))
      .slice(0, 5);
  }

  consumoMaximo(): number {
    if (!this.lecturasFiltradas.length) {
      return 0;
    }

    return Math.max(...this.lecturasFiltradas.map((item: any) => Number(item.consumoM3 || 0)));
  }

  anchoConsumo(item: any): string {
    const maximo = this.consumoMaximo();

    if (maximo <= 0) {
      return '0%';
    }

    const porcentaje = (Number(item.consumoM3 || 0) / maximo) * 100;

    return `${Math.max(porcentaje, 8)}%`;
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

  estadoInstalacionTexto(estado?: string): string {
    const valor = String(estado || '').toUpperCase();

    if (valor === 'INSTALADO') {
      return 'Instalado';
    }

    if (valor === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    return 'Pendiente de instalación';
  }

  estadoInstalacionClase(estado?: string): string {
    const valor = String(estado || '').toUpperCase();

    if (valor === 'INSTALADO') {
      return 'instalado';
    }

    if (valor === 'SUSPENDIDO') {
      return 'suspendido';
    }

    return 'pendiente-instalacion';
  }

  periodoHistorialTexto(): string {
    const mes = this.filtroMes ? this.nombreMes(Number(this.filtroMes)) : 'Todos los meses';
    const anio = this.filtroAnio ? String(this.filtroAnio) : 'Todos los años';

    return `${mes}  -  ${anio}`;
  }

  nombreArchivoPeriodo(): string {
    const mes = this.filtroMes ? String(this.filtroMes).padStart(2, '0') : 'todos_meses';
    const anio = this.filtroAnio ? String(this.filtroAnio) : 'todos_anios';

    return `${anio}_${mes}`;
  }

  private aplicarEstiloFila(worksheet: any, row: number, colInicio: number, colFin: number, style: any): void {
    for (let col = colInicio; col <= colFin; col++) {
      this.aplicarEstiloCelda(worksheet, row, col, style);
    }
  }

  private aplicarEstiloCelda(worksheet: any, row: number, col: number, style: any): void {
    const cellAddress = XLSX.utils.encode_cell({ r: row, c: col });

    if (!worksheet[cellAddress]) {
      worksheet[cellAddress] = { t: 's', v: '' };
    }

    worksheet[cellAddress].s = {
      ...(worksheet[cellAddress].s || {}),
      ...style,
      font: {
        ...((worksheet[cellAddress].s || {}).font || {}),
        ...(style.font || {})
      },
      fill: {
        ...((worksheet[cellAddress].s || {}).fill || {}),
        ...(style.fill || {})
      },
      alignment: {
        ...((worksheet[cellAddress].s || {}).alignment || {}),
        ...(style.alignment || {})
      },
      border: {
        ...((worksheet[cellAddress].s || {}).border || {}),
        ...(style.border || {})
      }
    };

    if (style.numFmt) {
      worksheet[cellAddress].z = style.numFmt;
    }
  }

  private textoSeguro(valor: any): string {
    return String(valor ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}
