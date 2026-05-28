import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { PagoRequest, Recibo, ReciboResponse } from '../../../core/services/recibo';
import { imprimirReciboJass } from '../../../core/utils/recibo-print';

@Component({
  selector: 'app-recibos',
  imports: [CommonModule, FormsModule],
  templateUrl: './recibos.html',
  styleUrl: './recibos.scss',
})
export class Recibos implements OnInit {
  recibos: ReciboResponse[] = [];
  recibosFiltrados: ReciboResponse[] = [];

  cargando = false;
  pagando = false;
  error = '';
  exito = '';

  filtroEstado = 'TODOS';
  busqueda = '';

  reciboSeleccionado: any = null;
  reciboDetalle: any = null;

  pago: PagoRequest = {
    metodoPago: 'PagoEfectivo',
    codigoOperacion: ''
  };

  constructor(
    private reciboService: Recibo,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarRecibos();
  }

  cargarRecibos(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.reciboService.listarRecibos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.recibos = data || [];
          this.aplicarFiltros();
          this.exito = 'Recibos actualizados correctamente.';
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los recibos. Verifica el backend y tu sesión ADMIN.';
          this.exito = '';
          this.recibos = [];
          this.recibosFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const textoBusqueda = this.busqueda.trim().toLowerCase();

    this.recibosFiltrados = this.recibos.filter((recibo: any) => {
      const estado = String(recibo.estadoRecibo || '').toUpperCase();

      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        this.filtroEstado === '' ||
        estado === this.filtroEstado;

      const coincideTexto =
        !textoBusqueda ||
        String(recibo.codigoRecibo || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.codigoSuministro || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.direccionSuministro || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.aliasSuministro || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.nombreCliente || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.dniCliente || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.sector || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.estadoRecibo || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.total || '').toLowerCase().includes(textoBusqueda) ||
        String(recibo.consumoM3 || '').toLowerCase().includes(textoBusqueda) ||
        this.periodo(recibo).toLowerCase().includes(textoBusqueda);

      return coincideEstado && coincideTexto;
    });
  }

  filtrarRecibos(): void {
    this.aplicarFiltros();
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = 'TODOS';
    this.aplicarFiltros();
  }

  abrirDetalleRecibo(recibo: ReciboResponse): void {
    this.reciboDetalle = recibo;
    this.error = '';
    this.exito = '';
  }

  cerrarDetalleRecibo(): void {
    this.reciboDetalle = null;
  }

  imprimirRecibo(recibo: ReciboResponse): void {
    imprimirReciboJass(recibo, this.recibos);
  }

  abrirPago(recibo: ReciboResponse): void {
    if (String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO') {
      this.error = 'Este recibo ya se encuentra pagado.';
      this.exito = '';
      return;
    }

    this.reciboSeleccionado = recibo;

    this.pago = {
      metodoPago: 'PagoEfectivo',
      codigoOperacion: ''
    };

    this.error = '';
    this.exito = '';
  }

  cerrarPago(): void {
    this.reciboSeleccionado = null;

    this.pago = {
      metodoPago: 'PagoEfectivo',
      codigoOperacion: ''
    };
  }

  confirmarPago(): void {
    if (!this.reciboSeleccionado) {
      return;
    }

    if (!this.pago.metodoPago || !this.pago.metodoPago.trim()) {
      this.error = 'Seleccione o ingrese el método de pago.';
      this.exito = '';
      return;
    }

    this.pagando = true;
    this.error = '';
    this.exito = '';

    const payload: PagoRequest = {
      metodoPago: this.pago.metodoPago.trim(),
      codigoOperacion: this.pago.codigoOperacion?.trim() || ''
    };

    this.reciboService.pagarRecibo(this.reciboSeleccionado.id, payload)
      .pipe(
        finalize(() => {
          this.pagando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (response) => {
          this.exito = `Pago registrado correctamente. Recibo: ${response.codigoRecibo}`;
          this.cerrarPago();
          this.cargarRecibos();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar el pago.';
          this.exito = '';
          this.cdr.detectChanges();
        }
      });
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

  totalEmitido(): number {
    return this.recibos.reduce((total: number, recibo: any) => {
      return total + Number(recibo.total || 0);
    }, 0);
  }

  saldoPendiente(): number {
    return this.recibos
      .filter((recibo: any) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total: number, recibo: any) => {
        return total + Number(recibo.total || 0);
      }, 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total: number, recibo: any) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  porcentajePagados(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosPagados() / this.totalRecibos()) * 100;
  }

  porcentajePendientes(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosPendientes() / this.totalRecibos()) * 100;
  }

  porcentajeVencidos(): number {
    if (this.totalRecibos() === 0) {
      return 0;
    }

    return (this.recibosVencidos() / this.totalRecibos()) * 100;
  }

  graficoEstados(): string {
    if (this.totalRecibos() === 0) {
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

  periodo(recibo: ReciboResponse): string {
    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }
}