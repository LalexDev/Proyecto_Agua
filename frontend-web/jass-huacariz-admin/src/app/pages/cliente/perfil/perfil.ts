import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

interface SuministroPerfil {
  alias: string;
  direccion: string;
  referencia: string;
  sector: string;
  lecturaActual: number;
  estado: 'Activo' | 'Suspendido';
}

@Component({
  selector: 'app-perfil',
  imports: [FormsModule, RouterLink],
  templateUrl: './perfil.html',
  styleUrl: './perfil.scss'
})
export class Perfil {
  modoEdicion = false;

  cliente = {
    dni: '12345678',
    nombres: 'Dany',
    apellidos: 'Carmona',
    telefono: '987654321',
    correo: 'dany@gmail.com',
    usuario: '12345678',
    estado: 'Activo'
  };

  clienteTemporal = { ...this.cliente };

  suministros: SuministroPerfil[] = [
    {
      alias: 'Casa principal',
      direccion: 'Av. Principal 123',
      referencia: 'Casa color blanco',
      sector: 'Huacariz',
      lecturaActual: 462.345,
      estado: 'Activo'
    },
    {
      alias: 'Tienda',
      direccion: 'Av. Principal 125',
      referencia: 'Frente a la tienda',
      sector: 'Huacariz',
      lecturaActual: 238,
      estado: 'Activo'
    },
    {
      alias: 'Local comercial',
      direccion: 'Jr. Lima 560',
      referencia: 'Esquina con mercado',
      sector: 'Huacariz Alto',
      lecturaActual: 110,
      estado: 'Activo'
    }
  ];

  get nombreCompleto(): string {
    return `${this.cliente.nombres} ${this.cliente.apellidos}`;
  }

  get totalSuministros(): number {
    return this.suministros.length;
  }

  get suministrosActivos(): number {
    return this.suministros.filter(s => s.estado === 'Activo').length;
  }

  abrirEdicion(): void {
    this.clienteTemporal = { ...this.cliente };
    this.modoEdicion = true;
  }

  cancelarEdicion(): void {
    this.modoEdicion = false;
  }

  guardarCambios(): void {
    this.cliente = { ...this.clienteTemporal };
    this.modoEdicion = false;
  }
}