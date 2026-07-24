import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { Pago, PagoResponse } from '../../../core/services/pago';

interface MetodoResumen {
  metodo: string;
  cantidad: number;
  monto: number;
  porcentaje: number;
}

@Component({
  selector: 'app-pagos',
  imports: [CommonModule, FormsModule],
  templateUrl: './pagos.html',
  styleUrl: './pagos.scss',
})
export class Pagos implements OnInit {
  pagos: PagoResponse[] = [];
  pagosFiltrados: PagoResponse[] = [];
  estadoFiltro = 'TODOS';
  filtroAnio: number | '' = new Date().getFullYear();
  filtroMes: number | '' = new Date().getMonth() + 1;
  private readonly limiteInicial = 200;
  private readonly limiteFiltrado = 5000;
  filtrosCompletosAplicados = false;
  private debounceBusqueda: any;

  cargando = false;
  error = '';
  exito = '';
  busqueda = '';
  comprobanteSeleccionado = '';

  modalConfirmacionAbierto = false;
    accionPendiente: 'aprobar' | 'rechazar' | null = null;
    pagoPendiente: PagoResponse | null = null;

    tituloConfirmacion = '';
    mensajeConfirmacion = '';
    textoBotonConfirmar = '';
    claseConfirmacion = '';

  constructor(
    private pagoService: Pago,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarPagos();
  }

  get limiteRegistros(): number {
    return this.filtrosCompletosAplicados ? this.limiteFiltrado : this.limiteInicial;
  }

cargarPagos(): void {
  this.cargando = true;
  this.error = '';
  this.exito = '';

  this.pagoService.listarPagos(this.estadoFiltro, {
    anio: this.filtroAnio,
    mes: this.filtroMes,
    buscar: this.busqueda,
    limit: this.limiteRegistros
  })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: (data) => {
        this.pagos = data || [];
        this.pagosFiltrados = this.pagos;
        this.mostrarExito('Pagos actualizados correctamente.');
        this.cdr.detectChanges();
      },
      error: () => {
        this.mostrarError('No se pudieron cargar los pagos.');
        this.exito = '';
        this.pagos = [];
        this.pagosFiltrados = [];
        this.cdr.detectChanges();
      }
    });
}
  filtrarPagos(): void {
    this.filtrosCompletosAplicados = true;
    clearTimeout(this.debounceBusqueda);
    this.debounceBusqueda = setTimeout(() => {
      this.cargarPagos();
    }, 350);
  }

  aplicarFiltroCompleto(): void {
    this.filtrosCompletosAplicados = true;
    this.cargarPagos();
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.estadoFiltro = 'TODOS';
    this.filtroAnio = new Date().getFullYear();
    this.filtroMes = new Date().getMonth() + 1;
    this.filtrosCompletosAplicados = false;
    this.cargarPagos();
  }

  totalPagos(): number {
    return this.pagosFiltrados.length;
  }

  montoTotalPagado(): number {
    return this.pagosFiltrados.reduce((total: number, pago: any) => {
      return total + Number(pago.monto || 0);
    }, 0);
  }

  pagosDelMes(): number {
    const hoy = new Date();
    const mesActual = hoy.getMonth();
    const anioActual = hoy.getFullYear();

    return this.pagosFiltrados.filter((pago: any) => {
      const fecha = this.obtenerFechaPago(pago);

      if (!fecha) {
        return false;
      }

      return fecha.getMonth() === mesActual && fecha.getFullYear() === anioActual;
    }).length;
  }

  montoPromedio(): number {
    if (!this.pagosFiltrados.length) {
      return 0;
    }

    return this.montoTotalPagado() / this.pagosFiltrados.length;
  }

  metodoMasUsado(): string {
    const resumen = this.resumenMetodos();

    if (!resumen.length) {
      return 'Sin datos';
    }

    return this.normalizarMetodo(resumen[0].metodo);
  }

  resumenMetodos(): MetodoResumen[] {
    const contador: Record<string, { cantidad: number; monto: number }> = {};

    this.pagosFiltrados.forEach((pago: any) => {
      const metodo = this.normalizarMetodo(pago.metodoPago);

      if (!contador[metodo]) {
        contador[metodo] = {
          cantidad: 0,
          monto: 0
        };
      }

      contador[metodo].cantidad += 1;
      contador[metodo].monto += Number(pago.monto || 0);
    });

    const total = this.pagosFiltrados.length || 1;

    return Object.keys(contador)
      .map((metodo) => ({
        metodo,
        cantidad: contador[metodo].cantidad,
        monto: contador[metodo].monto,
        porcentaje: (contador[metodo].cantidad / total) * 100
      }))
      .sort((a, b) => b.cantidad - a.cantidad);
  }

  graficoMetodos(): string {
    const resumen = this.resumenMetodos();

    if (!resumen.length) {
      return 'conic-gradient(#e2e8f0 0% 100%)';
    }

    const colores = ['#17a7d4', '#16a34a', '#f59e0b', '#dc2626', '#6366f1', '#14b8a6'];

    let inicio = 0;

    const partes = resumen.map((item, index) => {
      const fin = inicio + item.porcentaje;
      const color = colores[index % colores.length];
      const parte = `${color} ${inicio}% ${fin}%`;
      inicio = fin;
      return parte;
    });

    return `conic-gradient(${partes.join(', ')})`;
  }

  colorMetodo(index: number): string {
    const colores = ['#17a7d4', '#16a34a', '#f59e0b', '#dc2626', '#6366f1', '#14b8a6'];
    return colores[index % colores.length];
  }

  fechaPagoTexto(pago: PagoResponse): string {
    const fecha = this.obtenerFechaPago(pago);

    if (!fecha) {
      return '-';
    }

    return fecha.toLocaleString('es-PE');
  }

  private obtenerFechaPago(pago: any): Date | null {
    const valor = pago.fechaPago || pago.fechaRegistro || pago.fecha || pago.createdAt;

    if (!valor) {
      return null;
    }

    const fecha = new Date(valor);

    if (isNaN(fecha.getTime())) {
      return null;
    }

    return fecha;
  }


  normalizarMetodo(metodo: string): string {
  const valor = String(metodo || '').trim().toLowerCase();

  if (valor === 'yape') return 'Yape';
  if (valor === 'plin') return 'Plin';
  if (valor === 'efectivo' || valor === 'pagoefectivo') return 'Efectivo';
  if (valor === 'transferencia') return 'Transferencia';

    return metodo || 'Sin método';
  }


  private mostrarExito(mensaje: string): void {
  this.exito = mensaje;

    setTimeout(() => {
      this.exito = '';
      this.cdr.detectChanges();
    }, 1000); // 3 segundos
  }


  private mostrarError(mensaje: string): void {
  this.error = mensaje;

    setTimeout(() => {
      this.error = '';
      this.cdr.detectChanges();
    }, 5000); // 5 segundos
    
  }

  abrirConfirmacionAprobar(pago: PagoResponse): void {
  this.modalConfirmacionAbierto = true;
  this.accionPendiente = 'aprobar';
  this.pagoPendiente = pago;

  this.tituloConfirmacion = 'Confirmar pago';
  this.mensajeConfirmacion = `¿Deseas aprobar el pago del recibo ${pago.codigoRecibo}?`;
  this.textoBotonConfirmar = 'Sí, aprobar';
  this.claseConfirmacion = 'aprobar';
}

abrirConfirmacionRechazar(pago: PagoResponse): void {
  this.modalConfirmacionAbierto = true;
  this.accionPendiente = 'rechazar';
  this.pagoPendiente = pago;

  this.tituloConfirmacion = 'Rechazar pago';
  this.mensajeConfirmacion = `¿Deseas rechazar el pago del recibo ${pago.codigoRecibo}?`;
  this.textoBotonConfirmar = 'Sí, rechazar';
  this.claseConfirmacion = 'rechazar';
}

cerrarModalConfirmacion(): void {
  this.modalConfirmacionAbierto = false;
  this.accionPendiente = null;
  this.pagoPendiente = null;
  this.tituloConfirmacion = '';
  this.mensajeConfirmacion = '';
  this.textoBotonConfirmar = '';
  this.claseConfirmacion = '';
}

confirmarAccionPago(): void {
  if (!this.pagoPendiente || !this.accionPendiente) {
    return;
  }

  const id = this.pagoPendiente.id;

  if (this.accionPendiente === 'aprobar') {
    this.pagoService.aprobarPago(id).subscribe({
      next: () => {
        this.mostrarExito('Pago aprobado correctamente.');
        this.cerrarModalConfirmacion();
        this.cargarPagos();
      },
      error: () => {
        this.mostrarError('No fue posible aprobar el pago.');
      }
    });
    return;
  }

  if (this.accionPendiente === 'rechazar') {
    this.pagoService.rechazarPago(id).subscribe({
      next: () => {
        this.mostrarExito('Pago rechazado correctamente.');
        this.cerrarModalConfirmacion();
        this.cargarPagos();
      },
      error: () => {
        this.mostrarError('No fue posible rechazar el pago.');
      }
    });
  }
}

  verComprobante(pago: PagoResponse): void {
    if (!pago.comprobanteUrl) {
      this.mostrarError('Este pago no tiene comprobante adjunto.');
      return;
    }

    this.comprobanteSeleccionado = this.urlComprobante(pago.comprobanteUrl);
  }

  cerrarComprobante(): void {
    this.comprobanteSeleccionado = '';
  }

  urlComprobante(url: string): string {
    if (!url) {
      return '';
    }

    if (url.startsWith('http')) {
      return url;
    }

    return `${url}`;
  }

  cambiarFiltroEstado(): void {
    this.aplicarFiltroCompleto();
  }
}
