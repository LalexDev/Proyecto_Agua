import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

type TemaSistema = 'light' | 'dark';

@Component({
  selector: 'app-admin-layout',
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './admin-layout.html',
  styleUrl: './admin-layout.scss',
})
export class AdminLayout implements OnInit {
  tema: TemaSistema = 'light';
  menuMovilAbierto = false;

  constructor(private router: Router) {}

  ngOnInit(): void {
    const temaGuardado = localStorage.getItem('jass-admin-theme') as TemaSistema | null;
    this.tema = temaGuardado === 'dark' ? 'dark' : 'light';
    this.aplicarTema();
  }

  @HostListener('window:resize')
  onResize(): void {
    if (window.innerWidth > 980) {
      this.menuMovilAbierto = false;
      document.body.classList.remove('menu-mobile-open');
    }
  }

  cambiarTema(): void {
    this.tema = this.tema === 'dark' ? 'light' : 'dark';
    localStorage.setItem('jass-admin-theme', this.tema);
    this.aplicarTema();
  }

  aplicarTema(): void {
    document.body.classList.toggle('jass-dark-theme', this.tema === 'dark');
  }

  esOscuro(): boolean {
    return this.tema === 'dark';
  }

  abrirCerrarMenuMovil(): void {
    this.menuMovilAbierto = !this.menuMovilAbierto;
    document.body.classList.toggle('menu-mobile-open', this.menuMovilAbierto);
  }

  cerrarMenuMovil(): void {
    if (window.innerWidth <= 980) {
      this.menuMovilAbierto = false;
      document.body.classList.remove('menu-mobile-open');
    }
  }
  forzarCerrarMenuMovil(): void {
    this.menuMovilAbierto = false;
    document.body.classList.remove('menu-mobile-open');
  }

  cerrarSesion(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('rol');
    localStorage.removeItem('role');
    localStorage.removeItem('codigoUsuario');
    localStorage.removeItem('tipoToken');
    localStorage.removeItem('expiracion');

    sessionStorage.clear();
    document.body.classList.remove('jass-dark-theme');
    document.body.classList.remove('menu-mobile-open');

    this.router.navigate(['/login']);
  }
}