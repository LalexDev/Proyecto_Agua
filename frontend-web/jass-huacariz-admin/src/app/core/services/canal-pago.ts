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
  private readonly apiUrl = '/api/canales-pago';

  constructor(private http: HttpClient) {}

  listarActivos(): Observable<CanalPagoResponse[]> {
    return this.http.get<CanalPagoResponse[]>(`${this.apiUrl}/activos`);
  }

  listarTodos(): Observable<CanalPagoResponse[]> {
    return this.http.get<CanalPagoResponse[]>(this.apiUrl);
  }

  actualizar(
      id: number,
      data: CanalPagoResponse,
      qr?: File
    ): Observable<CanalPagoResponse> {
      const formData = new FormData();

      formData.append('datos', JSON.stringify(data));

      if (qr) {
        formData.append('qr', qr);
      }

      return this.http.put<CanalPagoResponse>(
        `${this.apiUrl}/${id}`,
        formData
      );
    }

    crear(
      data: CanalPagoResponse,
      qr?: File
    ): Observable<CanalPagoResponse> {
      const formData = new FormData();

      formData.append('datos', JSON.stringify(data));

      if (qr) {
        formData.append('qr', qr);
      }

      return this.http.post<CanalPagoResponse>(
        this.apiUrl,
        formData
      );
    }
}
