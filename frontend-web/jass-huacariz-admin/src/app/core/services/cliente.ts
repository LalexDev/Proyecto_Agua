import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface SuministroResponse {
  id: number;
  codigoSuministro: string;
  idSector: number;
  nombreSector: string;
  direccionSuministro: string;
  referencia: string;
  aliasSuministro: string;
  lecturaInicial: number;
  estado: boolean;
}

export interface ClienteResponse {
  id: number;
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  estado: boolean;
  codigoUsuario: string;
  passwordInicial: string;
  suministros: SuministroResponse[];
}

@Injectable({
  providedIn: 'root',
})
export class Cliente {
  private readonly apiUrl = 'http://localhost:8080/api/clientes';

  constructor(private http: HttpClient) {}

  listarClientes(): Observable<ClienteResponse[]> {
    return this.http.get<ClienteResponse[]>(this.apiUrl);
  }
}