import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { forkJoin, finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import { Cliente, ClienteResponse } from '../../../core/services/cliente';
import { Recibo, ReciboResponse } from '../../../core/services/recibo';
import { Pago, PagoResponse } from '../../../core/services/pago';
import { Tarifa, TarifaResponse } from '../../../core/services/tarifa';

interface ResumenMetodoPago {
  metodo: string;
  cantidad: number;
  monto: number;
  porcentaje: number;
}

@Component({
  selector: 'app-reportes',
  imports: [CommonModule, FormsModule],
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

  anioFiltro = new Date().getFullYear();
  mesFiltro: number | 'TODOS' = new Date().getMonth() + 1;
  private readonly limiteReporte = 5000;

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

    const mesFiltro = this.mesFiltro === 'TODOS' ? '' : Number(this.mesFiltro);

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      recibos: this.reciboService.listarRecibos({
        anio: Number(this.anioFiltro),
        mes: mesFiltro,
        estado: 'TODOS',
        limit: this.limiteReporte
      }),
      pagos: this.pagoService.listarPagos('TODOS', {
        anio: Number(this.anioFiltro),
        mes: mesFiltro,
        limit: this.limiteReporte
      }),
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

  limpiarPeriodoActual(): void {
    this.anioFiltro = new Date().getFullYear();
    this.mesFiltro = new Date().getMonth() + 1;
    this.cargarReportes();
  }

  totalClientes(): number {
    return this.clientes.length;
  }

  clientesActivos(): number {
    return this.clientes.filter((cliente: any) => cliente.estado !== false).length;
  }

  clientesInactivos(): number {
    return this.clientes.filter((cliente: any) => cliente.estado === false).length;
  }

  totalSuministros(): number {
    return this.clientes.reduce((total: number, cliente: any) => {
      return total + (cliente.suministros?.length || 0);
    }, 0);
  }

  suministrosInstalados(): number {
    return this.clientes.reduce((total: number, cliente: any) => {
      const instalados = (cliente.suministros || []).filter((suministro: any) => {
        const estadoInstalacion = String(suministro.estadoInstalacion || '').toUpperCase();

        return suministro.estado !== false &&
          (estadoInstalacion === 'INSTALADO' || estadoInstalacion === '');
      }).length;

      return total + instalados;
    }, 0);
  }

  suministrosPendientes(): number {
    return Math.max(this.totalSuministros() - this.suministrosInstalados(), 0);
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

  totalRecaudado(): number {
    return this.pagos.reduce((total: number, pago: any) => {
      return total + Number(pago.monto || 0);
    }, 0);
  }

  totalEmitido(): number {
    return this.recibos.reduce((total: number, recibo: any) => {
      return total + Number(recibo.total || 0);
    }, 0);
  }

  saldoPendiente(): number {
    return Math.max(this.totalEmitido() - this.totalRecaudado(), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total: number, recibo: any) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  consumoPromedio(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return this.consumoTotal() / this.recibos.length;
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

  porcentajeRecaudado(): number {
    if (!this.totalEmitido()) {
      return 0;
    }

    return Math.min((this.totalRecaudado() / this.totalEmitido()) * 100, 100);
  }

  porcentajeSaldoPendiente(): number {
    if (!this.totalEmitido()) {
      return 0;
    }

    return Math.min((this.saldoPendiente() / this.totalEmitido()) * 100, 100);
  }

  tarifaPromedio(): number {
    if (!this.tarifas.length) {
      return 0;
    }

    const suma = this.tarifas.reduce((total: number, tarifa: any) => {
      return total + Number(tarifa.precioM3 || 0);
    }, 0);

    return suma / this.tarifas.length;
  }

  tarifasActivas(): number {
    return this.tarifas.filter((tarifa: any) => tarifa.estado !== false).length;
  }

  ultimosPagos(): PagoResponse[] {
    return [...this.pagos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 5);
  }

  ultimosRecibos(): ReciboResponse[] {
    return [...this.recibos]
      .sort((a: any, b: any) => Number(b.id || 0) - Number(a.id || 0))
      .slice(0, 6);
  }

  clientesConMasSuministros(): ClienteResponse[] {
    return [...this.clientes]
      .sort((a: any, b: any) => {
        return (b.suministros?.length || 0) - (a.suministros?.length || 0);
      })
      .slice(0, 5);
  }

  resumenMetodosPago(): ResumenMetodoPago[] {
    const mapa = new Map<string, { cantidad: number; monto: number }>();

    for (const pago of this.pagos as any[]) {
      const metodo = this.normalizarMetodo(pago.metodoPago);
      const actual = mapa.get(metodo) || { cantidad: 0, monto: 0 };

      actual.cantidad += 1;
      actual.monto += Number(pago.monto || 0);

      mapa.set(metodo, actual);
    }

    return Array.from(mapa.entries())
      .map(([metodo, data]) => ({
        metodo,
        cantidad: data.cantidad,
        monto: data.monto,
        porcentaje: this.pagos.length ? (data.cantidad / this.pagos.length) * 100 : 0
      }))
      .sort((a, b) => b.monto - a.monto);
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

  graficoRecaudacion(): string {
    const recaudado = this.porcentajeRecaudado();

    if (!this.totalEmitido()) {
      return 'conic-gradient(#e2e8f0 0% 100%)';
    }

    return `
      conic-gradient(
        #11a6c8 0% ${recaudado}%,
        #e2e8f0 ${recaudado}% 100%
      )
    `;
  }

  colorMetodo(index: number): string {
    const colores = ['#11a6c8', '#16a34a', '#f59e0b', '#7c3aed', '#dc2626', '#0f766e'];
    return colores[index % colores.length];
  }

  nombreCompleto(cliente: ClienteResponse): string {
    const c: any = cliente;
    return `${c.nombres || ''} ${c.apellidos || ''}`.trim() || 'Sin nombre';
  }

  estadoClase(estado: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado' || valor === 'activo') {
      return 'pagado';
    }

    if (valor === 'vencido' || valor === 'inactivo') {
      return 'vencido';
    }

    return 'pendiente';
  }

  periodo(recibo: ReciboResponse): string {
    const r: any = recibo;
    return `${this.nombreMes(Number(r.mes))} ${r.anio}`;
  }

  fechaPagoTexto(pago: PagoResponse): string {
    const item: any = pago;
    return item.fechaPago || item.fechaRegistro || item.fecha || '-';
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  exportarExcel(): void {
    const fechaArchivo = new Date().toISOString().slice(0, 10);

    const resumen = [
      ['AGUA POTABLE HUACARIZ - REPORTE GENERAL'],
      [`Fecha de emisión: ${new Date().toLocaleString('es-PE')}`],
      [],
      ['RESUMEN PRINCIPAL'],
      ['Indicador', 'Valor', '', 'Indicador', 'Valor'],
      ['Total clientes', this.totalClientes(), '', 'Total suministros', this.totalSuministros()],
      ['Clientes activos', this.clientesActivos(), '', 'Suministros instalados', this.suministrosInstalados()],
      ['Total recibos', this.totalRecibos(), '', 'Recibos pendientes', this.recibosPendientes()],
      ['Recibos pagados', this.recibosPagados(), '', 'Recibos vencidos', this.recibosVencidos()],
      ['Total emitido', Number(this.totalEmitido().toFixed(2)), '', 'Total recaudado', Number(this.totalRecaudado().toFixed(2))],
      ['Saldo pendiente', Number(this.saldoPendiente().toFixed(2)), '', 'Consumo total m³', Number(this.consumoTotal().toFixed(3))],
      ['Tarifas activas', this.tarifasActivas(), '', 'Precio promedio m³', Number(this.tarifaPromedio().toFixed(2))]
    ];

    const detalleRecibos = this.recibos.map((recibo: any) => ({
      'Código recibo': recibo.codigoRecibo || '',
      'Suministro': recibo.codigoSuministro || '',
      'Dirección': recibo.direccionSuministro || '',
      'Periodo': `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`,
      'Consumo m³': Number(recibo.consumoM3 || 0),
      'Subtotal agua': Number(recibo.subtotalAgua || 0),
      'Mantenimiento': Number(recibo.cargoMantenimiento || 0),
      'Cargo lector': Number(recibo.cargoLector || 0),
      'Otros cargos': Number(recibo.cargoOtros || 0),
      'Mora': Number(recibo.mora || 0),
      'Total': Number(recibo.total || 0),
      'Estado': recibo.estadoRecibo || '',
      'Emisión': recibo.fechaEmision || '',
      'Vencimiento': recibo.fechaVencimiento || ''
    }));

    const detallePagos = this.pagos.map((pago: any) => ({
      'Código recibo': pago.codigoRecibo || pago.reciboCodigo || '',
      'Método': pago.metodoPago || pago.metodo || '',
      'Código operación': pago.codigoOperacion || pago.operacion || '',
      'Monto': Number(pago.monto || 0),
      'Estado': pago.estadoPago || '',
      'Fecha pago': pago.fechaPago || pago.fechaRegistro || pago.fecha || ''
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

    const detalleTarifas = this.tarifas.map((tarifa: any) => ({
      'Nombre': tarifa.nombreTarifa || tarifa.nombre || '',
      'Desde m³': Number(tarifa.consumoDesde || 0),
      'Hasta m³': tarifa.consumoHasta ?? 'A más',
      'Precio m³': Number(tarifa.precioM3 || 0),
      'Estado': tarifa.estado === false ? 'Inactiva' : 'Activa'
    }));

    const workbook = XLSX.utils.book_new();

    XLSX.utils.book_append_sheet(workbook, this.crearHojaResumen(resumen), 'Resumen');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detalleRecibos), 'Recibos');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detallePagos), 'Pagos');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detalleClientes), 'Clientes');
    XLSX.utils.book_append_sheet(workbook, this.crearHojaDetalle(detalleTarifas), 'Tarifas');

    XLSX.writeFile(workbook, `reporte_general_agua_potable_huacariz_${fechaArchivo}.xlsx`);
  }

  imprimirReporte(): void {
    const filasRecibos = this.ultimosRecibos().map((recibo: any) => `
      <tr>
        <td>${this.textoSeguro(recibo.codigoRecibo || '-')}</td>
        <td>${this.textoSeguro(recibo.codigoSuministro || '-')}</td>
        <td>${this.periodo(recibo)}</td>
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

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Reporte general - Agua Potable Huacariz</title>
        <style>
          * { box-sizing: border-box; }

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
              <h1>Agua Potable Huacariz</h1>
              <p>Reporte general del sistema de agua potable</p>
              <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
            </div>
          </div>

          <strong>Administración</strong>
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
    `);
    ventana.document.close();
  }

  private crearHojaResumen(filas: any[][]): any {
    const worksheet: any = XLSX.utils.aoa_to_sheet(filas);

    worksheet['!cols'] = [
      { wch: 28 },
      { wch: 22 },
      { wch: 8 },
      { wch: 28 },
      { wch: 22 }
    ];

    worksheet['!merges'] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 4 } },
      { s: { r: 1, c: 0 }, e: { r: 1, c: 4 } },
      { s: { r: 2, c: 0 }, e: { r: 2, c: 4 } },
      { s: { r: 4, c: 0 }, e: { r: 4, c: 4 } }
    ];

    const ref = worksheet['!ref'] || 'A1:E1';
    const range = XLSX.utils.decode_range(ref);
    const styles = this.estilosExcel();

    this.aplicarEstiloRango(worksheet, 0, 0, range.e.r, range.e.c, styles.celda);
    this.aplicarEstiloRango(worksheet, 0, 0, 0, 4, styles.titulo);
    this.aplicarEstiloRango(worksheet, 1, 0, 1, 4, styles.subtitulo);
    this.aplicarEstiloRango(worksheet, 2, 0, 2, 4, styles.fecha);
    this.aplicarEstiloRango(worksheet, 4, 0, 4, 4, styles.seccion);
    this.aplicarEstiloRango(worksheet, 5, 0, 5, 4, styles.cabecera);

    return worksheet;
  }

  private crearHojaDetalle(data: any[]): any {
    const datos = data.length ? data : [{ Mensaje: 'Sin datos registrados' }];
    const worksheet: any = XLSX.utils.json_to_sheet(datos);
    const ref = worksheet['!ref'] || 'A1:A1';
    const range = XLSX.utils.decode_range(ref);
    const styles = this.estilosExcel();

    worksheet['!cols'] = Array.from({ length: range.e.c + 1 }, () => ({ wch: 24 }));
    worksheet['!autofilter'] = { ref };

    this.aplicarEstiloRango(worksheet, 0, 0, range.e.r, range.e.c, styles.celda);
    this.aplicarEstiloRango(worksheet, 0, 0, 0, range.e.c, styles.cabecera);

    return worksheet;
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
    const border = {
      top: { style: 'thin', color: { rgb: 'D9EAF0' } },
      bottom: { style: 'thin', color: { rgb: 'D9EAF0' } },
      left: { style: 'thin', color: { rgb: 'D9EAF0' } },
      right: { style: 'thin', color: { rgb: 'D9EAF0' } }
    };

    return {
      titulo: {
        font: { bold: true, sz: 18, color: { rgb: 'FFFFFF' } },
        fill: { fgColor: { rgb: '07384A' } },
        alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
        border
      },
      subtitulo: {
        font: { bold: true, sz: 12, color: { rgb: '0F2F3D' } },
        fill: { fgColor: { rgb: 'E8F7FB' } },
        alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
        border
      },
      fecha: {
        font: { italic: true, sz: 11, color: { rgb: '64748B' } },
        alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
        border
      },
      seccion: {
        font: { bold: true, sz: 13, color: { rgb: 'FFFFFF' } },
        fill: { fgColor: { rgb: '1BA3C7' } },
        alignment: { horizontal: 'left', vertical: 'center', wrapText: true },
        border
      },
      cabecera: {
        font: { bold: true, color: { rgb: '0F2F3D' } },
        fill: { fgColor: { rgb: 'E8F7FB' } },
        alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
        border
      },
      celda: {
        alignment: { vertical: 'center', wrapText: true },
        border
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


  normalizarMetodo(metodo: string): string {
  const valor = String(metodo || '').trim().toLowerCase();

  if (valor === 'yape') return 'Yape';
  if (valor === 'plin') return 'Plin';
  if (valor === 'efectivo' || valor === 'pagoefectivo') return 'Efectivo';
  if (valor === 'transferencia') return 'Transferencia';

    return metodo || 'Sin método';
  }
}
