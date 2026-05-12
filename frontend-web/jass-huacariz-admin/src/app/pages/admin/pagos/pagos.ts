import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface ReciboPendiente {
  id: number;
  codigo: string;
  cliente: string;
  dni: string;
  suministro: string;
  periodo: string;
  total: number;
}

interface Pago {
  codigoPago: string;
  codigoRecibo: string;
  cliente: string;
  dni: string;
  suministro: string;
  periodo: string;
  metodoPago: 'Efectivo' | 'PagoEfectivo' | 'Transferencia';
  codigoOperacion: string;
  monto: number;
  fechaPago: string;
  estado: 'Registrado' | 'Anulado';
}

@Component({
  selector: 'app-pagos',
  imports: [FormsModule],
  templateUrl: './pagos.html',
  styleUrl: './pagos.scss'
})
export class Pagos {
  mostrarModal = false;

  recibosPendientes: ReciboPendiente[] = [
    {
      id: 1,
      codigo: 'REC-0001',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Casa principal',
      periodo: 'Mayo 2026',
      total: 36.00
    },
    {
      id: 2,
      codigo: 'REC-0003',
      cliente: 'Juan Pérez Sánchez',
      dni: '45879632',
      suministro: 'Vivienda familiar',
      periodo: 'Mayo 2026',
      total: 45.00
    },
    {
      id: 3,
      codigo: 'REC-0004',
      cliente: 'María Rodríguez Díaz',
      dni: '47851236',
      suministro: 'Casa secundaria',
      periodo: 'Mayo 2026',
      total: 3.00
    }
  ];

  pagos: Pago[] = [
    {
      codigoPago: 'PAG-0001',
      codigoRecibo: 'REC-0002',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Tienda',
      periodo: 'Mayo 2026',
      metodoPago: 'Efectivo',
      codigoOperacion: 'EFECTIVO-001',
      monto: 90.00,
      fechaPago: '11/05/2026',
      estado: 'Registrado'
    },
    {
      codigoPago: 'PAG-0002',
      codigoRecibo: 'REC-0005',
      cliente: 'Rosa Mendoza López',
      dni: '48752147',
      suministro: 'Local comercial',
      periodo: 'Mayo 2026',
      metodoPago: 'PagoEfectivo',
      codigoOperacion: 'PE-785412',
      monto: 72.00,
      fechaPago: '11/05/2026',
      estado: 'Registrado'
    }
  ];

  nuevoPago = {
    idRecibo: 0,
    metodoPago: 'Efectivo' as 'Efectivo' | 'PagoEfectivo' | 'Transferencia',
    codigoOperacion: '',
    monto: 0
  };

  get totalPagos(): number {
    return this.pagos.length;
  }

  get montoRecaudado(): number {
    return this.pagos
      .filter(pago => pago.estado === 'Registrado')
      .reduce((total, pago) => total + pago.monto, 0);
  }

  get recibosPorCobrar(): number {
    return this.recibosPendientes.length;
  }

  abrirModal(): void {
    this.nuevoPago = {
      idRecibo: 0,
      metodoPago: 'Efectivo',
      codigoOperacion: '',
      monto: 0
    };

    this.mostrarModal = true;
  }

  cerrarModal(): void {
    this.mostrarModal = false;
  }

  seleccionarRecibo(): void {
    const recibo = this.recibosPendientes.find(r => r.id === Number(this.nuevoPago.idRecibo));

    if (recibo) {
      this.nuevoPago.monto = recibo.total;
      this.nuevoPago.codigoOperacion = this.generarCodigoOperacion();
    }
  }

  guardarPago(): void {
    const recibo = this.recibosPendientes.find(r => r.id === Number(this.nuevoPago.idRecibo));

    if (!recibo) {
      return;
    }

    const pago: Pago = {
      codigoPago: `PAG-${String(this.pagos.length + 1).padStart(4, '0')}`,
      codigoRecibo: recibo.codigo,
      cliente: recibo.cliente,
      dni: recibo.dni,
      suministro: recibo.suministro,
      periodo: recibo.periodo,
      metodoPago: this.nuevoPago.metodoPago,
      codigoOperacion: this.nuevoPago.codigoOperacion,
      monto: this.nuevoPago.monto,
      fechaPago: new Date().toLocaleDateString('es-PE'),
      estado: 'Registrado'
    };

    this.pagos.unshift(pago);
    this.recibosPendientes = this.recibosPendientes.filter(r => r.id !== recibo.id);
    this.cerrarModal();
  }

  anularPago(pago: Pago): void {
    pago.estado = 'Anulado';
  }

  private generarCodigoOperacion(): string {
    const numero = Math.floor(100000 + Math.random() * 900000);

    if (this.nuevoPago.metodoPago === 'PagoEfectivo') {
      return `PE-${numero}`;
    }

    if (this.nuevoPago.metodoPago === 'Transferencia') {
      return `TR-${numero}`;
    }

    return `EFECTIVO-${String(this.pagos.length + 1).padStart(3, '0')}`;
  }
}