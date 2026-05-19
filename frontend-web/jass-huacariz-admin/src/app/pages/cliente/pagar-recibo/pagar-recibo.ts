import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  PagoClienteRequest,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-pagar-recibo',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './pagar-recibo.html',
  styleUrl: './pagar-recibo.scss',
})
export class PagarRecibo implements OnInit {
  recibo: ReciboClienteResponse | null = null;

  pago: PagoClienteRequest = {
    metodoPago: 'PagoEfectivo',
    codigoOperacion: ''
  };

  cargando = false;
  pagando = false;
  error = '';
  exito = '';

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
      this.error = 'No se encontró el recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';

    this.clientePortal.listarMisRecibos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (recibos) => {
          const encontrado = recibos.find(r => r.id === id);

          if (!encontrado) {
            this.error = 'No se encontró el recibo solicitado.';
            this.recibo = null;
            this.cdr.detectChanges();
            return;
          }

          this.recibo = encontrado;
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el recibo.';
          this.cdr.detectChanges();
        }
      });
  }

  confirmarPago(): void {
    if (!this.recibo) {
      return;
    }

    if (this.recibo.estadoRecibo === 'PAGADO') {
      this.error = 'Este recibo ya se encuentra pagado.';
      return;
    }

    if (!this.pago.metodoPago.trim()) {
      this.error = 'Seleccione un método de pago.';
      return;
    }

    if (!this.pago.codigoOperacion.trim()) {
      this.error = 'Ingrese el código de operación.';
      return;
    }

    this.pagando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.pagarMiRecibo(this.recibo.id, {
      metodoPago: this.pago.metodoPago.trim(),
      codigoOperacion: this.pago.codigoOperacion.trim()
    })
    .pipe(
      finalize(() => {
        this.pagando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: () => {
        this.exito = 'Pago registrado correctamente.';
        this.cdr.detectChanges();

        setTimeout(() => {
          this.router.navigate(['/cliente/mis-recibos']);
        }, 1200);
      },
      error: (err) => {
        this.error = err?.error?.error || 'No se pudo registrar el pago.';
        this.cdr.detectChanges();
      }
    });
  }

  periodo(): string {
    if (!this.recibo) {
      return '';
    }

    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return `${meses[this.recibo.mes - 1] ?? 'Mes'} ${this.recibo.anio}`;
  }
}