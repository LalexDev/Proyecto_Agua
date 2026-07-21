import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import * as XLSX from 'xlsx-js-style';

import {
  LecturaAdmin,
  LecturaPendiente
} from '../../../core/services/lectura-admin';

@Component({
  selector: 'app-sin-lecturas',
  imports: [CommonModule, FormsModule],
  templateUrl: './sin-lecturas.html',
  styleUrl: './sin-lecturas.scss',
})
export class SinLecturas implements OnInit {
  pendientesLectura: LecturaPendiente[] = [];
  pendientesFiltrados: LecturaPendiente[] = [];

  busquedaPendientes = '';
  filtroPendienteAnio: number = new Date().getFullYear();
  filtroPendienteMes: number = new Date().getMonth() + 1;

  cargandoPendientes = false;
  errorPendientes = '';
  exitoPendientes = '';

  constructor(
    private lecturaAdmin: LecturaAdmin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.buscarPendientesLectura();
  }

  buscarPendientesLectura(): void {
    this.errorPendientes = '';
    this.exitoPendientes = '';

    if (!this.filtroPendienteAnio || Number(this.filtroPendienteAnio) < 2024) {
      this.errorPendientes = 'Ingrese un aÃ±o vÃ¡lido.';
      return;
    }

    if (!this.filtroPendienteMes || Number(this.filtroPendienteMes) < 1 || Number(this.filtroPendienteMes) > 12) {
      this.errorPendientes = 'Seleccione un mes vÃ¡lido.';
      return;
    }

    this.cargandoPendientes = true;

    this.lecturaAdmin.listarPendientesLectura(
      Number(this.filtroPendienteAnio),
      Number(this.filtroPendienteMes)
    )
      .pipe(
        finalize(() => {
          this.cargandoPendientes = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.pendientesLectura = data || [];
          this.aplicarFiltroPendientes();

          this.exitoPendientes = this.pendientesLectura.length > 0
            ? `Se encontraron ${this.pendientesLectura.length} usuario(s) sin lectura en ${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}.`
            : `Todos los suministros activos tienen lectura registrada en ${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}.`;
        },
        error: () => {
          this.errorPendientes = 'No se pudieron consultar los usuarios sin lectura.';
          this.exitoPendientes = '';
          this.pendientesLectura = [];
          this.pendientesFiltrados = [];
        }
      });
  }

  aplicarFiltroPendientes(): void {
    const texto = this.busquedaPendientes.trim().toLowerCase();

    this.pendientesFiltrados = this.pendientesLectura.filter((item: any) => {
      return (
        !texto ||
        String(item.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(item.nombreCliente || '').toLowerCase().includes(texto) ||
        String(item.dniCliente || '').toLowerCase().includes(texto) ||
        String(item.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(item.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(item.referencia || '').toLowerCase().includes(texto) ||
        String(item.sector || '').toLowerCase().includes(texto) ||
        String(item.estadoInstalacion || '').toLowerCase().includes(texto)
      );
    });
  }

  limpiarFiltroPendientes(): void {
    this.busquedaPendientes = '';
    this.aplicarFiltroPendientes();
  }

  exportarPendientesExcel(): void {
    const data = [
      [
        'NÂ°',
        'Suministro',
        'Cliente',
        'DNI',
        'Periodo',
        'DirecciÃ³n',
        'Referencia',
        'Sector',
        'Estado instalaciÃ³n',
        'Lectura anterior'
      ],
      ...this.pendientesFiltrados.map((item: any, index) => [
        index + 1,
        item.codigoSuministro || '',
        item.nombreCliente || '',
        item.dniCliente || '',
        `${this.nombreMes(Number(item.mes))} ${item.anio}`,
        item.direccionSuministro || '',
        item.referencia || '',
        item.sector || '',
        this.estadoInstalacionTexto(item.estadoInstalacion),
        Number(item.lecturaAnterior || 0)
      ])
    ];

    const hoja = XLSX.utils.aoa_to_sheet(data);
    const libro = XLSX.utils.book_new();

    hoja['!cols'] = [
      { wch: 6 },
      { wch: 18 },
      { wch: 30 },
      { wch: 14 },
      { wch: 18 },
      { wch: 34 },
      { wch: 28 },
      { wch: 20 },
      { wch: 24 },
      { wch: 18 }
    ];

    XLSX.utils.book_append_sheet(libro, hoja, 'Sin lectura');

    XLSX.writeFile(
      libro,
      `usuarios_sin_lectura_${this.filtroPendienteAnio}_${this.filtroPendienteMes}.xlsx`
    );
  }

  imprimirPendientes(): void {
    const ventana = window.open('', '_blank', 'width=1100,height=850');

    if (!ventana) {
      alert('El navegador bloqueÃ³ la ventana de impresiÃ³n.');
      return;
    }

    const periodo = `${this.nombreMes(Number(this.filtroPendienteMes))} ${this.filtroPendienteAnio}`;

    const filas = this.pendientesFiltrados.map((item: any, index) => `
      <tr>
        <td>${index + 1}</td>
        <td>${this.textoSeguro(item.codigoSuministro || '-')}</td>
        <td>${this.textoSeguro(item.nombreCliente || '-')}</td>
        <td>${this.textoSeguro(item.dniCliente || '-')}</td>
        <td>${this.textoSeguro(periodo)}</td>
        <td>${this.textoSeguro(item.direccionSuministro || '-')}</td>
        <td>${this.textoSeguro(item.sector || '-')}</td>
        <td>${this.textoSeguro(this.estadoInstalacionTexto(item.estadoInstalacion))}</td>
        <td>${Number(item.lecturaAnterior || 0).toFixed(3)} mÂ³</td>
      </tr>
    `).join('');

    ventana.document.write(`
      <html>
      <head>
        <title>Usuarios sin lectura</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 24px; color: #0f2f44; }
          h1 { color: #0f7fa0; margin-bottom: 4px; }
          p { margin-top: 0; color: #64748b; }
          table { width: 100%; border-collapse: collapse; font-size: 12px; }
          th { background: #0f7fa0; color: white; padding: 8px; text-align: left; }
          td { border: 1px solid #d7e3ea; padding: 8px; }
          tr:nth-child(even) td { background: #f8fcfd; }
          .actions { margin-top: 18px; text-align: right; }
          button { padding: 10px 16px; border: none; border-radius: 8px; font-weight: 700; cursor: pointer; }
          .print { background: #0f7fa0; color: white; }
          @media print { .actions { display: none; } }
        </style>
      </head>
      <body>
        <h1>AGUA POTABLE HUACARIZ</h1>
        <p>Historial de usuarios sin lectura - ${this.textoSeguro(periodo)}</p>

        <table>
          <thead>
            <tr>
              <th>NÂ°</th>
              <th>Suministro</th>
              <th>Cliente</th>
              <th>DNI</th>
              <th>Periodo</th>
              <th>DirecciÃ³n</th>
              <th>Sector</th>
              <th>InstalaciÃ³n</th>
              <th>Lectura anterior</th>
            </tr>
          </thead>
          <tbody>
            ${filas || '<tr><td colspan="9">No hay usuarios sin lectura.</td></tr>'}
          </tbody>
        </table>

        <div class="actions">
          <button onclick="window.print()" class="print">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `);

    ventana.document.close();
  }

  totalSinLectura(): number {
    return this.pendientesFiltrados.length;
  }

  pendientesInstalados(): number {
    return this.pendientesFiltrados.filter((item) => {
      return this.estadoInstalacionTexto(item.estadoInstalacion).toUpperCase() === 'INSTALADO';
    }).length;
  }

  pendientesPorInstalar(): number {
    return this.pendientesFiltrados.filter((item) => {
      return this.estadoInstalacionTexto(item.estadoInstalacion).toUpperCase() !== 'INSTALADO';
    }).length;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes invÃ¡lido';
  }

  estadoInstalacionTexto(estado?: string): string {
    const valor = String(estado || '').toUpperCase();

    if (valor === 'INSTALADO') {
      return 'Instalado';
    }

    if (valor === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    return 'Pendiente de instalaciÃ³n';
  }

  estadoInstalacionClase(estado?: string): string {
    const valor = String(estado || '').toUpperCase();

    if (valor === 'INSTALADO') {
      return 'instalado';
    }

    if (valor === 'SUSPENDIDO') {
      return 'suspendido';
    }

    return 'pendiente-instalacion';
  }

  private textoSeguro(valor: any): string {
    return String(valor ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}
