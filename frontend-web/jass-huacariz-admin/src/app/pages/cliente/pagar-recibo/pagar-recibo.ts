import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

interface PagoClienteRequest {
  metodoPago: string;
  codigoOperacion: string;
}

@Component({
  selector: 'app-pagar-recibo',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './pagar-recibo.html',
  styleUrl: './pagar-recibo.scss',
})
export class PagarRecibo implements OnInit {
  recibo: ReciboClienteResponse | null = null;

  cargando = false;
  pagando = false;

  error = '';
  exito = '';

  mostrarConfirmacion = false;

  pago: PagoClienteRequest = {
    metodoPago: 'PagoEfectivo',
    codigoOperacion: ''
  };

  metodosPago = [
    'PagoEfectivo',
    'Transferencia',
    'Yape',
    'Plin',
    'Efectivo'
  ];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarRecibo();
  }

  cargarRecibo(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!id) {
      this.error = 'No se encontró el identificador del recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.listarMisRecibos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          const recibos = data || [];
          this.recibo = recibos.find((item) => Number(item.id) === id) || null;

          if (!this.recibo) {
            this.error = 'No se encontró el recibo solicitado.';
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la información del recibo.';
          this.recibo = null;
          this.cdr.detectChanges();
        }
      });
  }

  volver(): void {
    this.router.navigate(['/cliente/mis-recibos']);
  }

  irDetalle(): void {
    if (!this.recibo) {
      this.volver();
      return;
    }

    this.router.navigate(['/cliente/detalle-recibo', this.recibo.id]);
  }

  abrirConfirmacion(): void {
    this.error = '';
    this.exito = '';

    if (!this.recibo) {
      this.error = 'No hay recibo seleccionado.';
      return;
    }

    if (this.estaPagado()) {
      this.error = 'Este recibo ya se encuentra pagado.';
      return;
    }

    if (!this.pago.metodoPago.trim()) {
      this.error = 'Seleccione un método de pago.';
      return;
    }

    this.mostrarConfirmacion = true;
  }

  cerrarConfirmacion(): void {
    this.mostrarConfirmacion = false;
  }

  confirmarPago(): void {
    if (!this.recibo) {
      return;
    }

    const payload: PagoClienteRequest = {
      metodoPago: this.pago.metodoPago.trim(),
      codigoOperacion: this.pago.codigoOperacion.trim()
    };

    const servicio: any = this.clientePortal;

    let peticion: any = null;

    if (typeof servicio.pagarRecibo === 'function') {
      peticion = servicio.pagarRecibo(this.recibo.id, payload);
    } else if (typeof servicio.pagarMiRecibo === 'function') {
      peticion = servicio.pagarMiRecibo(this.recibo.id, payload);
    } else if (typeof servicio.pagarReciboCliente === 'function') {
      peticion = servicio.pagarReciboCliente(this.recibo.id, payload);
    } else if (typeof servicio.registrarPagoRecibo === 'function') {
      peticion = servicio.registrarPagoRecibo(this.recibo.id, payload);
    } else if (typeof servicio.registrarPago === 'function') {
      peticion = servicio.registrarPago(this.recibo.id, payload);
    }

    if (!peticion) {
      this.error = 'No se encontró el método de pago en cliente-portal.ts.';
      this.mostrarConfirmacion = false;
      return;
    }

    this.pagando = true;
    this.error = '';
    this.exito = '';

    peticion
      .pipe(
        finalize(() => {
          this.pagando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Pago registrado correctamente.';
          this.mostrarConfirmacion = false;

          if (this.recibo) {
            this.recibo.estadoRecibo = 'PAGADO';
          }

          setTimeout(() => {
            this.router.navigate(['/cliente/mis-recibos']);
          }, 900);

          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.error = err?.error?.error || err?.error?.message || 'No se pudo registrar el pago.';
          this.mostrarConfirmacion = false;
          this.cdr.detectChanges();
        }
      });
  }

  estaPagado(): boolean {
    return String(this.recibo?.estadoRecibo || '').toUpperCase() === 'PAGADO';
  }

  periodo(): string {
    if (!this.recibo) {
      return '-';
    }

    return `${this.nombreMes(Number(this.recibo.mes))} ${this.recibo.anio}`;
  }

  totalCargos(): number {
    if (!this.recibo) {
      return 0;
    }

    return Number(this.recibo.cargoMantenimiento || 0) +
      Number(this.recibo.cargoLector || 0) +
      Number(this.recibo.mora || 0);
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

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }
}