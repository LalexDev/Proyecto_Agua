import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import {
  ClientePerfilResponse,
  ClientePortal
} from '../../core/services/cliente-portal';

import { Auth } from '../../core/services/auth';

@Component({
  selector: 'app-cliente-layout',
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './cliente-layout.html',
  styleUrl: './cliente-layout.scss'
})
export class ClienteLayout implements OnInit {
  perfil: ClientePerfilResponse | null = null;
  cargandoPerfil = false;

  constructor(
    private clientePortal: ClientePortal,
    private auth: Auth,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarPerfil();
  }

  cargarPerfil(): void {
    this.cargandoPerfil = true;

    this.clientePortal.obtenerMiPerfil()
      .subscribe({
        next: (data) => {
          this.perfil = data;
          this.cargandoPerfil = false;
          this.cdr.detectChanges();
        },
        error: () => {
          this.perfil = null;
          this.cargandoPerfil = false;
          this.cdr.detectChanges();
        }
      });
  }

  nombreCliente(): string {
    if (!this.perfil) {
      return 'Cliente';
    }

    return `${this.perfil.nombres || ''} ${this.perfil.apellidos || ''}`.trim();
  }

  inicialCliente(): string {
    const nombre = this.perfil?.nombres || 'C';
    return nombre.charAt(0).toUpperCase();
  }

  codigoUsuario(): string {
    return this.perfil?.codigoUsuario || localStorage.getItem('codigoUsuario') || 'CLIENTE';
  }

  cerrarSesion(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}