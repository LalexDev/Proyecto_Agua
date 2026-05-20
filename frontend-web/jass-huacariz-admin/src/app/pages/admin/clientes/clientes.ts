import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';

import { Cliente } from '../../../core/services/cliente';

@Component({
  selector: 'app-clientes',
  imports: [CommonModule, FormsModule],
  templateUrl: './clientes.html',
  styleUrl: './clientes.scss',
})
export class Clientes implements OnInit {
  clientes: any[] = [];
  clientesFiltrados: any[] = [];

  sectores: any[] = [
    { id: 1, nombre: 'Sector 1' },
    { id: 2, nombre: 'Sector 2' },
    { id: 3, nombre: 'Sector 3' },
    { id: 4, nombre: 'Sector 4' }
  ];

  busqueda = '';

  cargando = false;
  guardando = false;

  error = '';
  exito = '';
  mensaje = '';

  mostrarFormulario = false;

  nuevoCliente: any = {
    dni: '',
    nombres: '',
    apellidos: '',
    telefono: '',
    correo: '',
    estado: true,
    suministros: []
  };

  constructor(
    private clienteService: Cliente,
    private cdr: ChangeDetectorRef,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.cargarDatos();
  }

  cargarDatos(): void {
    this.cargarClientes();
  }

  cargarClientes(): void {
    this.cargando = true;
    this.error = '';

    const servicio: any = this.clienteService;

    const request$ =
      servicio.listarClientes?.() ||
      servicio.listar?.() ||
      servicio.obtenerClientes?.() ||
      servicio.getClientes?.();

    if (!request$) {
      this.error = 'No se encontró el método para listar clientes.';
      this.cargando = false;
      return;
    }

    request$
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data: any[]) => {
          this.clientes = data || [];
          this.filtrarClientes();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la lista de clientes.';
          this.clientes = [];
          this.clientesFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  filtrarClientes(): void {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      this.clientesFiltrados = [...this.clientes];
      return;
    }

    this.clientesFiltrados = this.clientes.filter((cliente: any) => {
      const dni = String(cliente?.dni || '').toLowerCase();
      const nombres = String(cliente?.nombres || '').toLowerCase();
      const apellidos = String(cliente?.apellidos || '').toLowerCase();
      const telefono = String(cliente?.telefono || '').toLowerCase();
      const correo = String(cliente?.correo || '').toLowerCase();
      const usuario = String(cliente?.codigoUsuario || cliente?.usuario || '').toLowerCase();

      const suministrosTexto = (cliente?.suministros || [])
        .map((s: any) => {
          return [
            s?.codigoSuministro,
            s?.codigo,
            s?.aliasSuministro,
            s?.alias,
            s?.nombre,
            s?.direccionSuministro,
            s?.direccion
          ].join(' ');
        })
        .join(' ')
        .toLowerCase();

      return (
        dni.includes(texto) ||
        nombres.includes(texto) ||
        apellidos.includes(texto) ||
        telefono.includes(texto) ||
        correo.includes(texto) ||
        usuario.includes(texto) ||
        suministrosTexto.includes(texto)
      );
    });
  }

  abrirFormulario(): void {
    this.error = '';
    this.exito = '';
    this.mensaje = '';
    this.mostrarFormulario = true;

    if (!this.nuevoCliente.suministros || this.nuevoCliente.suministros.length === 0) {
      this.agregarSuministro();
    }
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
  }

  agregarSuministro(): void {
    this.nuevoCliente.suministros.push({
      idSector: 1,
      direccionSuministro: '',
      referencia: '',
      aliasSuministro: '',
      lecturaInicial: 0
    });
  }

  quitarSuministro(index: number): void {
    this.nuevoCliente.suministros.splice(index, 1);

    if (this.nuevoCliente.suministros.length === 0) {
      this.agregarSuministro();
    }
  }

  registrarCliente(): void {
    this.error = '';
    this.exito = '';
    this.mensaje = '';

    if (!this.nuevoCliente.dni?.trim()) {
      this.error = 'Ingrese el DNI del cliente.';
      return;
    }

    if (!this.nuevoCliente.nombres?.trim()) {
      this.error = 'Ingrese los nombres del cliente.';
      return;
    }

    if (!this.nuevoCliente.apellidos?.trim()) {
      this.error = 'Ingrese los apellidos del cliente.';
      return;
    }

    if (!this.nuevoCliente.suministros || this.nuevoCliente.suministros.length === 0) {
      this.error = 'Agregue al menos un suministro.';
      return;
    }

    const servicio: any = this.clienteService;

    const request$ =
      servicio.registrarCliente?.(this.nuevoCliente) ||
      servicio.crearCliente?.(this.nuevoCliente) ||
      servicio.guardarCliente?.(this.nuevoCliente) ||
      servicio.registrar?.(this.nuevoCliente);

    if (!request$) {
      this.error = 'No se encontró el método para registrar cliente.';
      return;
    }

    this.guardando = true;

    request$
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (resp: any) => {
          const usuario = resp?.codigoUsuario || resp?.usuario || this.nuevoCliente.dni;
          const password = resp?.passwordInicial || resp?.password || 'cliente123';

          this.exito = `Cliente registrado correctamente. Usuario: ${usuario} / Contraseña inicial: ${password}`;
          this.mensaje = this.exito;

          this.limpiarFormulario();
          this.cerrarFormulario();
          this.cargarClientes();
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.error =
            err?.error?.error ||
            err?.error?.mensaje ||
            'No se pudo registrar el cliente.';
          this.cdr.detectChanges();
        }
      });
  }

  limpiarFormulario(): void {
    this.nuevoCliente = {
      dni: '',
      nombres: '',
      apellidos: '',
      telefono: '',
      correo: '',
      estado: true,
      suministros: []
    };
  }

  nombreCompleto(cliente: any): string {
  const nombres = cliente?.nombres || '';
  const apellidos = cliente?.apellidos || '';

    return `${nombres} ${apellidos}`.trim() || 'Sin nombre';
  }
  totalSuministros(cliente: any): number {
    return cliente?.suministros?.length || 0;
  }

  estadoTexto(estado: any): string {
    return estado === false || estado === 'INACTIVO' ? 'Inactivo' : 'Activo';
  }

  estadoClase(estado: any): string {
    return estado === false || estado === 'INACTIVO' ? 'inactivo' : 'activo';
  }

  obtenerCodigoSuministro(suministro: any): string {
    return (
      suministro?.codigoSuministro ||
      suministro?.codigo ||
      suministro?.codigo_suministro ||
      ''
    );
  }

  obtenerAliasSuministro(suministro: any): string {
    return (
      suministro?.aliasSuministro ||
      suministro?.alias ||
      suministro?.nombre ||
      'Suministro de agua'
    );
  }

  obtenerDireccionSuministro(suministro: any): string {
    return (
      suministro?.direccionSuministro ||
      suministro?.direccion ||
      suministro?.direccionSuministroCompleta ||
      ''
    );
  }

  abrirQrSuministro(suministro: any): void {
    const codigo = this.obtenerCodigoSuministro(suministro);
    const alias = this.obtenerAliasSuministro(suministro);
    const direccion = this.obtenerDireccionSuministro(suministro);

    if (!codigo) {
      alert('No se encontró el código del suministro.');
      return;
    }

    this.router.navigate(['/admin/qr-suministro'], {
      queryParams: {
        codigo,
        alias,
        direccion
      }
    });
  }
}