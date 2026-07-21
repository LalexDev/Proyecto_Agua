import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class Token {
  private readonly TOKEN_KEY = 'token';
  private readonly ROL_KEY = 'rol';
  private readonly CODIGO_KEY = 'codigoUsuario';

  guardarSesion(token: string, rol: string, codigoUsuario: string): void {
    localStorage.setItem(this.TOKEN_KEY, token);
    localStorage.setItem(this.ROL_KEY, rol);
    localStorage.setItem(this.CODIGO_KEY, codigoUsuario);
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  getRol(): string | null {
    return localStorage.getItem(this.ROL_KEY);
  }

  getCodigoUsuario(): string | null {
    return localStorage.getItem(this.CODIGO_KEY);
  }

  estaAutenticado(): boolean {
    return !!this.getToken();
  }

  limpiarSesion(): void {
    localStorage.clear();
  }
}
