import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface CanalPagoResponse {
  id: number;
  metodoPago: string;
  titular: string;
  numero?: string;
  banco?: string;
  cuenta?: string;
  cci?: string;
  descripcion?: string;
  qrUrl?: string;
  estado: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class CanalPago {
  private readonly apiUrl = 'https://qnsdd0d9-8080.brs.devtunnels.ms/api/canales-pago';

  constructor(private http: HttpClient) {}

  listarActivos(): Observable<CanalPagoResponse[]> {
    return this.http.get<CanalPagoResponse[]>(`${this.apiUrl}/activos`);
  }

  listarTodos(): Observable<CanalPagoResponse[]> {
    return this.http.get<CanalPagoResponse[]>(this.apiUrl);
  }

  actualizar(id: number, data: Partial<CanalPagoResponse>): Observable<CanalPagoResponse> {
    return this.http.put<CanalPagoResponse>(`${this.apiUrl}/${id}`, data);
  }
}