import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize, forkJoin } from 'rxjs';

import {
  Cliente,
  ClienteRequest,
  ClienteResponse,
  SuministroRequest
} from '../../../core/services/cliente';

import { Sector, SectorResponse } from '../../../core/services/sector';

@Component({
  selector: 'app-clientes',
  imports: [CommonModule, FormsModule],
  templateUrl: './clientes.html',
  styleUrl: './clientes.scss',
})
export class Clientes implements OnInit {
  clientes: ClienteResponse[] = [];
  clientesFiltrados: ClienteResponse[] = [];
  sectores: SectorResponse[] = [];

  cargando = false;
  guardando = false;
  error = '';
  exito = '';
  busqueda = '';

  mostrarFormulario = false;

  nuevoCliente: ClienteRequest = this.crearClienteVacio();

  constructor(
    private clienteService: Cliente,
    private sectorService: Sector,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDatos();
  }

  cargarDatos(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      clientes: this.clienteService.listarClientes(),
      sectores: this.sectorService.listarSectores()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: ({ clientes, sectores }) => {
        this.clientes = clientes;
        this.clientesFiltrados = clientes;
        this.sectores = sectores;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudieron cargar los clientes. Verifica el backend y tu sesión ADMIN.';
        this.cdr.detectChanges();
      }
    });
  }

  filtrarClientes(): void {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      this.clientesFiltrados = this.clientes;
      return;
    }

    this.clientesFiltrados = this.clientes.filter(cliente =>
      cliente.dni.toLowerCase().includes(texto) ||
      cliente.nombres.toLowerCase().includes(texto) ||
      cliente.apellidos.toLowerCase().includes(texto) ||
      cliente.codigoUsuario.toLowerCase().includes(texto)
    );
  }

  abrirFormulario(): void {
    this.mostrarFormulario = true;
    this.error = '';
    this.exito = '';
    this.nuevoCliente = this.crearClienteVacio();
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
    this.error = '';
    this.exito = '';
  }

  agregarSuministro(): void {
    this.nuevoCliente.suministros.push(this.crearSuministroVacio());
  }

  quitarSuministro(index: number): void {
    if (this.nuevoCliente.suministros.length === 1) {
      this.error = 'Debe existir al menos un suministro.';
      return;
    }

    this.nuevoCliente.suministros.splice(index, 1);
  }

  registrarCliente(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.guardando = true;

    const payload: ClienteRequest = {
      ...this.nuevoCliente,
      dni: this.nuevoCliente.dni.trim(),
      nombres: this.nuevoCliente.nombres.trim(),
      apellidos: this.nuevoCliente.apellidos.trim(),
      telefono: this.nuevoCliente.telefono.trim(),
      correo: this.nuevoCliente.correo.trim(),
      suministros: this.nuevoCliente.suministros.map(s => ({
        ...s,
        direccionSuministro: s.direccionSuministro.trim(),
        referencia: s.referencia.trim(),
        aliasSuministro: s.aliasSuministro.trim(),
        lecturaInicial: Number(s.lecturaInicial)
      }))
    };

    this.clienteService.registrarCliente(payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (clienteCreado) => {
          this.exito = `Cliente registrado correctamente. Usuario: ${clienteCreado.codigoUsuario} / Contraseña inicial: ${clienteCreado.passwordInicial}`;
          this.mostrarFormulario = false;
          this.cargarDatos();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar el cliente.';
          this.cdr.detectChanges();
        }
      });
  }

  totalSuministros(cliente: ClienteResponse): number {
    return cliente.suministros?.length ?? 0;
  }

  nombreCompleto(cliente: ClienteResponse): string {
    return `${cliente.nombres} ${cliente.apellidos}`;
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activo' : 'Inactivo';
  }

  private validarFormulario(): boolean {
    if (!this.nuevoCliente.dni || this.nuevoCliente.dni.length !== 8) {
      this.error = 'El DNI debe tener 8 dígitos.';
      return false;
    }

    if (!this.nuevoCliente.nombres.trim()) {
      this.error = 'Ingrese los nombres del cliente.';
      return false;
    }

    if (!this.nuevoCliente.apellidos.trim()) {
      this.error = 'Ingrese los apellidos del cliente.';
      return false;
    }

    if (this.nuevoCliente.suministros.length === 0) {
      this.error = 'Debe registrar al menos un suministro.';
      return false;
    }

    for (const suministro of this.nuevoCliente.suministros) {
      if (!suministro.idSector) {
        this.error = 'Seleccione el sector de cada suministro.';
        return false;
      }

      if (!suministro.direccionSuministro.trim()) {
        this.error = 'Ingrese la dirección de cada suministro.';
        return false;
      }

      if (suministro.lecturaInicial < 0) {
        this.error = 'La lectura inicial no puede ser negativa.';
        return false;
      }
    }

    return true;
  }

  private crearClienteVacio(): ClienteRequest {
    return {
      dni: '',
      nombres: '',
      apellidos: '',
      telefono: '',
      correo: '',
      estado: true,
      suministros: [this.crearSuministroVacio()]
    };
  }

  private crearSuministroVacio(): SuministroRequest {
    return {
      idSector: 1,
      direccionSuministro: '',
      referencia: '',
      aliasSuministro: '',
      lecturaInicial: 0
    };
  }
}