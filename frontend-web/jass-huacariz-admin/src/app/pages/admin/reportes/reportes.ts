import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { forkJoin, finalize } from 'rxjs';

import { Cliente, ClienteResponse } from '../../../core/services/cliente';
import { Recibo, ReciboResponse } from '../../../core/services/recibo';
import { Pago, PagoResponse } from '../../../core/services/pago';
import { Tarifa, TarifaResponse } from '../../../core/services/tarifa';

@Component({
  selector: 'app-reportes',
  imports: [CommonModule],
  templateUrl: './reportes.html',
  styleUrl: './reportes.scss',
})
export class Reportes implements OnInit {
  clientes: ClienteResponse[] = [];
  recibos: ReciboResponse[] = [];
  pagos: PagoResponse[] = [];
  tarifas: TarifaResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clienteService: Cliente,
    private reciboService: Recibo,
    private pagoService: Pago,
    private tarifaService: Tarifa,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarReportes();
  }

  cargarReportes(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      recibos: this.reciboService.listarRecibos(),
      pagos: this.pagoService.listarPagos(),
      tarifas: this.tarifaService.listarTarifas()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: ({ clientes, recibos, pagos, tarifas }) => {
        this.clientes = clientes;
        this.recibos = recibos;
        this.pagos = pagos;
        this.tarifas = tarifas;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudieron cargar los reportes. Verifica el backend y tu sesión ADMIN.';
        this.cdr.detectChanges();
      }
    });
  }

  totalClientes(): number {
    return this.clientes.length;
  }

  totalSuministros(): number {
    return this.clientes.reduce(
      (total, cliente) => total + (cliente.suministros?.length ?? 0),
      0
    );
  }

  totalRecibos(): number {
    return this.recibos.length;
  }

  recibosPendientes(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PENDIENTE').length;
  }

  recibosPagados(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PAGADO').length;
  }

  totalRecaudado(): number {
    return this.pagos.reduce((total, pago) => total + Number(pago.monto), 0);
  }

  totalEmitido(): number {
    return this.recibos.reduce((total, recibo) => total + Number(recibo.total), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, recibo) => total + Number(recibo.consumoM3), 0);
  }

  consumoPromedio(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return this.consumoTotal() / this.recibos.length;
  }

  porcentajePagados(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return (this.recibosPagados() / this.recibos.length) * 100;
  }

  porcentajePendientes(): number {
    if (this.recibos.length === 0) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibos.length) * 100;
  }

  tarifaPromedio(): number {
    if (this.tarifas.length === 0) {
      return 0;
    }

    const suma = this.tarifas.reduce((total, tarifa) => total + Number(tarifa.precioM3), 0);
    return suma / this.tarifas.length;
  }

  ultimosPagos(): PagoResponse[] {
    return [...this.pagos]
      .sort((a, b) => b.id - a.id)
      .slice(0, 5);
  }

  ultimosRecibos(): ReciboResponse[] {
    return [...this.recibos]
      .sort((a, b) => b.id - a.id)
      .slice(0, 5);
  }

  clientesConMasSuministros(): ClienteResponse[] {
    return [...this.clientes]
      .sort((a, b) => (b.suministros?.length ?? 0) - (a.suministros?.length ?? 0))
      .slice(0, 5);
  }

  nombreCompleto(cliente: ClienteResponse): string {
    return `${cliente.nombres} ${cliente.apellidos}`;
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