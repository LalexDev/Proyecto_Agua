import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { Pago, PagoResponse } from '../../../core/services/pago';

interface MetodoResumen {
  metodo: string;
  cantidad: number;
  monto: number;
  porcentaje: number;
}

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
  exito = '';
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
    this.exito = '';

    this.pagoService.listarPagos()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.pagos = data || [];
          this.filtrarPagos();
          this.exito = 'Pagos actualizados correctamente.';
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los pagos. Verifica el backend y tu sesión ADMIN.';
          this.exito = '';
          this.pagos = [];
          this.pagosFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  filtrarPagos(): void {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      this.pagosFiltrados = [...this.pagos];
      return;
    }

    this.pagosFiltrados = this.pagos.filter((pago: any) => {
      return (
        String(pago.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(pago.metodoPago || '').toLowerCase().includes(texto) ||
        String(pago.codigoOperacion || '').toLowerCase().includes(texto) ||
        String(pago.monto || '').toLowerCase().includes(texto) ||
        this.fechaPagoTexto(pago).toLowerCase().includes(texto)
      );
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtrarPagos();
  }

  totalPagos(): number {
    return this.pagosFiltrados.length;
  }

  montoTotalPagado(): number {
    return this.pagosFiltrados.reduce((total: number, pago: any) => {
      return total + Number(pago.monto || 0);
    }, 0);
  }

  pagosDelMes(): number {
    const hoy = new Date();
    const mesActual = hoy.getMonth();
    const anioActual = hoy.getFullYear();

    return this.pagosFiltrados.filter((pago: any) => {
      const fecha = this.obtenerFechaPago(pago);

      if (!fecha) {
        return false;
      }

      return fecha.getMonth() === mesActual && fecha.getFullYear() === anioActual;
    }).length;
  }

  montoPromedio(): number {
    if (!this.pagosFiltrados.length) {
      return 0;
    }

    return this.montoTotalPagado() / this.pagosFiltrados.length;
  }

  metodoMasUsado(): string {
    const resumen = this.resumenMetodos();

    if (!resumen.length) {
      return 'Sin datos';
    }

    return resumen[0].metodo;
  }

  resumenMetodos(): MetodoResumen[] {
    const contador: Record<string, { cantidad: number; monto: number }> = {};

    this.pagosFiltrados.forEach((pago: any) => {
      const metodo = pago.metodoPago || 'Sin método';

      if (!contador[metodo]) {
        contador[metodo] = {
          cantidad: 0,
          monto: 0
        };
      }

      contador[metodo].cantidad += 1;
      contador[metodo].monto += Number(pago.monto || 0);
    });

    const total = this.pagosFiltrados.length || 1;

    return Object.keys(contador)
      .map((metodo) => ({
        metodo,
        cantidad: contador[metodo].cantidad,
        monto: contador[metodo].monto,
        porcentaje: (contador[metodo].cantidad / total) * 100
      }))
      .sort((a, b) => b.cantidad - a.cantidad);
  }

  graficoMetodos(): string {
    const resumen = this.resumenMetodos();

    if (!resumen.length) {
      return 'conic-gradient(#e2e8f0 0% 100%)';
    }

    const colores = ['#17a7d4', '#16a34a', '#f59e0b', '#dc2626', '#6366f1', '#14b8a6'];

    let inicio = 0;

    const partes = resumen.map((item, index) => {
      const fin = inicio + item.porcentaje;
      const color = colores[index % colores.length];
      const parte = `${color} ${inicio}% ${fin}%`;
      inicio = fin;
      return parte;
    });

    return `conic-gradient(${partes.join(', ')})`;
  }

  colorMetodo(index: number): string {
    const colores = ['#17a7d4', '#16a34a', '#f59e0b', '#dc2626', '#6366f1', '#14b8a6'];
    return colores[index % colores.length];
  }

  fechaPagoTexto(pago: PagoResponse): string {
    const fecha = this.obtenerFechaPago(pago);

    if (!fecha) {
      return '-';
    }

    return fecha.toLocaleString('es-PE');
  }

  private obtenerFechaPago(pago: any): Date | null {
    const valor = pago.fechaPago || pago.fechaRegistro || pago.fecha || pago.createdAt;

    if (!valor) {
      return null;
    }

    const fecha = new Date(valor);

    if (isNaN(fecha.getTime())) {
      return null;
    }

    return fecha;
  }
}