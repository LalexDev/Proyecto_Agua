import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, HostListener, OnInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';

import {
  ClientePerfilResponse,
  ClientePortal
} from '../../core/services/cliente-portal';

@Component({
  selector: 'app-cliente-layout',
  imports: [CommonModule, RouterModule],
  templateUrl: './cliente-layout.html',
  styleUrl: './cliente-layout.scss',
})
export class ClienteLayout implements OnInit {
  perfil: ClientePerfilResponse | null = null;

  nombreUsuario = 'Cliente';
  codigoUsuario = '';
  isDarkMode = false;
  menuMovilAbierto = false;

  constructor(
    private router: Router,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarTema();
    this.cargarDatosLocales();
    this.cargarPerfilCliente();
  }

  @HostListener('window:resize')
  onResize(): void {
    if (window.innerWidth > 980) {
      this.menuMovilAbierto = false;
      document.body.classList.remove('menu-mobile-open');
    }
  }

  cargarDatosLocales(): void {
    this.nombreUsuario =
      localStorage.getItem('nombreUsuario') ||
      localStorage.getItem('nombreCliente') ||
      'Cliente';

    this.codigoUsuario =
      localStorage.getItem('codigoUsuario') ||
      localStorage.getItem('dni') ||
      '';
  }

  cargarPerfilCliente(): void {
    this.clientePortal.obtenerMiPerfil().subscribe({
      next: (perfil) => {
        this.perfil = perfil;
        this.aplicarPerfil(perfil);
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargarDatosLocales();
        this.cdr.detectChanges();
      }
    });
  }

  aplicarPerfil(perfil: ClientePerfilResponse): void {
    const item: any = perfil || {};

    const nombreCompleto = `${item.nombres || ''} ${item.apellidos || ''}`.trim();

    this.nombreUsuario =
      nombreCompleto ||
      item.nombreCompleto ||
      localStorage.getItem('nombreUsuario') ||
      'Cliente';

    this.codigoUsuario =
      item.dni ||
      item.documento ||
      item.numeroDocumento ||
      item.codigoUsuario ||
      item.usuario ||
      localStorage.getItem('codigoUsuario') ||
      '';

    localStorage.setItem('nombreUsuario', this.nombreUsuario);

    if (this.codigoUsuario) {
      localStorage.setItem('codigoUsuario', this.codigoUsuario);
    }
  }

  nombreVisible(): string {
    return this.nombreUsuario || 'Cliente';
  }

  codigoVisible(): string {
    return this.codigoUsuario || 'Usuario cliente';
  }

  iniciales(): string {
    const nombre = this.nombreVisible();
    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }

  cargarTema(): void {
    const temaGuardado = localStorage.getItem('jass-theme');

    this.isDarkMode = temaGuardado === 'dark';

    document.body.setAttribute('data-theme', this.isDarkMode ? 'dark' : 'light');
    document.body.classList.toggle('jass-dark-theme', this.isDarkMode);
  }

  cambiarTema(): void {
    this.isDarkMode = !this.isDarkMode;

    localStorage.setItem('jass-theme', this.isDarkMode ? 'dark' : 'light');

    document.body.setAttribute('data-theme', this.isDarkMode ? 'dark' : 'light');
    document.body.classList.toggle('jass-dark-theme', this.isDarkMode);
  }

  abrirCerrarMenuMovil(): void {
    this.menuMovilAbierto = !this.menuMovilAbierto;
    document.body.classList.toggle('menu-mobile-open', this.menuMovilAbierto);
  }

  cerrarMenuMovil(): void {
    this.menuMovilAbierto = false;
    document.body.classList.remove('menu-mobile-open');
  }

  cerrarSesion(): void {
    localStorage.clear();
    sessionStorage.clear();

    document.body.classList.remove('jass-dark-theme');
    document.body.classList.remove('menu-mobile-open');
    document.body.setAttribute('data-theme', 'light');

    this.router.navigate(['/login']);
  }
}