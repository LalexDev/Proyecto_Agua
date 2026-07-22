import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';

export interface ClientePerfilResponse {
  id?: number;
  idCliente?: number;
  dni?: string;
  nombres?: string;
  apellidos?: string;
  telefono?: string;
  correo?: string;
  codigoUsuario?: string;
  usuario?: string;
  estado?: boolean;
}

export interface SuministroClienteResponse {
  id?: number;
  codigoSuministro: string;
  idSector?: number;
  nombreSector?: string;
  sector?: string;
  direccionSuministro?: string;
  direccion?: string;
  referencia?: string;
  aliasSuministro?: string;
  lecturaInicial?: number;
  estado?: boolean | string;
  estadoSuministro?: string;
  estadoInstalacion?: string;
}

export interface ReciboClienteResponse {
  id: number;
  codigoRecibo: string;

  codigoSuministro?: string;
  direccionSuministro?: string;
  aliasSuministro?: string;
  sector?: string;

  nombreCliente?: string;
  dniCliente?: string;

  anio: number;
  mes: number;

  consumoM3: number;

  cambioMedidor?: boolean;
  lecturaInicialNuevoMedidor?: number | null;
  observacionCambioMedidor?: string | null;
  consumoInusual?: boolean;

  subtotalAgua: number;
  cargoMantenimiento: number;
  cargoLector: number;
  cargoOtros: number;
  mora: number;
  total: number;

  estadoRecibo: string;
  fechaEmision: string;
  fechaVencimiento: string;

  codigoBarras?: string;
}

export interface PagoRequest {
  metodoPago: string;
  codigoOperacion: string;
}

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

export interface CambiarPasswordRequest {
  passwordActual: string;
  nuevaPassword: string;
  confirmarPassword: string;
}

@Injectable({
  providedIn: 'root',
})
export class ClientePortal {
  private readonly apiUrl = '/api/cliente';

  constructor(private http: HttpClient) {}

  obtenerMiPerfil(): Observable<ClientePerfilResponse> {
    return this.http.get<ClientePerfilResponse>(`${this.apiUrl}/me`);
  }

  listarMisSuministros(): Observable<SuministroClienteResponse[]> {
    return this.http.get<SuministroClienteResponse[]>(`${this.apiUrl}/me/suministros`);
  }

  listarMisRecibos(): Observable<ReciboClienteResponse[]> {
    return this.http.get<ReciboClienteResponse[]>(`${this.apiUrl}/me/recibos`);
  }

  obtenerReciboPorId(id: number): Observable<ReciboClienteResponse> {
    return this.listarMisRecibos().pipe(
      map((recibos) => {
        const recibo = recibos.find((item) => Number(item.id) === Number(id));

        if (!recibo) {
          throw new Error('No se encontrÃ³ el recibo solicitado.');
        }

        return recibo;
      })
    );
  }

  pagarMiRecibo(
    idRecibo: number,
    metodoPago: string,
    codigoOperacion: string,
    comprobante: File
  ): Observable<PagoResponse> {
    const formData = new FormData();

    formData.append('metodoPago', metodoPago);
    formData.append('codigoOperacion', codigoOperacion);
    formData.append('comprobante', comprobante);

    return this.http.patch<PagoResponse>(
      `${this.apiUrl}/me/recibos/${idRecibo}/pagar`,
      formData
    );
  }

  cambiarMiPassword(data: CambiarPasswordRequest): Observable<{ mensaje: string }> {
    return this.http.patch<{ mensaje: string }>(
      `${this.apiUrl}/me/password`,
      data
    );
  }
}
