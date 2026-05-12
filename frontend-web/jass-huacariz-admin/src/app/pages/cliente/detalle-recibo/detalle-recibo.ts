import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

interface DetalleReciboCliente {
  id: number;
  codigo: string;
  cliente: string;
  dni: string;
  telefono: string;
  correo: string;
  suministro: string;
  direccion: string;
  referencia: string;
  sector: string;
  periodo: string;
  lecturaAnterior: number;
  lecturaActual: number;
  consumo: number;
  precioM3: number;
  subtotal: number;
  pagoLector: number;
  mantenimiento: number;
  mora: number;
  total: number;
  fechaEmision: string;
  fechaVencimiento: string;
  estado: 'Pendiente' | 'Pagado' | 'Vencido';
}

@Component({
  selector: 'app-detalle-recibo',
  imports: [RouterLink],
  templateUrl: './detalle-recibo.html',
  styleUrl: './detalle-recibo.scss'
})
export class DetalleRecibo {
  recibos: DetalleReciboCliente[] = [
    {
      id: 1,
      codigo: 'REC-0001',
      cliente: 'Dany Carmona',
      dni: '12345678',
      telefono: '987654321',
      correo: 'dany@gmail.com',
      suministro: 'Casa principal',
      direccion: 'Av. Principal 123',
      referencia: 'Casa color blanco',
      sector: 'Huacariz',
      periodo: 'Mayo 2026',
      lecturaAnterior: 450.345,
      lecturaActual: 462.345,
      consumo: 12,
      precioM3: 3,
      subtotal: 36,
      pagoLector: 1,
      mantenimiento: 0,
      mora: 0,
      total: 37,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pendiente'
    },
    {
      id: 2,
      codigo: 'REC-0002',
      cliente: 'Dany Carmona',
      dni: '12345678',
      telefono: '987654321',
      correo: 'dany@gmail.com',
      suministro: 'Tienda',
      direccion: 'Av. Principal 125',
      referencia: 'Frente a la tienda',
      sector: 'Huacariz',
      periodo: 'Mayo 2026',
      lecturaAnterior: 220,
      lecturaActual: 238,
      consumo: 18,
      precioM3: 5,
      subtotal: 90,
      pagoLector: 1,
      mantenimiento: 0,
      mora: 0,
      total: 91,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pagado'
    },
    {
      id: 3,
      codigo: 'REC-0003',
      cliente: 'Dany Carmona',
      dni: '12345678',
      telefono: '987654321',
      correo: 'dany@gmail.com',
      suministro: 'Local comercial',
      direccion: 'Jr. Lima 560',
      referencia: 'Esquina con mercado',
      sector: 'Huacariz Alto',
      periodo: 'Mayo 2026',
      lecturaAnterior: 100,
      lecturaActual: 110,
      consumo: 10,
      precioM3: 3,
      subtotal: 30,
      pagoLector: 1,
      mantenimiento: 0,
      mora: 0,
      total: 31,
      fechaEmision: '01/05/2026',
      fechaVencimiento: '15/05/2026',
      estado: 'Pendiente'
    }
  ];

  idRecibo = 0;

  constructor(private route: ActivatedRoute) {
    this.idRecibo = Number(this.route.snapshot.paramMap.get('id') || 1);
  }

  get reciboActual(): DetalleReciboCliente | undefined {
    return this.recibos.find(recibo => recibo.id === this.idRecibo);
  }

  imprimirRecibo(): void {
    window.print();
  }
}