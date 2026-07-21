import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize, forkJoin } from 'rxjs';

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
    metodoPago: 'Efectivo',
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

            setTimeout(() => {
              this.exito = '';
              this.cdr.detectChanges();
            }, 2000);

            this.cdr.detectChanges();
          },
                  error: () => {
          this.error = 'No se pudieron cargar los recibos. Verifica el backend y tu sesiÃ³n ADMIN.';
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
    this.reciboSeleccionado = null;
    this.pagoMultipleAbierto = false;
    this.pagando = false;

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

    this.reciboDetalle = null;
    this.pagoMultipleAbierto = false;
    this.pagando = false;

    this.reciboSeleccionado = recibo;

    this.pago = {
      metodoPago: 'Efectivo',
      codigoOperacion: ''
    };

    this.error = '';
    this.exito = '';
  }

  cerrarPago(): void {
    this.reciboSeleccionado = null;
    this.pagando = false;

    this.pago = {
      metodoPago: 'Efectivo',
      codigoOperacion: ''
    };
  }

  confirmarPago(): void {
    if (!this.reciboSeleccionado) {
      return;
    }

    if (!this.pago.metodoPago || !this.pago.metodoPago.trim()) {
      this.error = 'Seleccione o ingrese el mÃ©todo de pago.';
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

    return meses[mes - 1] || 'Mes invÃ¡lido';
  }


  enviarWhatsApp(recibo: any): void {
  const telefono = this.obtenerTelefonoCliente(recibo);

  if (!telefono) {
    this.error = 'Este cliente no tiene telÃ©fono registrado para enviar WhatsApp.';
    this.exito = '';
    return;
  }

  const enlacePortal = 'https://qnsdd0d9-4200.brs.devtunnels.ms/cliente/mis-recibos';

  const mensaje = `ðŸ’§ *AGUA POTABLE HUACARIZ - NOTIFICACIÃ“N DE RECIBO*

Estimado(a) *${recibo.nombreCliente || 'usuario'}*:

Le informamos que su recibo de agua potable correspondiente a *${this.periodo(recibo)}* ya fue generado.

ðŸ“„ CÃ³digo de recibo: *${recibo.codigoRecibo || '-'}*
ðŸ  Suministro: *${recibo.codigoSuministro || '-'}*
ðŸ’° Total a pagar: *S/ ${Number(recibo.total || 0).toFixed(2)}*
ðŸ“… Fecha de vencimiento: *${recibo.fechaVencimiento || '-'}*

âš ï¸ Por favor realice su pago dentro del plazo establecido de 15 dÃ­as para evitar mora o restricciones del servicio.

ðŸ”— Consulte su recibo aquÃ­:
${enlacePortal}

*AGUA POTABLE HUACARIZ*
Servicio de Agua Potable`;

  const url = `https://wa.me/51${telefono}?text=${encodeURIComponent(mensaje)}`;

  window.open(url, '_blank');
}

obtenerTelefonoCliente(recibo: any): string {
  const telefono = String(
    recibo.telefonoCliente ||
    recibo.telefono ||
    recibo.celularCliente ||
    recibo.celular ||
    ''
  ).replace(/\D/g, '');

  if (telefono.length === 9) {
    return telefono;
  }

  if (telefono.length > 9) {
    return telefono.slice(-9);
  }

  return '';
}

  idsSeleccionados: number[] = [];
  pagoMultipleAbierto = false;

  pagoMultiple: PagoRequest = {
    metodoPago: 'Efectivo',
    codigoOperacion: ''
  };

  esReciboSeleccionable(recibo: ReciboResponse): boolean {
  const estado = String(recibo.estadoRecibo || '').toUpperCase();
  return estado === 'PENDIENTE' || estado === 'VENCIDO';
}

estaSeleccionado(recibo: ReciboResponse): boolean {
  return this.idsSeleccionados.includes(recibo.id);
}

alternarSeleccion(recibo: ReciboResponse): void {
  if (!this.esReciboSeleccionable(recibo)) {
    return;
  }

  if (this.estaSeleccionado(recibo)) {
    this.idsSeleccionados = this.idsSeleccionados.filter(id => id !== recibo.id);
  } else {
    this.idsSeleccionados = [...this.idsSeleccionados, recibo.id];
  }
}

seleccionarTodosFiltrados(): void {
  const ids = this.recibosFiltrados
    .filter(recibo => this.esReciboSeleccionable(recibo))
    .map(recibo => recibo.id);

  this.idsSeleccionados = Array.from(new Set([...this.idsSeleccionados, ...ids]));
}

limpiarSeleccion(): void {
  this.idsSeleccionados = [];
}

recibosSeleccionados(): ReciboResponse[] {
  return this.recibos.filter(recibo => this.idsSeleccionados.includes(recibo.id));
}

cantidadSeleccionados(): number {
  return this.idsSeleccionados.length;
}

totalSeleccionado(): number {
  return this.recibosSeleccionados().reduce((total, recibo) => {
    return total + Number(recibo.total || 0);
  }, 0);
}

abrirPagoMultiple(): void {
  if (this.idsSeleccionados.length === 0) {
    this.error = 'Seleccione al menos un recibo pendiente o vencido.';
    this.exito = '';
    return;
  }

  this.reciboDetalle = null;
  this.reciboSeleccionado = null;
  this.pagando = false;

  this.pagoMultipleAbierto = true;

  this.pagoMultiple = {
    metodoPago: 'Efectivo',
    codigoOperacion: ''
  };

  this.error = '';
  this.exito = '';
}

cerrarPagoMultiple(): void {
  this.pagoMultipleAbierto = false;
  this.pagando = false;

  this.pagoMultiple = {
    metodoPago: 'Efectivo',
    codigoOperacion: ''
  };
}

confirmarPagoMultiple(): void {
  const seleccionados = this.recibosSeleccionados();

  if (seleccionados.length === 0) {
    this.error = 'No hay recibos seleccionados para pagar.';
    this.exito = '';
    return;
  }

  if (!this.pagoMultiple.metodoPago || !this.pagoMultiple.metodoPago.trim()) {
    this.error = 'Seleccione el mÃ©todo de pago.';
    this.exito = '';
    return;
  }

  const metodo = this.pagoMultiple.metodoPago.trim();
  const codigoBase = this.pagoMultiple.codigoOperacion?.trim() || '';
  const esEfectivo = metodo.toLowerCase() === 'efectivo';

  if (!esEfectivo && !codigoBase) {
    this.error = 'Ingrese el cÃ³digo de operaciÃ³n para Yape, Plin o Transferencia.';
    this.exito = '';
    return;
  }

  this.pagando = true;
  this.error = '';
  this.exito = '';

  const marca = Date.now();

  const peticiones = seleccionados.map((recibo, index) => {
    const codigoOperacion = esEfectivo
      ? `EFECTIVO-MASIVO-${marca}-${recibo.id}`
      : `${codigoBase}-${recibo.codigoRecibo || recibo.id}`;

    const payload: PagoRequest = {
      metodoPago: metodo,
      codigoOperacion
    };

    return this.reciboService.pagarRecibo(recibo.id, payload);
  });

  forkJoin(peticiones)
    .pipe(
      finalize(() => {
        this.pagando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: () => {
        const cantidad = seleccionados.length;
        const total = this.totalSeleccionado();

        this.exito = `Pago mÃºltiple registrado correctamente. ${cantidad} recibo(s) por S/ ${total.toFixed(2)}.`;
        this.cerrarPagoMultiple();
        this.limpiarSeleccion();
        this.cargarRecibos();
      },
      error: (err) => {
        this.error = err?.error?.error || 'No se pudo registrar el pago mÃºltiple.';
        this.exito = '';
        this.cdr.detectChanges();
      }
    });
  }


  abrirPagoDesdeDetalle(): void {
    if (!this.reciboDetalle) {
      return;
    }

    const recibo = { ...this.reciboDetalle };

    this.reciboDetalle = null;
    this.pagoMultipleAbierto = false;
    this.pagando = false;

    this.reciboSeleccionado = recibo;

    this.pago = {
      metodoPago: 'Efectivo',
      codigoOperacion: ''
    };

    this.error = '';
    this.exito = '';
  }
}
