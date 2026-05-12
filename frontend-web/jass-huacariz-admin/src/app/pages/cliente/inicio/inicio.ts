import { Component } from '@angular/core';

interface SuministroCliente {
  alias: string;
  direccion: string;
  sector: string;
  estado: 'Activo' | 'Suspendido';
  lecturaActual: number;
  ultimoConsumo: number;
  reciboPendiente: number;
}

@Component({
  selector: 'app-inicio',
  imports: [],
  templateUrl: './inicio.html',
  styleUrl: './inicio.scss'
})
export class Inicio {
  cliente = {
    nombres: 'Dany',
    apellidos: 'Carmona',
    dni: '12345678',
    telefono: '987654321',
    correo: 'dany@gmail.com'
  };

  suministros: SuministroCliente[] = [
    {
      alias: 'Casa principal',
      direccion: 'Av. Principal 123',
      sector: 'Huacariz',
      estado: 'Activo',
      lecturaActual: 462.345,
      ultimoConsumo: 12,
      reciboPendiente: 36
    },
    {
      alias: 'Tienda',
      direccion: 'Av. Principal 125',
      sector: 'Huacariz',
      estado: 'Activo',
      lecturaActual: 238,
      ultimoConsumo: 18,
      reciboPendiente: 90
    },
    {
      alias: 'Local comercial',
      direccion: 'Jr. Lima 560',
      sector: 'Huacariz Alto',
      estado: 'Activo',
      lecturaActual: 110,
      ultimoConsumo: 10,
      reciboPendiente: 30
    }
  ];

  get totalSuministros(): number {
    return this.suministros.length;
  }

  get deudaTotal(): number {
    return this.suministros.reduce((total, suministro) => total + suministro.reciboPendiente, 0);
  }

  get consumoTotal(): number {
    return this.suministros.reduce((total, suministro) => total + suministro.ultimoConsumo, 0);
  }
}