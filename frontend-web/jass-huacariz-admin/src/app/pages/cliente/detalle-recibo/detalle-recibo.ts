import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

@Component({
  selector: 'app-detalle-recibo',
  imports: [CommonModule, RouterModule],
  templateUrl: './detalle-recibo.html',
  styleUrl: './detalle-recibo.scss',
})
export class DetalleRecibo implements OnInit {
  recibo: ReciboClienteResponse | null = null;
  historialRecibos: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDetalle();
  }

  cargarDetalle(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!id) {
      this.error = 'No se encontró el identificador del recibo.';
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
        next: (data) => {
          this.historialRecibos = data || [];
          this.recibo = this.historialRecibos.find((item) => Number(item.id) === id) || null;

          if (!this.recibo) {
            this.error = 'No se encontró el recibo solicitado.';
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del recibo.';
          this.recibo = null;
          this.historialRecibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  volver(): void {
    this.router.navigate(['/cliente/mis-recibos']);
  }

  irPagar(): void {
    if (!this.recibo) {
      this.volver();
      return;
    }

    this.router.navigate(['/cliente/pagar-recibo', this.recibo.id]);
  }

  puedePagar(): boolean {
    if (!this.recibo) {
      return false;
    }

    return String(this.recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
  }

  periodo(): string {
    if (!this.recibo) {
      return '-';
    }

    return `${this.nombreMes(Number(this.recibo.mes))} ${this.recibo.anio}`;
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

  totalCargos(): number {
    if (!this.recibo) {
      return 0;
    }

    return Number(this.recibo.cargoMantenimiento || 0) +
      Number(this.recibo.cargoLector || 0) +
      Number(this.recibo.cargoOtros || 0) +
      Number(this.recibo.mora || 0);
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  imprimirRecibo(): void {
    if (!this.recibo) {
      return;
    }

    imprimirReciboJass(this.recibo, this.historialRecibos);
  }
}