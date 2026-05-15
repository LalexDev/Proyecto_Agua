import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { forkJoin, finalize } from 'rxjs';

import { Cliente } from '../../../core/services/cliente';
import { Recibo, ReciboResponse } from '../../../core/services/recibo';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, RouterModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class Dashboard implements OnInit {
  cargando = false;
  error = '';

  totalClientes = 0;
  totalRecibos = 0;
  recibosPendientes = 0;
  totalPagado = 0;
  consumoPromedio = 0;

  ultimosRecibos: ReciboResponse[] = [];

  constructor(
    private clienteService: Cliente,
    private reciboService: Recibo,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDashboard();
  }

  cargarDashboard(): void {
    this.cargando = true;
    this.error = '';
    this.cdr.detectChanges();

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      recibos: this.reciboService.listarRecibos(),
      pendientes: this.reciboService.listarPendientes()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: ({ clientes, recibos, pendientes }) => {
        this.totalClientes = clientes.length;
        this.totalRecibos = recibos.length;
        this.recibosPendientes = pendientes.length;

        this.totalPagado = recibos
          .filter(r => r.estadoRecibo === 'PAGADO')
          .reduce((total, recibo) => total + Number(recibo.total), 0);

        this.consumoPromedio = recibos.length > 0
          ? recibos.reduce((total, recibo) => total + Number(recibo.consumoM3), 0) / recibos.length
          : 0;

        this.ultimosRecibos = [...recibos]
          .sort((a, b) => b.id - a.id)
          .slice(0, 5);

        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Error cargando dashboard:', error);
        this.error = 'No se pudieron cargar los datos del dashboard. Verifica que el backend esté encendido y que tu sesión sea ADMIN.';
        this.cdr.detectChanges();
      }
    });
  }

  estadoClase(estado: string): string {
    return estado?.toLowerCase() === 'pagado' ? 'pagado' : 'pendiente';
  }

  periodo(recibo: ReciboResponse): string {
    return `${this.nombreMes(recibo.mes)} ${recibo.anio}`;
  }

  private nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] ?? 'Mes inválido';
  }
}