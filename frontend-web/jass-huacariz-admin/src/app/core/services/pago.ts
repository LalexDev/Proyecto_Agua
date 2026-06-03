import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PagoResponse {
  id: number;
  idRecibo: number;
  codigoRecibo: string;
  metodoPago: string;
  codigoOperacion: string;
  monto: number;
  estadoPago: string;
  fechaPago: string;
}

@Injectable({
  providedIn: 'root',
})
export class Pago {
  private readonly apiUrl = 'https://qnsdd0d9-8080.brs.devtunnels.ms/api/pagos';

  constructor(private http: HttpClient) {}

  listarPagos(): Observable<PagoResponse[]> {
    return this.http.get<PagoResponse[]>(this.apiUrl);
  }

  buscarPorSuministro(codigoSuministro: string): Observable<PagoResponse[]> {
    return this.http.get<PagoResponse[]>(`${this.apiUrl}/suministro/${codigoSuministro}`);
  }
}