import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePerfilResponse,
  ClientePortal,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-perfil',
  imports: [CommonModule, RouterModule],
  templateUrl: './perfil.html',
  styleUrl: './perfil.scss',
})
export class Perfil implements OnInit {
  perfil: ClientePerfilResponse | null = null;
  suministros: SuministroClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarPerfil();
  }

  cargarPerfil(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      perfil: this.clientePortal.obtenerMiPerfil(),
      suministros: this.clientePortal.listarMisSuministros()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ perfil, suministros }) => {
          this.perfil = perfil;
          this.suministros = suministros || [];
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la información de tu perfil.';
          this.perfil = null;
          this.suministros = [];
          this.cdr.detectChanges();
        }
      });
  }

  nombreCompleto(): string {
    if (!this.perfil) {
      return 'Cliente';
    }

    const item: any = this.perfil;
    return `${item.nombres || ''} ${item.apellidos || ''}`.trim() || 'Cliente';
  }

  iniciales(): string {
    const nombre = this.nombreCompleto();
    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }

  valorPerfil(campo: string): string {
    const item: any = this.perfil || {};
    return item[campo] || '-';
  }

  codigoUsuario(): string {
    const item: any = this.perfil || {};
    return item.codigoUsuario || item.usuario || localStorage.getItem('codigoUsuario') || '-';
  }

  dniCliente(): string {
    const item: any = this.perfil || {};
    return item.dni || item.documento || item.numeroDocumento || '-';
  }

  telefonoCliente(): string {
    const item: any = this.perfil || {};
    return item.telefono || item.celular || '-';
  }

  correoCliente(): string {
    const item: any = this.perfil || {};
    return item.correo || item.email || '-';
  }

  direccionPrincipal(): string {
    const principal = this.suministros.length ? this.suministros[0] : null;

    if (!principal) {
      return '-';
    }

    const item: any = principal;
    return item.direccionSuministro || item.direccion || '-';
  }

  suministrosActivos(): number {
    return this.suministros.filter((item: any) => {
      return item.estado === true ||
        String(item.estado || '').toUpperCase() === 'ACTIVO' ||
        String(item.estadoSuministro || '').toUpperCase() === 'ACTIVO' ||
        String(item.estadoInstalacion || '').toUpperCase() === 'INSTALADO';
    }).length;
  }

  estadoSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro;

    if (
      item.estado === false ||
      String(item.estado || '').toUpperCase() === 'SUSPENDIDO' ||
      String(item.estadoSuministro || '').toUpperCase() === 'SUSPENDIDO'
    ) {
      return 'Suspendido';
    }

    return 'Activo';
  }

  estadoClase(suministro: SuministroClienteResponse): string {
    return this.estadoSuministro(suministro).toLowerCase() === 'activo'
      ? 'activo'
      : 'suspendido';
  }

  suministroValor(suministro: SuministroClienteResponse, campo: string): string {
    const item: any = suministro || {};
    return item[campo] || '-';
  }
}