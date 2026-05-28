import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { Router, RouterModule } from '@angular/router';

@Component({
  selector: 'app-cliente-layout',
  imports: [CommonModule, RouterModule],
  templateUrl: './cliente-layout.html',
  styleUrl: './cliente-layout.scss',
})
export class ClienteLayout {
  nombreUsuario = localStorage.getItem('nombreUsuario') || localStorage.getItem('codigoUsuario') || 'Cliente';
  codigoUsuario = localStorage.getItem('codigoUsuario') || '';

  constructor(private router: Router) {}

  inicial(): string {
    return this.nombreUsuario.substring(0, 1).toUpperCase();
  }

  cerrarSesion(): void {
    localStorage.clear();
    this.router.navigate(['/login']);
  }
}