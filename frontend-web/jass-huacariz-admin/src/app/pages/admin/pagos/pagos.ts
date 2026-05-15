import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { Pago, PagoResponse } from '../../../core/services/pago';

@Component({
  selector: 'app-pagos',
  imports: [CommonModule, FormsModule],
  templateUrl: './pagos.html',
  styleUrl: './pagos.scss',
})
export class Pagos implements OnInit {
  pagos: PagoResponse[] = [];
  pagosFiltrados: PagoResponse[] = [];

  cargando = false;
  error = '';
  busqueda = '';

  constructor(
    private pagoService: Pago,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarPagos();
  }

  cargarPagos(): void {
    this.cargando = true;
    this.error = '';

    this.pagoService.listarPagos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.pagos = data;
          this.pagosFiltrados = data;
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los pagos. Verifica el backend y tu sesión ADMIN.';
          this.cdr.detectChanges();
        }
      });
  }

  filtrarPagos(): void {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      this.pagosFiltrados = this.pagos;
      return;
    }

    this.pagosFiltrados = this.pagos.filter(pago =>
      pago.codigoRecibo.toLowerCase().includes(texto) ||
      pago.metodoPago.toLowerCase().includes(texto) ||
      (pago.codigoOperacion || '').toLowerCase().includes(texto)
    );
  }

  totalRecaudado(): number {
    return this.pagos.reduce((total, pago) => total + Number(pago.monto), 0);
  }

  totalPagos(): number {
    return this.pagos.length;
  }

  pagosPagoEfectivo(): number {
    return this.pagos.filter(p => p.metodoPago === 'PagoEfectivo').length;
  }

  estadoClase(estado: string): string {
    return estado?.toLowerCase() === 'pagado' ? 'pagado' : 'pendiente';
  }
}