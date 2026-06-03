import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';

import {
  Cliente,
  ClienteRequest,
  ClienteResponse,
  LecturadorRequest,
  SuministroRequest,
  SuministroResponse,
  SectorResponse,
  SectorRequest
} from '../../../core/services/cliente';

type TipoAccion = 'CLIENTE' | 'SUMINISTRO' | 'ELIMINAR_SUMINISTRO';
type TipoUsuarioFormulario = 'CLIENTE' | 'LECTURADOR';

interface AccionPendiente {
  tipo: TipoAccion;
  cliente: ClienteResponse;
  suministro?: SuministroResponse;
  estadoNuevo?: boolean;
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
  sectores: SectorResponse[] = [];

  nuevoSector: SectorRequest = {
    nombre: '',
    descripcion: '',
    estado: true
  };

  guardandoSector = false;

  cargando = false;
  guardando = false;
  procesandoAccion = false;

  error = '';
  exito = '';

  busqueda = '';
  filtroEstadoCliente = 'TODOS';
  filtroEstadoSuministro = 'TODOS';

  mostrarFormulario = false;
  mostrarDetalle = false;
  mostrarEditarCliente = false;
  mostrarEditarSuministro = false;
  mostrarAgregarSuministro = false;

  clienteDetalle: ClienteResponse | null = null;
  clienteEditando: ClienteResponse | null = null;
  clienteSuministroEditando: ClienteResponse | null = null;
  suministroEditando: SuministroResponse | null = null;

  accionPendiente: AccionPendiente | null = null;

  tipoUsuarioFormulario: TipoUsuarioFormulario = 'CLIENTE';

  nuevoCliente: ClienteRequest = this.crearClienteVacio();
  nuevoLecturador: LecturadorRequest = this.crearLecturadorVacio();

  formEditarCliente: ClienteRequest = this.crearClienteVacio();
  formEditarSuministro: SuministroRequest = this.crearSuministroVacio();
  formNuevoSuministro: SuministroRequest = this.crearSuministroVacio();

  constructor(
    private clienteService: Cliente,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarSectores();
    this.cargarClientes();
  }

  cargarSectores(): void {

  this.clienteService.listarSectores().subscribe({

    next: (data) => {

      this.sectores = data || [];

      this.cdr.detectChanges();
    },

    error: () => {

      this.sectores = [];

      this.cdr.detectChanges();
    }

    });

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
          this.clientes = (data || []).sort((a, b) => {
            return this.nombreCompleto(a).localeCompare(this.nombreCompleto(b));
          });

          this.aplicarFiltros();
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

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.clientesFiltrados = this.clientes.filter((cliente) => {
      const suministros = cliente.suministros || [];

      const coincideTexto =
        !texto ||
        String(cliente.dni || '').toLowerCase().includes(texto) ||
        this.nombreCompleto(cliente).toLowerCase().includes(texto) ||
        String(cliente.telefono || '').toLowerCase().includes(texto) ||
        String(cliente.correo || '').toLowerCase().includes(texto) ||
        String(cliente.codigoUsuario || '').toLowerCase().includes(texto) ||
        this.estadoClienteTexto(cliente.estado).toLowerCase().includes(texto) ||
        suministros.some((suministro) => {
          return (
            String(suministro.codigoSuministro || '').toLowerCase().includes(texto) ||
            String(suministro.aliasSuministro || '').toLowerCase().includes(texto) ||
            String(suministro.direccionSuministro || '').toLowerCase().includes(texto) ||
            String(suministro.nombreSector || '').toLowerCase().includes(texto) ||
            this.estadoSuministroTexto(suministro).toLowerCase().includes(texto)
          );
        });

      const coincideEstadoCliente =
        this.filtroEstadoCliente === 'TODOS' ||
        (this.filtroEstadoCliente === 'ACTIVO' && cliente.estado) ||
        (this.filtroEstadoCliente === 'INACTIVO' && !cliente.estado);

      const coincideEstadoSuministro =
        this.filtroEstadoSuministro === 'TODOS' ||
        (this.filtroEstadoSuministro === 'INSTALADO' && suministros.some(s => this.esSuministroInstalado(s))) ||
        (this.filtroEstadoSuministro === 'PENDIENTE' && suministros.some(s => this.esSuministroPendiente(s))) ||
        (this.filtroEstadoSuministro === 'BLOQUEADO' && suministros.some(s => !s.estado));

      return coincideTexto && coincideEstadoCliente && coincideEstadoSuministro;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstadoCliente = 'TODOS';
    this.filtroEstadoSuministro = 'TODOS';
    this.aplicarFiltros();
  }

  abrirFormulario(): void {
    this.mostrarFormulario = true;
    this.error = '';
    this.exito = '';
    this.tipoUsuarioFormulario = 'CLIENTE';
    this.nuevoCliente = this.crearClienteVacio();
    this.nuevoLecturador = this.crearLecturadorVacio();
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
    this.error = '';
    this.tipoUsuarioFormulario = 'CLIENTE';
    this.nuevoCliente = this.crearClienteVacio();
    this.nuevoLecturador = this.crearLecturadorVacio();
  }

  cambiarTipoUsuarioFormulario(tipo: TipoUsuarioFormulario): void {
    this.tipoUsuarioFormulario = tipo;
    this.error = '';
    this.exito = '';

    if (tipo === 'CLIENTE') {
      this.nuevoCliente = this.crearClienteVacio();
    } else {
      this.nuevoLecturador = this.crearLecturadorVacio();
    }
  }

  registrarUsuario(): void {
    if (this.tipoUsuarioFormulario === 'CLIENTE') {
      this.registrarCliente();
      return;
    }

    this.registrarLecturador();
  }

  registrarCliente(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormularioCliente()) {
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
          this.exito = 'Cliente registrado correctamente. Sus suministros iniciaron como pendientes de instalación.';
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

  registrarLecturador(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarLecturador()) {
      return;
    }

    this.guardando = true;

    const payload: LecturadorRequest = {
      dni: this.nuevoLecturador.dni.trim(),
      nombres: this.nuevoLecturador.nombres.trim(),
      apellidos: this.nuevoLecturador.apellidos.trim(),
      telefono: this.nuevoLecturador.telefono.trim(),
      correo: this.nuevoLecturador.correo.trim(),
      codigoUsuario: this.nuevoLecturador.codigoUsuario.trim(),
      password: this.nuevoLecturador.password.trim(),
      estado: this.nuevoLecturador.estado,
      sectorAsignado: this.nuevoLecturador.sectorAsignado?.trim() || ''
    };

    this.clienteService.registrarLecturador(payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Lecturador registrado correctamente.';
          this.mostrarFormulario = false;
          this.nuevoLecturador = this.crearLecturadorVacio();
          this.cargarClientes();
        },
        error: (err) => {
          this.error =
            err?.error?.error ||
            err?.error?.message ||
            'No se pudo registrar el lecturador. Verifica el endpoint /api/usuarios/lecturadores.';
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

  abrirEditarCliente(cliente: ClienteResponse): void {
    this.clienteEditando = cliente;

    this.formEditarCliente = {
      dni: cliente.dni || '',
      nombres: cliente.nombres || '',
      apellidos: cliente.apellidos || '',
      telefono: cliente.telefono || '',
      correo: cliente.correo || '',
      estado: cliente.estado,
      suministros: (cliente.suministros || []).map((suministro) => ({
        idSector: Number(suministro.idSector || 1),
        direccionSuministro: suministro.direccionSuministro || '',
        referencia: suministro.referencia || '',
        aliasSuministro: suministro.aliasSuministro || '',
        lecturaInicial: Number(suministro.lecturaInicial || 0)
      }))
    };

    this.mostrarEditarCliente = true;
    this.error = '';
    this.exito = '';
  }

  cerrarEditarCliente(): void {
    this.mostrarEditarCliente = false;
    this.clienteEditando = null;
    this.formEditarCliente = this.crearClienteVacio();
  }

  guardarEdicionCliente(): void {
    this.error = '';
    this.exito = '';

    if (!this.clienteEditando) {
      this.error = 'No se seleccionó ningún cliente para editar.';
      return;
    }

    if (!this.formEditarCliente.dni || this.formEditarCliente.dni.trim().length !== 8) {
      this.error = 'Ingrese un DNI válido de 8 dígitos.';
      return;
    }

    if (!this.formEditarCliente.nombres.trim()) {
      this.error = 'Ingrese los nombres del cliente.';
      return;
    }

    if (!this.formEditarCliente.apellidos.trim()) {
      this.error = 'Ingrese los apellidos del cliente.';
      return;
    }

    this.guardando = true;

    const payload: ClienteRequest = {
      dni: this.formEditarCliente.dni.trim(),
      nombres: this.formEditarCliente.nombres.trim(),
      apellidos: this.formEditarCliente.apellidos.trim(),
      telefono: this.formEditarCliente.telefono?.trim() || '',
      correo: this.formEditarCliente.correo?.trim() || '',
      estado: this.formEditarCliente.estado,
      suministros: (this.clienteEditando.suministros || []).map((suministro) => ({
        idSector: Number(suministro.idSector || 1),
        direccionSuministro: suministro.direccionSuministro || '',
        referencia: suministro.referencia || '',
        aliasSuministro: suministro.aliasSuministro || '',
        lecturaInicial: Number(suministro.lecturaInicial || 0)
      }))
    };

    this.clienteService.actualizarCliente(this.clienteEditando.id, payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Datos del cliente actualizados correctamente.';
          this.cerrarEditarCliente();
          this.cerrarDetalle();
          this.cargarClientes();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo actualizar el cliente.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirAgregarSuministro(cliente: ClienteResponse): void {
    this.clienteSuministroEditando = cliente;
    this.formNuevoSuministro = this.crearSuministroVacio();
    this.mostrarAgregarSuministro = true;
    this.error = '';
    this.exito = '';
  }

  cerrarAgregarSuministro(): void {
    this.mostrarAgregarSuministro = false;
    this.clienteSuministroEditando = null;
    this.formNuevoSuministro = this.crearSuministroVacio();
  }

  guardarNuevoSuministro(): void {
    this.error = '';
    this.exito = '';

    if (!this.clienteSuministroEditando) {
      this.error = 'No se seleccionó ningún cliente.';
      return;
    }

    if (!this.validarSuministro(this.formNuevoSuministro)) {
      return;
    }

    this.guardando = true;

    const payload: SuministroRequest = {
      idSector: Number(this.formNuevoSuministro.idSector),
      direccionSuministro: this.formNuevoSuministro.direccionSuministro.trim(),
      referencia: this.formNuevoSuministro.referencia?.trim() || '',
      aliasSuministro: this.formNuevoSuministro.aliasSuministro.trim(),
      lecturaInicial: Number(this.formNuevoSuministro.lecturaInicial || 0)
    };

    this.clienteService.agregarSuministro(this.clienteSuministroEditando.id, payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Nuevo suministro agregado correctamente. Inició como pendiente/suspendido.';
          this.cerrarAgregarSuministro();
          this.cerrarDetalle();
          this.cargarClientes();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo agregar el suministro.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirEditarSuministro(cliente: ClienteResponse, suministro: SuministroResponse): void {
    this.clienteSuministroEditando = cliente;
    this.suministroEditando = suministro;

    this.formEditarSuministro = {
      idSector: Number(suministro.idSector || 1),
      direccionSuministro: suministro.direccionSuministro || '',
      referencia: suministro.referencia || '',
      aliasSuministro: suministro.aliasSuministro || '',
      lecturaInicial: Number(suministro.lecturaInicial || 0)
    };

    this.mostrarEditarSuministro = true;
    this.error = '';
    this.exito = '';
  }

  cerrarEditarSuministro(): void {
    this.mostrarEditarSuministro = false;
    this.clienteSuministroEditando = null;
    this.suministroEditando = null;
    this.formEditarSuministro = this.crearSuministroVacio();
  }

  guardarEdicionSuministro(): void {
    this.error = '';
    this.exito = '';

    if (!this.clienteSuministroEditando || !this.suministroEditando) {
      this.error = 'No se seleccionó ningún suministro.';
      return;
    }

    if (!this.validarSuministro(this.formEditarSuministro)) {
      return;
    }

    this.guardando = true;

    const payload: SuministroRequest = {
      idSector: Number(this.formEditarSuministro.idSector),
      direccionSuministro: this.formEditarSuministro.direccionSuministro.trim(),
      referencia: this.formEditarSuministro.referencia?.trim() || '',
      aliasSuministro: this.formEditarSuministro.aliasSuministro.trim(),
      lecturaInicial: Number(this.formEditarSuministro.lecturaInicial || 0)
    };

    this.clienteService.actualizarSuministro(
      this.clienteSuministroEditando.id,
      this.suministroEditando.id,
      payload
    )
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Suministro actualizado correctamente.';
          this.cerrarEditarSuministro();
          this.cerrarDetalle();
          this.cargarClientes();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo actualizar el suministro.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirEliminarSuministro(cliente: ClienteResponse, suministro: SuministroResponse): void {
    this.accionPendiente = {
      tipo: 'ELIMINAR_SUMINISTRO',
      cliente,
      suministro,
      titulo: 'Eliminar suministro',
      mensaje: `¿Deseas eliminar el suministro ${suministro.codigoSuministro}? Solo se eliminará si no tiene lecturas ni recibos registrados. Si ya tiene historial, el sistema solicitará suspenderlo.`,
      textoBoton: 'Eliminar suministro'
    };
  }

  abrirCambiarEstadoCliente(cliente: ClienteResponse): void {
    const estadoNuevo = !cliente.estado;

    this.accionPendiente = {
      tipo: 'CLIENTE',
      cliente,
      estadoNuevo,
      titulo: estadoNuevo ? 'Activar cliente' : 'Desactivar cliente',
      mensaje: estadoNuevo
        ? `¿Deseas activar a ${this.nombreCompleto(cliente)}? Se habilitará su usuario y sus suministros conservarán su estado de instalación.`
        : `¿Deseas desactivar a ${this.nombreCompleto(cliente)}? Se bloqueará su usuario y TODOS sus suministros.`,
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
        ? `¿Confirmas que el suministro ${suministro.codigoSuministro} ya fue instalado? El lecturador podrá registrar consumo.`
        : `¿Deseas suspender el suministro ${suministro.codigoSuministro}? El lecturador ya no registrará consumo, solo podrá generar mantenimiento.`,
      textoBoton: estadoNuevo ? 'Marcar instalado' : 'Suspender'
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
      this.clienteService.cambiarEstadoCliente(accion.cliente.id, Boolean(accion.estadoNuevo))
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
              : 'Cliente desactivado correctamente. También se bloquearon sus suministros.';

            this.accionPendiente = null;
            this.cerrarDetalle();
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
        Boolean(accion.estadoNuevo)
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
              : 'Suministro suspendido correctamente. Ahora solo permitirá mantenimiento.';

            this.accionPendiente = null;
            this.cerrarDetalle();
            this.cargarClientes();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo cambiar el estado del suministro.';
            this.cdr.detectChanges();
          }
        });

      return;
    }

    if (accion.tipo === 'ELIMINAR_SUMINISTRO' && accion.suministro) {
      this.clienteService.eliminarSuministro(accion.cliente.id, accion.suministro.id)
        .pipe(
          finalize(() => {
            this.procesandoAccion = false;
            this.cdr.detectChanges();
          })
        )
        .subscribe({
          next: () => {
            this.exito = 'Suministro eliminado correctamente.';
            this.accionPendiente = null;
            this.cerrarDetalle();
            this.cargarClientes();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo eliminar el suministro. Si tiene historial, debe suspenderlo.';
            this.accionPendiente = null;
            this.cdr.detectChanges();
          }
        });
    }
  }

  irQr(suministro: SuministroResponse): void {
    const cliente = this.buscarClientePorSuministro(suministro.id);

    this.router.navigate(['/admin/qr-suministro'], {
      queryParams: {
        codigo: suministro.codigoSuministro,
        alias: suministro.aliasSuministro,
        direccion: suministro.direccionSuministro,
        cliente: cliente ? this.nombreCompleto(cliente) : '',
        dni: cliente ? cliente.dni : ''
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
            <td>${this.estadoClienteTexto(cliente.estado)}</td>
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
            <td>${this.estadoClienteTexto(cliente.estado)}</td>
            <td>${this.textoSeguro(suministro.codigoSuministro)}</td>
            <td>${this.textoSeguro(suministro.aliasSuministro)}</td>
            <td>${this.textoSeguro(suministro.direccionSuministro)}</td>
            <td>${this.estadoSuministroTexto(suministro)}</td>
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
            <td>${this.estadoClienteTexto(cliente.estado)}</td>
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
            <td>${this.estadoClienteTexto(cliente.estado)}</td>
            <td>${this.textoSeguro(suministro.codigoSuministro)}</td>
            <td>${this.textoSeguro(suministro.aliasSuministro)}</td>
            <td>${this.textoSeguro(suministro.direccionSuministro)}</td>
            <td>${this.estadoSuministroTexto(suministro)}</td>
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

  totalClientes(): number {
    return this.clientes.length;
  }

  clientesActivos(): number {
    return this.clientes.filter(c => c.estado).length;
  }

  clientesInactivos(): number {
    return this.clientes.filter(c => !c.estado).length;
  }

  totalSuministros(): number {
    return this.clientes.reduce((total, cliente) => {
      return total + (cliente.suministros?.length || 0);
    }, 0);
  }

  suministrosInstalados(): number {
    return this.clientes.reduce((total, cliente) => {
      return total + (cliente.suministros || []).filter(s => this.esSuministroInstalado(s)).length;
    }, 0);
  }

  suministrosPendientes(): number {
    return this.clientes.reduce((total, cliente) => {
      return total + (cliente.suministros || []).filter(s => this.esSuministroPendiente(s)).length;
    }, 0);
  }

  nombreCompleto(cliente: ClienteResponse): string {
    return `${cliente.nombres || ''} ${cliente.apellidos || ''}`.trim();
  }

  totalSuministrosCliente(cliente: ClienteResponse): number {
    return cliente.suministros?.length || 0;
  }

  estadoClienteTexto(estado: boolean): string {
    return estado ? 'Activo' : 'Inactivo';
  }

  estadoClienteClase(estado: boolean): string {
    return estado ? 'activo' : 'inactivo';
  }

  estadoSuministroTexto(suministro: SuministroResponse): string {
    if (!suministro.estado) {
      return 'Bloqueado por cliente';
    }

    return this.esSuministroInstalado(suministro)
      ? 'Instalado'
      : 'Pendiente / suspendido';
  }

  estadoSuministroClase(suministro: SuministroResponse): string {
    if (!suministro.estado) {
      return 'inactivo';
    }

    return this.esSuministroInstalado(suministro)
      ? 'instalado'
      : 'pendiente';
  }

  esSuministroInstalado(suministro: SuministroResponse): boolean {
    return Boolean(suministro.estado)
      && String(suministro.estadoInstalacion || '').toUpperCase() === 'INSTALADO';
  }

  esSuministroPendiente(suministro: SuministroResponse): boolean {
    return Boolean(suministro.estado)
      && String(suministro.estadoInstalacion || '').toUpperCase() !== 'INSTALADO';
  }

  private buscarClientePorSuministro(suministroId: number): ClienteResponse | null {
    for (const cliente of this.clientes) {
      const existe = (cliente.suministros || []).some(s => s.id === suministroId);

      if (existe) {
        return cliente;
      }
    }

    return null;
  }

  private validarFormularioCliente(): boolean {
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
      if (!this.validarSuministro(suministro)) {
        return false;
      }
    }

    return true;
  }

  private validarSuministro(suministro: SuministroRequest): boolean {
    if (!suministro.idSector || Number(suministro.idSector) <= 0) {
      this.error = 'Ingrese el ID del sector del suministro.';
      return false;
    }

    if (!suministro.direccionSuministro || !suministro.direccionSuministro.trim()) {
      this.error = 'Ingrese la dirección del suministro.';
      return false;
    }

    if (!suministro.aliasSuministro || !suministro.aliasSuministro.trim()) {
      this.error = 'Ingrese el alias del suministro.';
      return false;
    }

    if (Number(suministro.lecturaInicial) < 0) {
      this.error = 'La lectura inicial no puede ser negativa.';
      return false;
    }

    return true;
  }

  private validarLecturador(): boolean {
    if (!this.nuevoLecturador.dni || this.nuevoLecturador.dni.trim().length !== 8) {
      this.error = 'Ingrese un DNI válido de 8 dígitos para el lecturador.';
      return false;
    }

    if (!this.nuevoLecturador.nombres.trim()) {
      this.error = 'Ingrese los nombres del lecturador.';
      return false;
    }

    if (!this.nuevoLecturador.apellidos.trim()) {
      this.error = 'Ingrese los apellidos del lecturador.';
      return false;
    }

    if (!this.nuevoLecturador.codigoUsuario.trim()) {
      this.error = 'Ingrese el usuario de acceso del lecturador.';
      return false;
    }

    if (!this.nuevoLecturador.password.trim() || this.nuevoLecturador.password.trim().length < 6) {
      this.error = 'Ingrese una contraseña inicial de mínimo 6 caracteres.';
      return false;
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

  private crearLecturadorVacio(): LecturadorRequest {
    return {
      dni: '',
      nombres: '',
      apellidos: '',
      telefono: '',
      correo: '',
      codigoUsuario: '',
      password: 'lector123',
      estado: true,
      sectorAsignado: ''
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