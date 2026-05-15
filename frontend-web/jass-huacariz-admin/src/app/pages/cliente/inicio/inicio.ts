import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePerfilResponse,
  ClientePortal,
  ReciboClienteResponse,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-inicio',
  imports: [CommonModule, RouterModule],
  templateUrl: './inicio.html',
  styleUrl: './inicio.scss',
})
export class Inicio implements OnInit {
  perfil: ClientePerfilResponse | null = null;
  suministros: SuministroClienteResponse[] = [];
  recibos: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarInicio();
  }

  cargarInicio(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      perfil: this.clientePortal.obtenerMiPerfil(),
      suministros: this.clientePortal.listarMisSuministros(),
      recibos: this.clientePortal.listarMisRecibos()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: ({ perfil, suministros, recibos }) => {
        this.perfil = perfil;
        this.suministros = suministros;
        this.recibos = recibos;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo cargar la información del cliente.';
        this.cdr.detectChanges();
      }
    });
  }

  recibosPendientes(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PENDIENTE').length;
  }

  recibosPagados(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PAGADO').length;
  }

  deudaTotal(): number {
    return this.recibos
      .filter(r => r.estadoRecibo === 'PENDIENTE')
      .reduce((total, r) => total + Number(r.total), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, r) => total + Number(r.consumoM3), 0);
  }

  ultimosRecibos(): ReciboClienteResponse[] {
    return [...this.recibos].sort((a, b) => b.id - a.id).slice(0, 5);
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