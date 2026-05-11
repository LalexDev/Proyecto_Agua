import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login',
  imports: [],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class Login {
  constructor(private router: Router) {}

  entrarComoAdmin(): void {
    this.router.navigate(['/admin/dashboard']);
  }

  entrarComoCliente(): void {
    this.router.navigate(['/cliente/inicio']);
  }
}