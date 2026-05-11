import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface Suministro {
  idSector: number;
  nombreSector: string;
  direccionSuministro: string;
  referencia: string;
  aliasSuministro: string;
  lecturaInicial: number;
}

interface Cliente {
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  estado: boolean;
  suministros: Suministro[];
}

@Component({
  selector: 'app-clientes',
  imports: [FormsModule],
  templateUrl: './clientes.html',
  styleUrl: './clientes.scss'
})
export class Clientes {
  mostrarModal = false;
  clienteSeleccionado: Cliente | null = null;

  clientes: Cliente[] = [
    {
      dni: '12345678',
      nombres: 'Dany',
      apellidos: 'Carmona',
      telefono: '987654321',
      correo: 'dany@gmail.com',
      estado: true,
      suministros: [
        {
          idSector: 1,
          nombreSector: 'Huacariz',
          direccionSuministro: 'Av. Principal 123',
          referencia: 'Casa color blanco',
          aliasSuministro: 'Casa principal',
          lecturaInicial: 450.345
        },
        {
          idSector: 1,
          nombreSector: 'Huacariz',
          direccionSuministro: 'Av. Principal 125',
          referencia: 'Frente a la tienda',
          aliasSuministro: 'Tienda',
          lecturaInicial: 220.000
        },
        {
          idSector: 2,
          nombreSector: 'La Molina',
          direccionSuministro: 'Jr. Lima 560',
          referencia: 'Esquina con mercado',
          aliasSuministro: 'Local comercial',
          lecturaInicial: 100.000
        }
      ]
    },
    {
      dni: '45879632',
      nombres: 'Juan',
      apellidos: 'Pérez Sánchez',
      telefono: '976543210',
      correo: 'juan@gmail.com',
      estado: true,
      suministros: [
        {
          idSector: 1,
          nombreSector: 'Huacariz Bajo',
          direccionSuministro: 'Sector Huacariz Bajo S/N',
          referencia: 'Cerca al reservorio',
          aliasSuministro: 'Vivienda familiar',
          lecturaInicial: 350.125
        }
      ]
    },
    {
      dni: '47851236',
      nombres: 'María',
      apellidos: 'Rodríguez Díaz',
      telefono: '965874123',
      correo: 'maria@gmail.com',
      estado: false,
      suministros: [
        {
          idSector: 2,
          nombreSector: 'Huacariz Alto',
          direccionSuministro: 'Av. Los Pinos 245',
          referencia: 'Portón azul',
          aliasSuministro: 'Casa secundaria',
          lecturaInicial: 180.000
        }
      ]
    }
  ];

  nuevoCliente: Cliente = this.crearClienteVacio();

  get totalClientes(): number {
    return this.clientes.length;
  }

  get clientesActivos(): number {
    return this.clientes.filter(cliente => cliente.estado).length;
  }

  get totalSuministros(): number {
    return this.clientes.reduce((total, cliente) => total + cliente.suministros.length, 0);
  }

  abrirModal(): void {
    this.nuevoCliente = this.crearClienteVacio();
    this.mostrarModal = true;
  }

  cerrarModal(): void {
    this.mostrarModal = false;
  }

  verSuministros(cliente: Cliente): void {
    this.clienteSeleccionado = cliente;
  }

  cerrarDetalleSuministros(): void {
    this.clienteSeleccionado = null;
  }

  agregarSuministro(): void {
    this.nuevoCliente.suministros.push({
      idSector: 1,
      nombreSector: '',
      direccionSuministro: '',
      referencia: '',
      aliasSuministro: '',
      lecturaInicial: 0
    });
  }

  eliminarSuministro(index: number): void {
    if (this.nuevoCliente.suministros.length > 1) {
      this.nuevoCliente.suministros.splice(index, 1);
    }
  }

  guardarCliente(): void {
    this.clientes.push({
      ...this.nuevoCliente,
      suministros: [...this.nuevoCliente.suministros]
    });

    this.cerrarModal();
  }

  private crearClienteVacio(): Cliente {
    return {
      dni: '',
      nombres: '',
      apellidos: '',
      telefono: '',
      correo: '',
      estado: true,
      suministros: [
        {
          idSector: 1,
          nombreSector: '',
          direccionSuministro: '',
          referencia: '',
          aliasSuministro: '',
          lecturaInicial: 0
        }
      ]
    };
  }
}