import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface SuministroOption {
  id: number;
  cliente: string;
  dni: string;
  aliasSuministro: string;
  direccionSuministro: string;
  sector: string;
  lecturaAnterior: number;
}

interface Recibo {
  codigo: string;
  cliente: string;
  dni: string;
  suministro: string;
  sector: string;
  periodo: string;
  lecturaAnterior: number;
  lecturaActual: number;
  consumo: number;
  total: number;
  estado: 'Pendiente' | 'Pagado' | 'Vencido';
}

@Component({
  selector: 'app-recibos',
  imports: [FormsModule],
  templateUrl: './recibos.html',
  styleUrl: './recibos.scss'
})
export class Recibos {
  mostrarModal = false;

  suministros: SuministroOption[] = [
    {
      id: 1,
      cliente: 'Dany Carmona',
      dni: '12345678',
      aliasSuministro: 'Casa principal',
      direccionSuministro: 'Av. Principal 123',
      sector: 'Huacariz',
      lecturaAnterior: 450.345
    },
    {
      id: 2,
      cliente: 'Dany Carmona',
      dni: '12345678',
      aliasSuministro: 'Tienda',
      direccionSuministro: 'Av. Principal 125',
      sector: 'Huacariz',
      lecturaAnterior: 220.000
    },
    {
      id: 3,
      cliente: 'Dany Carmona',
      dni: '12345678',
      aliasSuministro: 'Local comercial',
      direccionSuministro: 'Jr. Lima 560',
      sector: 'Huacariz Alto',
      lecturaAnterior: 100.000
    },
    {
      id: 4,
      cliente: 'Juan Pérez Sánchez',
      dni: '45879632',
      aliasSuministro: 'Vivienda familiar',
      direccionSuministro: 'Sector Huacariz Bajo S/N',
      sector: 'Huacariz Bajo',
      lecturaAnterior: 350.125
    }
  ];

  recibos: Recibo[] = [
    {
      codigo: 'REC-0001',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Casa principal',
      sector: 'Huacariz',
      periodo: 'Mayo 2026',
      lecturaAnterior: 450.345,
      lecturaActual: 462.345,
      consumo: 12,
      total: 36,
      estado: 'Pendiente'
    },
    {
      codigo: 'REC-0002',
      cliente: 'Dany Carmona',
      dni: '12345678',
      suministro: 'Tienda',
      sector: 'Huacariz',
      periodo: 'Mayo 2026',
      lecturaAnterior: 220,
      lecturaActual: 238,
      consumo: 18,
      total: 90,
      estado: 'Pagado'
    }
  ];

  nuevoRecibo = {
    idSuministro: 0,
    periodo: 'Mayo 2026',
    lecturaAnterior: 0,
    lecturaActual: 0
  };

  get totalPendientes(): number {
    return this.recibos.filter(r => r.estado === 'Pendiente').length;
  }

  get totalPagados(): number {
    return this.recibos.filter(r => r.estado === 'Pagado').length;
  }

  get montoPendiente(): number {
    return this.recibos
      .filter(r => r.estado === 'Pendiente')
      .reduce((total, r) => total + r.total, 0);
  }

  abrirModal(): void {
    this.nuevoRecibo = {
      idSuministro: 0,
      periodo: 'Mayo 2026',
      lecturaAnterior: 0,
      lecturaActual: 0
    };

    this.mostrarModal = true;
  }

  cerrarModal(): void {
    this.mostrarModal = false;
  }

  seleccionarSuministro(): void {
    const suministro = this.suministros.find(s => s.id === Number(this.nuevoRecibo.idSuministro));

    if (suministro) {
      this.nuevoRecibo.lecturaAnterior = suministro.lecturaAnterior;
      this.nuevoRecibo.lecturaActual = suministro.lecturaAnterior;
    }
  }

  calcularConsumo(): number {
    const consumo = this.nuevoRecibo.lecturaActual - this.nuevoRecibo.lecturaAnterior;
    return consumo > 0 ? Number(consumo.toFixed(3)) : 0;
  }

  calcularTotal(): number {
    const consumo = this.calcularConsumo();

    if (consumo === 0) {
      return 3;
    }

    if (consumo <= 12) {
      return consumo * 3;
    }

    if (consumo <= 23) {
      return consumo * 5;
    }

    return consumo * 8;
  }

  guardarRecibo(): void {
    const suministro = this.suministros.find(s => s.id === Number(this.nuevoRecibo.idSuministro));

    if (!suministro) {
      return;
    }

    const consumo = this.calcularConsumo();
    const total = this.calcularTotal();

    const recibo: Recibo = {
      codigo: `REC-${String(this.recibos.length + 1).padStart(4, '0')}`,
      cliente: suministro.cliente,
      dni: suministro.dni,
      suministro: suministro.aliasSuministro,
      sector: suministro.sector,
      periodo: this.nuevoRecibo.periodo,
      lecturaAnterior: this.nuevoRecibo.lecturaAnterior,
      lecturaActual: this.nuevoRecibo.lecturaActual,
      consumo,
      total,
      estado: 'Pendiente'
    };

    this.recibos.unshift(recibo);
    this.cerrarModal();
  }
}