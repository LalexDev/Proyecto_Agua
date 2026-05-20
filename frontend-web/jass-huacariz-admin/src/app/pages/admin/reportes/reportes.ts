import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { forkJoin, finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import { Cliente, ClienteResponse } from '../../../core/services/cliente';
import { Recibo, ReciboResponse } from '../../../core/services/recibo';
import { Pago, PagoResponse } from '../../../core/services/pago';
import { Tarifa, TarifaResponse } from '../../../core/services/tarifa';

@Component({
  selector: 'app-reportes',
  imports: [CommonModule],
  templateUrl: './reportes.html',
  styleUrl: './reportes.scss',
})
export class Reportes implements OnInit {
  clientes: ClienteResponse[] = [];
  recibos: ReciboResponse[] = [];
  pagos: PagoResponse[] = [];
  tarifas: TarifaResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clienteService: Cliente,
    private reciboService: Recibo,
    private pagoService: Pago,
    private tarifaService: Tarifa,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarReportes();
  }

  cargarReportes(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      recibos: this.reciboService.listarRecibos(),
      pagos: this.pagoService.listarPagos(),
      tarifas: this.tarifaService.listarTarifas()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ clientes, recibos, pagos, tarifas }) => {
          this.clientes = clientes || [];
          this.recibos = recibos || [];
          this.pagos = pagos || [];
          this.tarifas = tarifas || [];
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los reportes. Verifica el backend y tu sesión ADMIN.';
          this.cdr.detectChanges();
        }
      });
  }

  totalClientes(): number {
    return this.clientes.length;
  }

  totalSuministros(): number {
    return this.clientes.reduce(
      (total, cliente: any) => total + (cliente.suministros?.length ?? 0),
      0
    );
  }

  totalRecibos(): number {
    return this.recibos.length;
  }

  recibosPendientes(): number {
    return this.recibos.filter((r: any) => {
      return String(r.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((r: any) => {
      return String(r.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibos.filter((r: any) => {
      return String(r.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  totalRecaudado(): number {
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
    return this.totalEmitido() - this.totalRecaudado();
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

  porcentajePagados(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return (this.recibosPagados() / this.recibos.length) * 100;
  }

  porcentajePendientes(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibos.length) * 100;
  }

  tarifaPromedio(): number {
    if (this.tarifas.length === 0) {
      return 0;
    }

    const suma = this.tarifas.reduce((total, tarifa: any) => {
      return total + Number(tarifa.precioM3 || 0);
    }, 0);

    return suma / this.tarifas.length;
  }

  ultimosPagos(): PagoResponse[] {
    return [...this.pagos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 5);
  }

  ultimosRecibos(): ReciboResponse[] {
    return [...this.recibos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 5);
  }

  clientesConMasSuministros(): ClienteResponse[] {
    return [...this.clientes]
      .sort((a: any, b: any) => {
        return (b.suministros?.length ?? 0) - (a.suministros?.length ?? 0);
      })
      .slice(0, 5);
  }

  nombreCompleto(cliente: ClienteResponse): string {
    const c: any = cliente;
    return `${c.nombres || ''} ${c.apellidos || ''}`.trim() || 'Sin nombre';
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
    return `${this.nombreMes(r.mes)} ${r.anio}`;
  }

  exportarExcel(): void {
    const filas: any[][] = [];

    const filaTitulo = filas.length;
    filas.push(['JASS Huacariz']);

    const filaSubtitulo = filas.length;
    filas.push(['Reporte general del sistema de agua potable']);

    const filaFecha = filas.length;
    filas.push([`Fecha de emisión: ${new Date().toLocaleString('es-PE')}`]);

    filas.push([]);

    const filaResumenTitulo = filas.length;
    filas.push(['RESUMEN GENERAL']);

    const filaResumenCabecera = filas.length;
    filas.push(['Indicador', 'Valor', '', 'Indicador', 'Valor']);

    filas.push(['Total clientes', this.totalClientes(), '', 'Total suministros', this.totalSuministros()]);
    filas.push(['Total recibos', this.totalRecibos(), '', 'Total recaudado', `S/ ${this.totalRecaudado().toFixed(2)}`]);
    filas.push(['Recibos pendientes', this.recibosPendientes(), '', 'Recibos pagados', this.recibosPagados()]);
    filas.push(['Consumo total', `${this.consumoTotal().toFixed(3)} m³`, '', 'Consumo promedio', `${this.consumoPromedio().toFixed(3)} m³`]);
    filas.push(['Total emitido', `S/ ${this.totalEmitido().toFixed(2)}`, '', 'Saldo pendiente', `S/ ${this.saldoPendiente().toFixed(2)}`]);
    filas.push(['Tarifas registradas', this.tarifas.length, '', 'Precio promedio m³', `S/ ${this.tarifaPromedio().toFixed(2)}`]);

    filas.push([]);

    const filaRecibosTitulo = filas.length;
    filas.push(['ÚLTIMOS RECIBOS']);

    const filaRecibosCabecera = filas.length;
    filas.push(['Recibo', 'Suministro', 'Periodo', 'Consumo', 'Total', 'Estado']);

    this.ultimosRecibos().forEach((recibo: any) => {
      filas.push([
        recibo.codigoRecibo || '-',
        recibo.codigoSuministro || '-',
        `${this.nombreMes(recibo.mes)} ${recibo.anio}`,
        `${Number(recibo.consumoM3 || 0).toFixed(3)} m³`,
        `S/ ${Number(recibo.total || 0).toFixed(2)}`,
        recibo.estadoRecibo || '-'
      ]);
    });

    filas.push([]);

    const filaPagosTitulo = filas.length;
    filas.push(['ÚLTIMOS PAGOS']);

    const filaPagosCabecera = filas.length;
    filas.push(['Recibo', 'Método', 'Monto', 'Fecha']);

    this.ultimosPagos().forEach((pago: any) => {
      filas.push([
        pago.codigoRecibo || pago.reciboCodigo || '-',
        pago.metodoPago || pago.metodo || '-',
        `S/ ${Number(pago.monto || 0).toFixed(2)}`,
        pago.fechaPago || pago.fechaRegistro || pago.fecha || '-'
      ]);
    });

    filas.push([]);

    const filaClientesTitulo = filas.length;
    filas.push(['CLIENTES CON MÁS SUMINISTROS']);

    const filaClientesCabecera = filas.length;
    filas.push(['DNI', 'Cliente', 'Suministros', 'Estado']);

    this.clientesConMasSuministros().forEach((cliente: any) => {
      filas.push([
        cliente.dni || '-',
        this.nombreCompleto(cliente),
        cliente.suministros?.length || 0,
        cliente.estado === false ? 'Inactivo' : 'Activo'
      ]);
    });

    const worksheet: any = XLSX.utils.aoa_to_sheet(filas);

    worksheet['!cols'] = [
      { wch: 28 },
      { wch: 28 },
      { wch: 18 },
      { wch: 24 },
      { wch: 22 },
      { wch: 18 }
    ];

    worksheet['!merges'] = [
      { s: { r: filaTitulo, c: 0 }, e: { r: filaTitulo, c: 5 } },
      { s: { r: filaSubtitulo, c: 0 }, e: { r: filaSubtitulo, c: 5 } },
      { s: { r: filaFecha, c: 0 }, e: { r: filaFecha, c: 5 } },
      { s: { r: filaResumenTitulo, c: 0 }, e: { r: filaResumenTitulo, c: 5 } },
      { s: { r: filaRecibosTitulo, c: 0 }, e: { r: filaRecibosTitulo, c: 5 } },
      { s: { r: filaPagosTitulo, c: 0 }, e: { r: filaPagosTitulo, c: 5 } },
      { s: { r: filaClientesTitulo, c: 0 }, e: { r: filaClientesTitulo, c: 5 } }
    ];

    worksheet['!rows'] = [
      { hpt: 30 },
      { hpt: 22 },
      { hpt: 20 }
    ];

    this.estilizarReporteExcel(
      worksheet,
      filaTitulo,
      filaSubtitulo,
      filaFecha,
      filaResumenTitulo,
      filaResumenCabecera,
      filaRecibosTitulo,
      filaRecibosCabecera,
      filaPagosTitulo,
      filaPagosCabecera,
      filaClientesTitulo,
      filaClientesCabecera
    );

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Reporte general');

    const detalleRecibos = this.recibos.map((recibo: any) => ({
      'Código recibo': recibo.codigoRecibo || '',
      'Código suministro': recibo.codigoSuministro || '',
      'Periodo': `${this.nombreMes(recibo.mes)} ${recibo.anio}`,
      'Consumo m³': Number(recibo.consumoM3 || 0),
      'Subtotal agua': Number(recibo.subtotalAgua || 0),
      'Cargo mantenimiento': Number(recibo.cargoMantenimiento || 0),
      'Cargo lector': Number(recibo.cargoLector || 0),
      'Mora': Number(recibo.mora || 0),
      'Total': Number(recibo.total || 0),
      'Estado': recibo.estadoRecibo || '',
      'Fecha emisión': recibo.fechaEmision || '',
      'Fecha vencimiento': recibo.fechaVencimiento || ''
    }));

    const detallePagos = this.pagos.map((pago: any) => ({
      'Código recibo': pago.codigoRecibo || pago.reciboCodigo || '',
      'Método': pago.metodoPago || pago.metodo || '',
      'Monto': Number(pago.monto || 0),
      'Fecha': pago.fechaPago || pago.fechaRegistro || pago.fecha || '',
      'Operación': pago.codigoOperacion || pago.operacion || ''
    }));

    const detalleClientes = this.clientes.map((cliente: any) => ({
      'DNI': cliente.dni || '',
      'Cliente': this.nombreCompleto(cliente),
      'Teléfono': cliente.telefono || '',
      'Correo': cliente.correo || '',
      'Usuario': cliente.codigoUsuario || cliente.usuario || '',
      'Suministros': cliente.suministros?.length || 0,
      'Estado': cliente.estado === false ? 'Inactivo' : 'Activo'
    }));

    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detalleRecibos), 'Detalle recibos');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detallePagos), 'Detalle pagos');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detalleClientes), 'Detalle clientes');

    const fechaArchivo = new Date().toISOString().slice(0, 10);
    XLSX.writeFile(workbook, `reporte_general_jass_huacariz_${fechaArchivo}.xlsx`);
  }

  imprimirReporte(): void {
    const filasRecibos = this.ultimosRecibos().map((recibo: any) => `
      <tr>
        <td>${this.textoSeguro(recibo.codigoRecibo || '-')}</td>
        <td>${this.textoSeguro(recibo.codigoSuministro || '-')}</td>
        <td>${this.nombreMes(recibo.mes)} ${recibo.anio}</td>
        <td>${Number(recibo.consumoM3 || 0).toFixed(3)} m³</td>
        <td>S/ ${Number(recibo.total || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(recibo.estadoRecibo || '-')}</td>
      </tr>
    `).join('');

    const filasPagos = this.ultimosPagos().map((pago: any) => `
      <tr>
        <td>${this.textoSeguro(pago.codigoRecibo || pago.reciboCodigo || '-')}</td>
        <td>${this.textoSeguro(pago.metodoPago || pago.metodo || '-')}</td>
        <td>S/ ${Number(pago.monto || 0).toFixed(2)}</td>
        <td>${this.textoSeguro(pago.fechaPago || pago.fechaRegistro || pago.fecha || '-')}</td>
      </tr>
    `).join('');

    const filasClientes = this.clientesConMasSuministros().map((cliente: any) => `
      <tr>
        <td>${this.textoSeguro(cliente.dni || '-')}</td>
        <td>${this.textoSeguro(this.nombreCompleto(cliente))}</td>
        <td>${cliente.suministros?.length || 0}</td>
        <td>${cliente.estado === false ? 'Inactivo' : 'Activo'}</td>
      </tr>
    `).join('');

    const ventana = window.open('', '_blank', 'width=1200,height=850');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Reporte general - JASS Huacariz</title>

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

          h2 {
            margin: 24px 0 10px;
            font-size: 17px;
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
            margin-bottom: 20px;
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
            margin-bottom: 14px;
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
              <p>Reporte general del sistema de agua potable</p>
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
          <div class="card"><span>Total recibos</span><strong>${this.totalRecibos()}</strong></div>
          <div class="card"><span>Total recaudado</span><strong>S/ ${this.totalRecaudado().toFixed(2)}</strong></div>
          <div class="card"><span>Pendientes</span><strong>${this.recibosPendientes()}</strong></div>
          <div class="card"><span>Pagados</span><strong>${this.recibosPagados()}</strong></div>
          <div class="card"><span>Consumo total</span><strong>${this.consumoTotal().toFixed(3)} m³</strong></div>
          <div class="card"><span>Consumo promedio</span><strong>${this.consumoPromedio().toFixed(3)} m³</strong></div>
        </div>

        <h2>Últimos recibos</h2>
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

        <h2>Últimos pagos</h2>
        <table>
          <thead>
            <tr>
              <th>Recibo</th>
              <th>Método</th>
              <th>Monto</th>
              <th>Fecha</th>
            </tr>
          </thead>
          <tbody>
            ${filasPagos || '<tr><td colspan="4">Sin pagos registrados.</td></tr>'}
          </tbody>
        </table>

        <h2>Clientes con más suministros</h2>
        <table>
          <thead>
            <tr>
              <th>DNI</th>
              <th>Cliente</th>
              <th>Suministros</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            ${filasClientes || '<tr><td colspan="4">Sin clientes registrados.</td></tr>'}
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

  private crearHojaDetalle(data: any[]): any {
    const datos = data.length ? data : [{ Mensaje: 'Sin datos registrados' }];
    const worksheet: any = XLSX.utils.json_to_sheet(datos);
    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);

    worksheet['!cols'] = Array.from({ length: range.e.c + 1 }, () => ({ wch: 24 }));
    worksheet['!autofilter'] = { ref };

    const estilos = this.estilosExcel();

    this.aplicarEstiloRango(
      worksheet,
      0,
      0,
      0,
      range.e.c,
      estilos.cabeceraTabla
    );

    if (range.e.r >= 1) {
      this.aplicarEstiloRango(
        worksheet,
        1,
        0,
        range.e.r,
        range.e.c,
        estilos.celda
      );
    }

    return worksheet;
  }

  private estilizarReporteExcel(
    worksheet: any,
    filaTitulo: number,
    filaSubtitulo: number,
    filaFecha: number,
    filaResumenTitulo: number,
    filaResumenCabecera: number,
    filaRecibosTitulo: number,
    filaRecibosCabecera: number,
    filaPagosTitulo: number,
    filaPagosCabecera: number,
    filaClientesTitulo: number,
    filaClientesCabecera: number
  ): void {
    const estilos = this.estilosExcel();
    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);

    this.aplicarEstiloRango(worksheet, 0, 0, range.e.r, range.e.c, estilos.celda);

    this.aplicarEstiloRango(worksheet, filaTitulo, 0, filaTitulo, 5, estilos.titulo);
    this.aplicarEstiloRango(worksheet, filaSubtitulo, 0, filaSubtitulo, 5, estilos.subtitulo);
    this.aplicarEstiloRango(worksheet, filaFecha, 0, filaFecha, 5, estilos.fecha);

    this.aplicarEstiloRango(worksheet, filaResumenTitulo, 0, filaResumenTitulo, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaResumenCabecera, 0, filaResumenCabecera, 4, estilos.cabeceraTabla);
    this.aplicarEstiloRango(worksheet, filaResumenCabecera + 1, 0, filaResumenCabecera + 6, 4, estilos.resumen);

    this.aplicarEstiloRango(worksheet, filaRecibosTitulo, 0, filaRecibosTitulo, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaRecibosCabecera, 0, filaRecibosCabecera, 5, estilos.cabeceraTabla);

    this.aplicarEstiloRango(worksheet, filaPagosTitulo, 0, filaPagosTitulo, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaPagosCabecera, 0, filaPagosCabecera, 3, estilos.cabeceraTabla);

    this.aplicarEstiloRango(worksheet, filaClientesTitulo, 0, filaClientesTitulo, 5, estilos.seccion);
    this.aplicarEstiloRango(worksheet, filaClientesCabecera, 0, filaClientesCabecera, 3, estilos.cabeceraTabla);
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

  private nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] ?? 'Mes inválido';
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