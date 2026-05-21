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
          this.suministros = suministros || [];
          this.recibos = recibos || [];
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la información del cliente.';
          this.cdr.detectChanges();
        }
      });
  }

  nombreCliente(): string {
    if (!this.perfil) {
      return 'Cliente';
    }

    return `${this.perfil.nombres || ''} ${this.perfil.apellidos || ''}`.trim();
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  deudaTotal(): number {
    return this.recibos
      .filter((recibo) => {
        return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
      })
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  totalPagado(): number {
    return this.recibos
      .filter((recibo) => {
        return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
      })
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, recibo) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  suministroPrincipal(): SuministroClienteResponse | null {
    return this.suministros.length ? this.suministros[0] : null;
  }

  reciboPendienteMasReciente(): ReciboClienteResponse | null {
    const pendientes = this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .sort((a, b) => Number(b.id) - Number(a.id));

    return pendientes.length ? pendientes[0] : null;
  }

  ultimosRecibos(): ReciboClienteResponse[] {
    return [...this.recibos]
      .sort((a, b) => Number(b.id) - Number(a.id))
      .slice(0, 5);
  }

  porcentajePagados(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPagados() / this.recibos.length) * 100;
  }

  porcentajePendientes(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibos.length) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosVencidos() / this.recibos.length) * 100;
  }

  graficoEstados(): string {
    if (!this.recibos.length) {
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

  periodo(recibo: ReciboClienteResponse): string {
    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }
}