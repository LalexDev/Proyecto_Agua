import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
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

  constructor(private router: Router) {}

  ngOnInit(): void {
    const temaGuardado = localStorage.getItem('jass-admin-theme') as TemaSistema | null;
    this.tema = temaGuardado === 'dark' ? 'dark' : 'light';
    this.aplicarTema();
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

  cerrarSesion(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('rol');
    localStorage.removeItem('codigoUsuario');
    sessionStorage.clear();
    document.body.classList.remove('jass-dark-theme');
    this.router.navigate(['/login']);
  }
}