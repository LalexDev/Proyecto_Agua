import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SessionTimeoutService } from './core/services/session-timeout.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  protected readonly title = signal('jass-huacariz-admin');

  constructor(private sessionTimeoutService: SessionTimeoutService) {
    this.sessionTimeoutService.iniciar();
  }
}