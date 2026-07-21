import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface MovimientoCajaRequest {
  tipoMovimiento?: string;
  categoria: string;
  descripcion: string;
  monto: number;
  responsable?: string;
  comprobanteUrl?: string;
}

export interface MovimientoCajaResponse {
  id: number;
  tipoMovimiento: string;
  categoria: string;
  descripcion: string;
  monto: number;
  responsable?: string;
  comprobanteUrl?: string;
  fechaMovimiento: string;
  estado: string;
}

export interface ResumenCajaResponse {
  totalEgresos: number;
  totalIngresosManuales: number;
  movimientosActivos: number;
}

@Injectable({
  providedIn: 'root',
})
export class MovimientoCaja {
  private readonly apiUrl = '/api/movimientos-caja';

  constructor(private http: HttpClient) {}

  listar(): Observable<MovimientoCajaResponse[]> {
    return this.http.get<MovimientoCajaResponse[]>(this.apiUrl);
  }

  listarActivos(): Observable<MovimientoCajaResponse[]> {
    return this.http.get<MovimientoCajaResponse[]>(`${this.apiUrl}/activos`);
  }

  resumen(): Observable<ResumenCajaResponse> {
    return this.http.get<ResumenCajaResponse>(`${this.apiUrl}/resumen`);
  }

  crear(data: MovimientoCajaRequest): Observable<MovimientoCajaResponse> {
    return this.http.post<MovimientoCajaResponse>(this.apiUrl, data);
  }

  anular(id: number): Observable<MovimientoCajaResponse> {
    return this.http.patch<MovimientoCajaResponse>(`${this.apiUrl}/${id}/anular`, {});
  }
}
