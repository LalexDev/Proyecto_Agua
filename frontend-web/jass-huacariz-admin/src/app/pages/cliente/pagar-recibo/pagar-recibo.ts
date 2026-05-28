import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  PagoRequest,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

interface MetodoPagoCliente {
  valor: string;
  nombre: string;
  icono: string;
  descripcion: string;
  placeholder: string;
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

  pago: PagoRequest = {
    metodoPago: 'YAPE',
    codigoOperacion: ''
  };

  metodosPago: MetodoPagoCliente[] = [
    {
      valor: 'YAPE',
      nombre: 'Yape',
      icono: '📱',
      descripcion: 'Pago móvil con número de operación.',
      placeholder: 'Ejemplo: YAPE-123456'
    },
    {
      valor: 'PLIN',
      nombre: 'Plin',
      icono: '💜',
      descripcion: 'Pago móvil con constancia o número de operación.',
      placeholder: 'Ejemplo: PLIN-987654'
    },
    {
      valor: 'TRANSFERENCIA',
      nombre: 'Transferencia',
      icono: '🏦',
      descripcion: 'Transferencia bancaria o interbancaria.',
      placeholder: 'Ejemplo: OP-2026-001'
    },
    {
      valor: 'DEPOSITO',
      nombre: 'Depósito bancario',
      icono: '💳',
      descripcion: 'Depósito en agente, banco o plataforma autorizada.',
      placeholder: 'Ejemplo: DEP-000245'
    }
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

  seleccionarMetodo(metodo: MetodoPagoCliente): void {
    if (this.estaPagado()) {
      return;
    }

    this.pago.metodoPago = metodo.valor;
    this.pago.codigoOperacion = '';
    this.error = '';
  }

  metodoSeleccionado(): MetodoPagoCliente {
    return this.metodosPago.find((metodo) => metodo.valor === this.pago.metodoPago) || this.metodosPago[0];
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

    if (!this.pago.codigoOperacion || !this.pago.codigoOperacion.trim()) {
      this.error = 'Ingrese el código de operación del pago.';
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

    const payload: PagoRequest = {
      metodoPago: this.pago.metodoPago.trim(),
      codigoOperacion: this.pago.codigoOperacion.trim().toUpperCase()
    };

    this.pagando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.pagarMiRecibo(this.recibo.id, payload)
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
      Number(this.recibo.cargoOtros || 0) +
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