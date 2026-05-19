import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

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

    this.clientePortal.obtenerMiPerfil()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.perfil = data;
          this.cargarSuministros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar tu perfil.';
          this.cdr.detectChanges();
        }
      });
  }

  cargarSuministros(): void {
    this.clientePortal.listarMisSuministros()
      .subscribe({
        next: (data) => {
          this.suministros = data;
          this.cdr.detectChanges();
        },
        error: () => {
          this.suministros = [];
          this.cdr.detectChanges();
        }
      });
  }

  nombreCompleto(): string {
    if (!this.perfil) {
      return '';
    }

    return `${this.perfil.nombres} ${this.perfil.apellidos}`;
  }

  estadoTexto(): string {
    return this.perfil?.estado ? 'Activo' : 'Inactivo';
  }
}