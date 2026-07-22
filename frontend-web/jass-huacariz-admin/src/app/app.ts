import { CommonModule } from '@angular/common';
import { Component, OnDestroy, signal } from '@angular/core';
import { Router, RouterOutlet } from '@angular/router';
import { Subscription } from 'rxjs';
import { SessionTimeoutService } from './core/services/session-timeout.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnDestroy {
  protected readonly title = signal('jass-huacariz-admin');

  modalSesionExpiradaVisible = false;
  private sessionSubscription: Subscription;

  constructor(
    private sessionTimeoutService: SessionTimeoutService,
    private router: Router
  ) {
    this.sessionTimeoutService.iniciar();

    this.sessionSubscription = this.sessionTimeoutService.sesionExpirada$
      .subscribe(() => {
        this.modalSesionExpiradaVisible = true;
      });
  }

  cerrarModalSesionExpirada(): void {
    this.modalSesionExpiradaVisible = false;
    this.router.navigate(['/login']);
  }

  ngOnDestroy(): void {
    this.sessionSubscription.unsubscribe();
  }
}