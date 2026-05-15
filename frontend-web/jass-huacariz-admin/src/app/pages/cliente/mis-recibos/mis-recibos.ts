import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-mis-recibos',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './mis-recibos.html',
  styleUrl: './mis-recibos.scss',
})
export class MisRecibos implements OnInit {
  recibos: ReciboClienteResponse[] = [];
  recibosFiltrados: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  filtroEstado = 'TODOS';
  busqueda = '';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarRecibos();
  }

  cargarRecibos(): void {
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
          this.recibos = data;
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar tus recibos.';
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.recibosFiltrados = this.recibos.filter(recibo => {
      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        recibo.estadoRecibo === this.filtroEstado;

      const coincideTexto =
        !texto ||
        recibo.codigoRecibo.toLowerCase().includes(texto) ||
        recibo.codigoSuministro.toLowerCase().includes(texto) ||
        recibo.direccionSuministro.toLowerCase().includes(texto);

      return coincideEstado && coincideTexto;
    });
  }

  recibosPendientes(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PENDIENTE').length;
  }

  recibosPagados(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PAGADO').length;
  }

  totalPendiente(): number {
    return this.recibos
      .filter(r => r.estadoRecibo === 'PENDIENTE')
      .reduce((total, recibo) => total + Number(recibo.total), 0);
  }

  totalPagado(): number {
    return this.recibos
      .filter(r => r.estadoRecibo === 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total), 0);
  }

  estadoClase(estado: string): string {
    return estado?.toLowerCase() === 'pagado' ? 'pagado' : 'pendiente';
  }

  periodo(recibo: ReciboClienteResponse): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return `${meses[recibo.mes - 1] ?? 'Mes'} ${recibo.anio}`;
  }
}