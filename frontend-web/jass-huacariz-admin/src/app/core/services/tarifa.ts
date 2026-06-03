import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface TarifaRequest {
  nombreTarifa: string;
  consumoDesde: number;
  consumoHasta: number | null;
  precioM3: number;
  estado: boolean;
}

export interface TarifaResponse {
  id: number;
  nombreTarifa: string;
  nombre?: string;
  consumoDesde: number;
  consumoHasta: number | null;
  precioM3: number;
  estado: boolean;
}

export interface ConfiguracionCobranzaRequest {
  cargoLector: number;
  cargoMantenimiento: number;
  cargoOtros: number;
  diasVencimiento: number;
  moraBase: number;
}

export interface ConfiguracionCobranzaResponse {
  id: number;
  cargoLector: number;
  cargoMantenimiento: number;
  cargoOtros: number;
  diasVencimiento: number;
  moraBase: number;
  fechaActualizacion: string;
}

@Injectable({
  providedIn: 'root',
})
export class Tarifa {
  private readonly apiUrl = 'https://qnsdd0d9-8080.brs.devtunnels.ms/api/tarifas';

  constructor(private http: HttpClient) {}

  listarTarifas(): Observable<TarifaResponse[]> {
    return this.http.get<TarifaResponse[]>(this.apiUrl);
  }

  obtenerTarifaPorId(id: number): Observable<TarifaResponse> {
    return this.http.get<TarifaResponse>(`${this.apiUrl}/${id}`);
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

  obtenerConfiguracionCobranza(): Observable<ConfiguracionCobranzaResponse> {
    return this.http.get<ConfiguracionCobranzaResponse>(`${this.apiUrl}/configuracion-cobranza`);
  }

  guardarConfiguracionCobranza(
    data: ConfiguracionCobranzaRequest
  ): Observable<ConfiguracionCobranzaResponse> {
    return this.http.put<ConfiguracionCobranzaResponse>(
      `${this.apiUrl}/configuracion-cobranza`,
      data
    );
  }
}