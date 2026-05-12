import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface Tarifa {
  id: number;
  nombre: string;
  desdeM3: number;
  hastaM3: number | null;
  precioM3: number;
  descripcion: string;
  estado: boolean;
}

@Component({
  selector: 'app-tarifas',
  imports: [FormsModule],
  templateUrl: './tarifas.html',
  styleUrl: './tarifas.scss'
})
export class Tarifas {
  mostrarModal = false;
  modoEdicion = false;

  tarifas: Tarifa[] = [
    {
      id: 1,
      nombre: 'Consumo básico',
      desdeM3: 1,
      hastaM3: 12,
      precioM3: 3,
      descripcion: 'Tarifa aplicada para consumos de 1 a 12 m³.',
      estado: true
    },
    {
      id: 2,
      nombre: 'Consumo medio',
      desdeM3: 13,
      hastaM3: 23,
      precioM3: 5,
      descripcion: 'Tarifa aplicada para consumos de 13 a 23 m³.',
      estado: true
    },
    {
      id: 3,
      nombre: 'Consumo alto',
      desdeM3: 24,
      hastaM3: null,
      precioM3: 8,
      descripcion: 'Tarifa aplicada para consumos desde 24 m³ a más.',
      estado: true
    }
  ];

  mantenimiento = {
    monto: 3,
    descripcion: 'Monto aplicado cuando el consumo mensual es 0 m³.',
    estado: true
  };

  pagoLector = {
    monto: 1,
    descripcion: 'Monto adicional por servicio de lectura del medidor.',
    estado: true
  };

  tarifaSeleccionada: Tarifa = this.crearTarifaVacia();

  get tarifasActivas(): number {
    return this.tarifas.filter(tarifa => tarifa.estado).length;
  }

  get precioMinimo(): number {
    return Math.min(...this.tarifas.map(tarifa => tarifa.precioM3));
  }

  get precioMaximo(): number {
    return Math.max(...this.tarifas.map(tarifa => tarifa.precioM3));
  }

  abrirModal(): void {
    this.modoEdicion = false;
    this.tarifaSeleccionada = this.crearTarifaVacia();
    this.mostrarModal = true;
  }

  editarTarifa(tarifa: Tarifa): void {
    this.modoEdicion = true;
    this.tarifaSeleccionada = { ...tarifa };
    this.mostrarModal = true;
  }

  cerrarModal(): void {
    this.mostrarModal = false;
  }

  guardarTarifa(): void {
    if (this.modoEdicion) {
      this.tarifas = this.tarifas.map(tarifa =>
        tarifa.id === this.tarifaSeleccionada.id ? { ...this.tarifaSeleccionada } : tarifa
      );
    } else {
      const nuevaTarifa: Tarifa = {
        ...this.tarifaSeleccionada,
        id: this.tarifas.length + 1
      };

      this.tarifas.push(nuevaTarifa);
    }

    this.cerrarModal();
  }

  cambiarEstado(tarifa: Tarifa): void {
    tarifa.estado = !tarifa.estado;
  }

  calcularEjemplo(consumo: number): number {
    if (consumo === 0) {
      return this.mantenimiento.monto + this.pagoLector.monto;
    }

    const tarifa = this.tarifas.find(t =>
      t.estado &&
      consumo >= t.desdeM3 &&
      (t.hastaM3 === null || consumo <= t.hastaM3)
    );

    if (!tarifa) {
      return 0;
    }

    return consumo * tarifa.precioM3 + this.pagoLector.monto;
  }

  private crearTarifaVacia(): Tarifa {
    return {
      id: 0,
      nombre: '',
      desdeM3: 0,
      hastaM3: null,
      precioM3: 0,
      descripcion: '',
      estado: true
    };
  }
}