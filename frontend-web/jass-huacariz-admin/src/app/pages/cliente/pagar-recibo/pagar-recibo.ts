import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';

interface ReciboPago {
  id: number;
  codigo: string;
  cliente: string;
  dni: string;
  suministro: string;
  direccion: string;
  periodo: string;
  consumo: number;
  fechaVencimiento: string;
  subtotal: number;
  pagoLector: number;
  mantenimiento: number;
  mora: number;
  total: number;
  estado: 'Pendiente' | 'Pagado' | 'Vencido';
}

@Component({
  selector: 'app-pagar-recibo',
  imports: [RouterLink, FormsModule],
  templateUrl: './pagar-recibo.html',
  styleUrl: './pagar-recibo.scss'
})
export class PagarRecibo {
  idRecibo = 0;
  metodoSeleccionado: 'PagoEfectivo' | 'Transferencia' | 'Presencial' = 'PagoEfectivo';
  codigoCip = '';
  pagoGenerado = false;

  recibos: ReciboPago[] = [
    {
      id: 1,
      codigo: 'REC-0001',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Casa principal',
      direccion: 'Av. Principal 123',
      periodo: 'Mayo 2026',
      consumo: 12,
      fechaVencimiento: '15/05/2026',
      subtotal: 36,
      pagoLector: 1,
      mantenimiento: 0,
      mora: 0,
      total: 37,
      estado: 'Pendiente'
    },
    {
      id: 3,
      codigo: 'REC-0003',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Local comercial',
      direccion: 'Jr. Lima 560',
      periodo: 'Mayo 2026',
      consumo: 10,
      fechaVencimiento: '15/05/2026',
      subtotal: 30,
      pagoLector: 1,
      mantenimiento: 0,
      mora: 0,
      total: 31,
      estado: 'Pendiente'
    }
  ];

  constructor(private route: ActivatedRoute) {
    this.idRecibo = Number(this.route.snapshot.paramMap.get('id') || 1);
  }

  get reciboActual(): ReciboPago | undefined {
    return this.recibos.find(recibo => recibo.id === this.idRecibo);
  }

  generarPago(): void {
    if (!this.reciboActual) {
      return;
    }

    const numero = Math.floor(100000000 + Math.random() * 900000000);

    if (this.metodoSeleccionado === 'PagoEfectivo') {
      this.codigoCip = `CIP-${numero}`;
    }

    if (this.metodoSeleccionado === 'Transferencia') {
      this.codigoCip = `TR-${numero}`;
    }

    if (this.metodoSeleccionado === 'Presencial') {
      this.codigoCip = `PRES-${numero}`;
    }

    this.pagoGenerado = true;
  }

  confirmarPagoVisual(): void {
    if (this.reciboActual) {
      this.reciboActual.estado = 'Pagado';
    }
  }
}