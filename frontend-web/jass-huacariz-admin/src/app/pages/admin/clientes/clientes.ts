import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';

import {
  Cliente,
  ClienteRequest,
  ClienteResponse,
  SuministroRequest,
  SuministroResponse
} from '../../../core/services/cliente';

type TipoAccion = 'CLIENTE' | 'SUMINISTRO';

interface AccionPendiente {
  tipo: TipoAccion;
  cliente: ClienteResponse;
  suministro?: SuministroResponse;
  estadoNuevo: boolean;
  titulo: string;
  mensaje: string;
  textoBoton: string;
}

@Component({
  selector: 'app-clientes',
  imports: [CommonModule, FormsModule],
  templateUrl: './clientes.html',
  styleUrl: './clientes.scss',
})
export class Clientes implements OnInit {
  clientes: ClienteResponse[] = [];
  clientesFiltrados: ClienteResponse[] = [];

  cargando = false;
  guardando = false;
  procesandoAccion = false;

  error = '';
  exito = '';
  busqueda = '';

  mostrarFormulario = false;
  mostrarDetalle = false;

  clienteDetalle: ClienteResponse | null = null;
  accionPendiente: AccionPendiente | null = null;

  nuevoCliente: ClienteRequest = this.crearClienteVacio();

  constructor(
    private clienteService: Cliente,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarClientes();
  }

  cargarClientes(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clienteService.listarClientes()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.clientes = data || [];
          this.filtrarClientes();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los clientes. Verifica el backend y tu sesión ADMIN.';
          this.clientes = [];
          this.clientesFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  cargarDatos(): void {
    this.cargarClientes();
  }

  filtrarClientes(): void {
    const texto = this.busqueda.trim().toLowerCase();

    if (!texto) {
      this.clientesFiltrados = [...this.clientes];
      return;
    }

    this.clientesFiltrados = this.clientes.filter((cliente) => {
      const nombreCompleto = this.nombreCompleto(cliente).toLowerCase();

      const coincideCliente =
        String(cliente.dni || '').toLowerCase().includes(texto) ||
        nombreCompleto.includes(texto) ||
        String(cliente.telefono || '').toLowerCase().includes(texto) ||
        String(cliente.correo || '').toLowerCase().includes(texto) ||
        String(cliente.codigoUsuario || '').toLowerCase().includes(texto) ||
        this.estadoTexto(cliente.estado).toLowerCase().includes(texto);

      const coincideSuministro = (cliente.suministros || []).some((suministro) => {
        return (
          String(suministro.codigoSuministro || '').toLowerCase().includes(texto) ||
          String(suministro.aliasSuministro || '').toLowerCase().includes(texto) ||
          String(suministro.direccionSuministro || '').toLowerCase().includes(texto) ||
          String(suministro.nombreSector || '').toLowerCase().includes(texto) ||
          this.estadoSuministroTexto(suministro.estado).toLowerCase().includes(texto)
        );
      });

      return coincideCliente || coincideSuministro;
    });
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
    this.nuevoCliente = this.crearClienteVacio();
  }

  registrarCliente(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.guardando = true;

    const payload: ClienteRequest = {
      dni: this.nuevoCliente.dni.trim(),
      nombres: this.nuevoCliente.nombres.trim(),
      apellidos: this.nuevoCliente.apellidos.trim(),
      telefono: this.nuevoCliente.telefono.trim(),
      correo: this.nuevoCliente.correo.trim(),
      estado: this.nuevoCliente.estado,
      suministros: this.nuevoCliente.suministros.map((suministro) => ({
        idSector: Number(suministro.idSector),
        direccionSuministro: suministro.direccionSuministro.trim(),
        referencia: suministro.referencia?.trim() || '',
        aliasSuministro: suministro.aliasSuministro.trim(),
        lecturaInicial: Number(suministro.lecturaInicial || 0)
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
        next: () => {
          this.exito = 'Cliente registrado correctamente.';
          this.mostrarFormulario = false;
          this.nuevoCliente = this.crearClienteVacio();
          this.cargarClientes();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar el cliente.';
          this.cdr.detectChanges();
        }
      });
  }

  agregarSuministroFormulario(): void {
    this.nuevoCliente.suministros.push(this.crearSuministroVacio());
  }

  quitarSuministroFormulario(index: number): void {
    if (this.nuevoCliente.suministros.length === 1) {
      this.error = 'El cliente debe tener al menos un suministro.';
      return;
    }

    this.nuevoCliente.suministros.splice(index, 1);
  }

  verDetalle(cliente: ClienteResponse): void {
    this.clienteDetalle = cliente;
    this.mostrarDetalle = true;
    this.error = '';
    this.exito = '';
  }

  cerrarDetalle(): void {
    this.clienteDetalle = null;
    this.mostrarDetalle = false;
  }

  abrirCambiarEstadoCliente(cliente: ClienteResponse): void {
    const estadoNuevo = !cliente.estado;

    this.accionPendiente = {
      tipo: 'CLIENTE',
      cliente,
      estadoNuevo,
      titulo: estadoNuevo ? 'Activar cliente' : 'Desactivar cliente',
      mensaje: estadoNuevo
        ? `¿Deseas activar a ${this.nombreCompleto(cliente)}? También se habilitará su usuario de acceso.`
        : `¿Deseas desactivar a ${this.nombreCompleto(cliente)}? También se deshabilitará su usuario de acceso.`,
      textoBoton: estadoNuevo ? 'Activar cliente' : 'Desactivar cliente'
    };
  }

  abrirCambiarEstadoSuministro(
    cliente: ClienteResponse,
    suministro: SuministroResponse,
    estadoNuevo: boolean
  ): void {
    this.accionPendiente = {
      tipo: 'SUMINISTRO',
      cliente,
      suministro,
      estadoNuevo,
      titulo: estadoNuevo ? 'Marcar suministro instalado' : 'Suspender suministro',
      mensaje: estadoNuevo
        ? `¿Confirmas que el suministro ${suministro.codigoSuministro} ya fue instalado y quedará activo?`
        : `¿Deseas suspender el suministro ${suministro.codigoSuministro}?`,
      textoBoton: estadoNuevo ? 'Marcar instalado' : 'Suspender suministro'
    };
  }

  cerrarConfirmacion(): void {
    this.accionPendiente = null;
  }

  confirmarAccion(): void {
    if (!this.accionPendiente) {
      return;
    }

    this.procesandoAccion = true;
    this.error = '';
    this.exito = '';

    const accion = this.accionPendiente;

    if (accion.tipo === 'CLIENTE') {
      this.clienteService.cambiarEstadoCliente(accion.cliente.id, accion.estadoNuevo)
        .pipe(
          finalize(() => {
            this.procesandoAccion = false;
            this.cdr.detectChanges();
          })
        )
        .subscribe({
          next: () => {
            this.exito = accion.estadoNuevo
              ? 'Cliente activado correctamente.'
              : 'Cliente desactivado correctamente.';

            this.accionPendiente = null;
            this.cargarClientes();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo cambiar el estado del cliente.';
            this.cdr.detectChanges();
          }
        });

      return;
    }

    if (accion.tipo === 'SUMINISTRO' && accion.suministro) {
      this.clienteService.cambiarEstadoSuministro(
        accion.cliente.id,
        accion.suministro.id,
        accion.estadoNuevo
      )
        .pipe(
          finalize(() => {
            this.procesandoAccion = false;
            this.cdr.detectChanges();
          })
        )
        .subscribe({
          next: () => {
            this.exito = accion.estadoNuevo
              ? 'Suministro marcado como instalado correctamente.'
              : 'Suministro suspendido correctamente.';

            this.accionPendiente = null;
            this.cerrarDetalle();
            this.cargarClientes();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo cambiar el estado del suministro.';
            this.cdr.detectChanges();
          }
        });
    }
  }

  irQr(suministro: SuministroResponse): void {
    this.router.navigate(['/admin/qr-suministro'], {
      queryParams: {
        codigo: suministro.codigoSuministro,
        alias: suministro.aliasSuministro,
        direccion: suministro.direccionSuministro
      }
    });
  }

  exportarClientesExcel(): void {
    const fecha = new Date().toISOString().slice(0, 10);
    const clientes = this.clientesFiltrados.length ? this.clientesFiltrados : this.clientes;

    let filas = '';

    clientes.forEach((cliente) => {
      const suministros = cliente.suministros || [];

      if (!suministros.length) {
        filas += `
          <tr>
            <td>${this.textoSeguro(cliente.dni)}</td>
            <td>${this.textoSeguro(this.nombreCompleto(cliente))}</td>
            <td>${this.textoSeguro(cliente.telefono)}</td>
            <td>${this.textoSeguro(cliente.correo)}</td>
            <td>${this.textoSeguro(cliente.codigoUsuario)}</td>
            <td>${this.estadoTexto(cliente.estado)}</td>
            <td>-</td>
            <td>-</td>
            <td>-</td>
            <td>-</td>
          </tr>
        `;
        return;
      }

      suministros.forEach((suministro) => {
        filas += `
          <tr>
            <td>${this.textoSeguro(cliente.dni)}</td>
            <td>${this.textoSeguro(this.nombreCompleto(cliente))}</td>
            <td>${this.textoSeguro(cliente.telefono)}</td>
            <td>${this.textoSeguro(cliente.correo)}</td>
            <td>${this.textoSeguro(cliente.codigoUsuario)}</td>
            <td>${this.estadoTexto(cliente.estado)}</td>
            <td>${this.textoSeguro(suministro.codigoSuministro)}</td>
            <td>${this.textoSeguro(suministro.aliasSuministro)}</td>
            <td>${this.textoSeguro(suministro.direccionSuministro)}</td>
            <td>${this.estadoSuministroTexto(suministro.estado)}</td>
          </tr>
        `;
      });
    });

    const html = `
      <html>
        <head>
          <meta charset="UTF-8">
          <style>
            table { border-collapse: collapse; width: 100%; font-family: Arial; }
            th { background: #07384A; color: white; font-weight: bold; padding: 10px; border: 1px solid #dbe7ec; }
            td { padding: 9px; border: 1px solid #dbe7ec; }
            .titulo { background: #1BA3C7; color: white; font-size: 18px; font-weight: bold; text-align: center; }
          </style>
        </head>
        <body>
          <table>
            <tr><td class="titulo" colspan="10">JASS HUACARIZ - CLIENTES Y SUMINISTROS</td></tr>
            <tr><td colspan="10">Fecha de exportación: ${new Date().toLocaleString('es-PE')}</td></tr>
            <tr>
              <th>DNI</th>
              <th>Cliente</th>
              <th>Teléfono</th>
              <th>Correo</th>
              <th>Usuario</th>
              <th>Estado cliente</th>
              <th>Código suministro</th>
              <th>Alias</th>
              <th>Dirección</th>
              <th>Estado suministro</th>
            </tr>
            ${filas}
          </table>
        </body>
      </html>
    `;

    const blob = new Blob([html], {
      type: 'application/vnd.ms-excel;charset=utf-8;'
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.href = url;
    link.download = `clientes_suministros_jass_huacariz_${fecha}.xls`;
    link.click();

    URL.revokeObjectURL(url);
  }

  imprimirClientesPdf(): void {
    const clientes = this.clientesFiltrados.length ? this.clientesFiltrados : this.clientes;

    let filas = '';

    clientes.forEach((cliente) => {
      const suministros = cliente.suministros || [];

      if (!suministros.length) {
        filas += `
          <tr>
            <td>${this.textoSeguro(cliente.dni)}</td>
            <td>${this.textoSeguro(this.nombreCompleto(cliente))}</td>
            <td>${this.textoSeguro(cliente.telefono)}</td>
            <td>${this.textoSeguro(cliente.correo)}</td>
            <td>${this.estadoTexto(cliente.estado)}</td>
            <td colspan="4">Sin suministros registrados</td>
          </tr>
        `;
        return;
      }

      suministros.forEach((suministro) => {
        filas += `
          <tr>
            <td>${this.textoSeguro(cliente.dni)}</td>
            <td>${this.textoSeguro(this.nombreCompleto(cliente))}</td>
            <td>${this.textoSeguro(cliente.telefono)}</td>
            <td>${this.textoSeguro(cliente.correo)}</td>
            <td>${this.estadoTexto(cliente.estado)}</td>
            <td>${this.textoSeguro(suministro.codigoSuministro)}</td>
            <td>${this.textoSeguro(suministro.aliasSuministro)}</td>
            <td>${this.textoSeguro(suministro.direccionSuministro)}</td>
            <td>${this.estadoSuministroTexto(suministro.estado)}</td>
          </tr>
        `;
      });
    });

    const ventana = window.open('', '_blank', 'width=1200,height=800');

    if (!ventana) {
      alert('El navegador bloqueó la ventana de impresión.');
      return;
    }

    ventana.document.open();
    ventana.document.write(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Clientes y suministros - JASS Huacariz</title>
        <style>
          body {
            font-family: Arial, Helvetica, sans-serif;
            padding: 24px;
            color: #0f2f44;
          }

          .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #1ba3c7;
            padding-bottom: 16px;
            margin-bottom: 20px;
          }

          h1 {
            margin: 0;
            font-size: 24px;
          }

          p {
            margin: 4px 0;
            color: #64748b;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
          }

          th {
            background: #e8f7fb;
            color: #0f2f44;
            padding: 9px;
            border: 1px solid #dbe7ec;
            text-align: left;
          }

          td {
            padding: 8px;
            border: 1px solid #dbe7ec;
          }

          .actions {
            margin-top: 18px;
            text-align: right;
          }

          button {
            border: none;
            border-radius: 10px;
            padding: 11px 16px;
            font-weight: 800;
            cursor: pointer;
          }

          .print {
            background: #1ba3c7;
            color: white;
          }

          @media print {
            .actions {
              display: none;
            }
          }
        </style>
      </head>

      <body>
        <div class="header">
          <div>
            <h1>JASS Huacariz</h1>
            <p>Reporte de clientes y suministros</p>
            <p>Fecha de emisión: ${new Date().toLocaleString('es-PE')}</p>
          </div>
          <strong>Administración</strong>
        </div>

        <table>
          <thead>
            <tr>
              <th>DNI</th>
              <th>Cliente</th>
              <th>Teléfono</th>
              <th>Correo</th>
              <th>Estado cliente</th>
              <th>Código suministro</th>
              <th>Alias</th>
              <th>Dirección</th>
              <th>Estado suministro</th>
            </tr>
          </thead>
          <tbody>
            ${filas || '<tr><td colspan="9">No hay clientes registrados.</td></tr>'}
          </tbody>
        </table>

        <div class="actions">
          <button class="print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);
    ventana.document.close();
  }

  nombreCompleto(cliente: ClienteResponse): string {
    return `${cliente.nombres || ''} ${cliente.apellidos || ''}`.trim();
  }

  totalSuministros(cliente: ClienteResponse): number {
    return cliente.suministros?.length || 0;
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activo' : 'Inactivo';
  }

  estadoClase(estado: boolean): string {
    return estado ? 'activo' : 'inactivo';
  }

  estadoSuministroTexto(estado: boolean): string {
    return estado ? 'Instalado' : 'Pendiente / suspendido';
  }

  estadoSuministroClase(estado: boolean): string {
    return estado ? 'activo' : 'pendiente';
  }

  private validarFormulario(): boolean {
    if (!this.nuevoCliente.dni || this.nuevoCliente.dni.trim().length !== 8) {
      this.error = 'Ingrese un DNI válido de 8 dígitos.';
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

    if (!this.nuevoCliente.suministros.length) {
      this.error = 'Agregue al menos un suministro.';
      return false;
    }

    for (const suministro of this.nuevoCliente.suministros) {
      if (!suministro.idSector || Number(suministro.idSector) <= 0) {
        this.error = 'Ingrese el ID del sector en cada suministro.';
        return false;
      }

      if (!suministro.direccionSuministro.trim()) {
        this.error = 'Ingrese la dirección del suministro.';
        return false;
      }

      if (!suministro.aliasSuministro.trim()) {
        this.error = 'Ingrese el alias del suministro.';
        return false;
      }

      if (Number(suministro.lecturaInicial) < 0) {
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

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}