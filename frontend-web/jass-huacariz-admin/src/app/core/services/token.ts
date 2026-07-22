import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class Token {
  private readonly TOKEN_KEY = 'token';
  private readonly ROL_KEY = 'rol';
  private readonly CODIGO_KEY = 'codigoUsuario';
  private readonly DEBE_CAMBIAR_PASSWORD_KEY = 'debeCambiarPassword';

  guardarSesion(
    token: string,
    rol: string,
    codigoUsuario: string,
    debeCambiarPassword: boolean = false
  ): void {
    localStorage.setItem(this.TOKEN_KEY, token);
    localStorage.setItem(this.ROL_KEY, rol);
    localStorage.setItem(this.CODIGO_KEY, codigoUsuario);
    localStorage.setItem(
      this.DEBE_CAMBIAR_PASSWORD_KEY,
      String(debeCambiarPassword)
    );
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

  debeCambiarPassword(): boolean {
    return localStorage.getItem(this.DEBE_CAMBIAR_PASSWORD_KEY) === 'true';
  }

  marcarPasswordCambiado(): void {
    localStorage.setItem(this.DEBE_CAMBIAR_PASSWORD_KEY, 'false');
  }

  limpiarSesion(): void {
    localStorage.clear();
  }
}
