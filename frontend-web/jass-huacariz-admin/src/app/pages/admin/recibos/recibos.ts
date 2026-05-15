import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { PagoRequest, Recibo, ReciboResponse } from '../../../core/services/recibo';

@Component({
  selector: 'app-recibos',
  imports: [CommonModule, FormsModule],
  templateUrl: './recibos.html',
  styleUrl: './recibos.scss',
})
export class Recibos implements OnInit {
  recibos: ReciboResponse[] = [];
  recibosFiltrados: ReciboResponse[] = [];

  cargando = false;
  pagando = false;
  error = '';
  exito = '';

  filtroEstado = 'TODOS';
  busqueda = '';

  reciboSeleccionado: ReciboResponse | null = null;

  pago: PagoRequest = {
    metodoPago: 'PagoEfectivo',
    codigoOperacion: ''
  };

  constructor(
    private reciboService: Recibo,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarRecibos();
  }

  cargarRecibos(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.reciboService.listarRecibos()
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
          this.error = 'No se pudieron cargar los recibos. Verifica el backend y tu sesión ADMIN.';
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
        (recibo.codigoSuministro || '').toLowerCase().includes(texto) ||
        (recibo.direccionSuministro || '').toLowerCase().includes(texto);

      return coincideEstado && coincideTexto;
    });
  }

  abrirPago(recibo: ReciboResponse): void {
    if (recibo.estadoRecibo === 'PAGADO') {
      this.error = 'Este recibo ya se encuentra pagado.';
      return;
    }

    this.reciboSeleccionado = recibo;
    this.pago = {
      metodoPago: 'PagoEfectivo',
      codigoOperacion: ''
    };

    this.error = '';
    this.exito = '';
  }

  cerrarPago(): void {
    this.reciboSeleccionado = null;
    this.pago = {
      metodoPago: 'PagoEfectivo',
      codigoOperacion: ''
    };
  }

  confirmarPago(): void {
    if (!this.reciboSeleccionado) {
      return;
    }

    if (!this.pago.metodoPago.trim()) {
      this.error = 'Seleccione o ingrese el método de pago.';
      return;
    }

    this.pagando = true;
    this.error = '';
    this.exito = '';

    this.reciboService.pagarRecibo(this.reciboSeleccionado.id, {
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
      next: (response) => {
        this.exito = `Pago registrado correctamente. Recibo: ${response.codigoRecibo}`;
        this.cerrarPago();
        this.cargarRecibos();
      },
      error: (err) => {
        this.error = err?.error?.error || 'No se pudo registrar el pago.';
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

  totalPendientes(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PENDIENTE').length;
  }

  totalPagados(): number {
    return this.recibos.filter(r => r.estadoRecibo === 'PAGADO').length;
  }

  montoTotal(): number {
    return this.recibos.reduce((total, r) => total + Number(r.total), 0);
  }

  private nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] ?? 'Mes inválido';
  }
}