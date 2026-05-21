import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface TarifaResponse {
  id: number;
  nombreTarifa: string;
  consumoDesde: number;
  consumoHasta: number | null;
  precioM3: number;
  estado: boolean;
}

export interface TarifaRequest {
  nombreTarifa: string;
  consumoDesde: number;
  consumoHasta: number | null;
  precioM3: number;
  estado: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class Tarifa {
  private readonly apiUrl = 'http://localhost:8080/api/tarifas';

  constructor(private http: HttpClient) {}

  listarTarifas(): Observable<TarifaResponse[]> {
    return this.http.get<TarifaResponse[]>(this.apiUrl);
  }

  registrarTarifa(data: TarifaRequest): Observable<TarifaResponse> {
    return this.http.post<TarifaResponse>(this.apiUrl, data);
  }

  actualizarTarifa(id: number, data: TarifaRequest): Observable<TarifaResponse> {
    return this.http.put<TarifaResponse>(`${this.apiUrl}/${id}`, data);
  }

  cambiarEstadoTarifa(id: number, estado: boolean): Observable<TarifaResponse> {
    return this.http.patch<TarifaResponse>(`${this.apiUrl}/${id}/estado?estado=${estado}`, {});
  }

  eliminarTarifa(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}