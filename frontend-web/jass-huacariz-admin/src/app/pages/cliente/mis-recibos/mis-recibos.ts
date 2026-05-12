import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

interface ReciboCliente {
  id: number;
  codigo: string;
  suministro: string;
  direccion: string;
  periodo: string;
  lecturaAnterior: number;
  lecturaActual: number;
  consumo: number;
  subtotal: number;
  pagoLector: number;
  mantenimiento: number;
  total: number;
  fechaEmision: string;
  fechaVencimiento: string;
  estado: 'Pendiente' | 'Pagado' | 'Vencido';
}

@Component({
  selector: 'app-mis-recibos',
  imports: [FormsModule, RouterLink],
  templateUrl: './mis-recibos.html',
  styleUrl: './mis-recibos.scss'
})
export class MisRecibos {
  filtroEstado = 'Todos';

  recibos: ReciboCliente[] = [
    {
      id: 1,
      codigo: 'REC-0001',
      suministro: 'Casa principal',
      direccion: 'Av. Principal 123',
      periodo: 'Mayo 2026',
      lecturaAnterior: 450.345,
      lecturaActual: 462.345,
      consumo: 12,
      subtotal: 36,
      pagoLector: 1,
      mantenimiento: 0,
      total: 37,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pendiente'
    },
    {
      id: 2,
      codigo: 'REC-0002',
      suministro: 'Tienda',
      direccion: 'Av. Principal 125',
      periodo: 'Mayo 2026',
      lecturaAnterior: 220,
      lecturaActual: 238,
      consumo: 18,
      subtotal: 90,
      pagoLector: 1,
      mantenimiento: 0,
      total: 91,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pagado'
    },
    {
      id: 3,
      codigo: 'REC-0003',
      suministro: 'Local comercial',
      direccion: 'Jr. Lima 560',
      periodo: 'Mayo 2026',
      lecturaAnterior: 100,
      lecturaActual: 110,
      consumo: 10,
      subtotal: 30,
      pagoLector: 1,
      mantenimiento: 0,
      total: 31,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pendiente'
    },
    {
      id: 4,
      codigo: 'REC-0004',
      suministro: 'Casa principal',
      direccion: 'Av. Principal 123',
      periodo: 'Abril 2026',
      lecturaAnterior: 438.345,
      lecturaActual: 450.345,
      consumo: 12,
      subtotal: 36,
      pagoLector: 1,
      mantenimiento: 0,
      total: 37,
      fechaEmision: '01/04/2026',
      fechaVencimiento: '15/04/2026',
      estado: 'Pagado'
    }
  ];

  get recibosFiltrados(): ReciboCliente[] {
    if (this.filtroEstado === 'Todos') {
      return this.recibos;
    }

    return this.recibos.filter(recibo => recibo.estado === this.filtroEstado);
  }

  get recibosPendientes(): number {
    return this.recibos.filter(recibo => recibo.estado === 'Pendiente').length;
  }

  get recibosPagados(): number {
    return this.recibos.filter(recibo => recibo.estado === 'Pagado').length;
  }

  get deudaTotal(): number {
    return this.recibos
      .filter(recibo => recibo.estado === 'Pendiente' || recibo.estado === 'Vencido')
      .reduce((total, recibo) => total + recibo.total, 0);
  }
}