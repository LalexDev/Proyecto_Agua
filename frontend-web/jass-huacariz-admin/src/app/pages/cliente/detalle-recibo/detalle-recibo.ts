import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-detalle-recibo',
  imports: [CommonModule, RouterModule],
  templateUrl: './detalle-recibo.html',
  styleUrl: './detalle-recibo.scss',
})
export class DetalleRecibo implements OnInit {
  recibo: ReciboClienteResponse | null = null;

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
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
          this.error = 'No se pudo cargar el detalle del recibo.';
          this.cdr.detectChanges();
        }
      });
  }

  estadoClase(estado: string): string {
    return estado?.toLowerCase() === 'pagado' ? 'pagado' : 'pendiente';
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

  puedePagar(): boolean {
    return this.recibo?.estadoRecibo === 'PENDIENTE';
  }
}