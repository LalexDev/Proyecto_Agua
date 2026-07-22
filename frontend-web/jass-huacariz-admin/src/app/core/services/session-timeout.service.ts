import { Injectable, NgZone } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class SessionTimeoutService {
  private readonly tiempoLimiteMs = 10 * 60 * 1000; // 10 minutos
  private temporizador: any = null;
  private escuchandoEventos = false;

  private readonly eventos = [
    'click',
    'mousemove',
    'keydown',
    'scroll',
    'touchstart'
  ];

  constructor(
    private router: Router,
    private ngZone: NgZone
  ) {}

  iniciar(): void {
    if (!this.escuchandoEventos) {
      this.eventos.forEach((evento) => {
        window.addEventListener(evento, this.registrarActividad);
      });

      this.escuchandoEventos = true;
    }

    this.router.events
      .pipe(filter((event) => event instanceof NavigationEnd))
      .subscribe(() => {
        this.reiniciarTemporizador();
      });

    this.reiniciarTemporizador();
  }

  private registrarActividad = (): void => {
    this.reiniciarTemporizador();
  };

  private reiniciarTemporizador(): void {
    this.limpiarTemporizador();

    if (!this.haySesionActiva()) {
      return;
    }

    this.ngZone.runOutsideAngular(() => {
      this.temporizador = setTimeout(() => {
        this.ngZone.run(() => {
          this.cerrarSesionPorInactividad();
        });
      }, this.tiempoLimiteMs);
    });
  }

  private limpiarTemporizador(): void {
    if (this.temporizador) {
      clearTimeout(this.temporizador);
      this.temporizador = null;
    }
  }

  private haySesionActiva(): boolean {
    return !!localStorage.getItem('token');
  }

  private cerrarSesionPorInactividad(): void {
    this.limpiarTemporizador();

    localStorage.removeItem('token');
    localStorage.removeItem('rol');
    localStorage.removeItem('codigoUsuario');
    localStorage.removeItem('debeCambiarPassword');

    sessionStorage.clear();

    alert('Tu sesión se cerró por inactividad.');

    this.router.navigate(['/login']);
  }
}