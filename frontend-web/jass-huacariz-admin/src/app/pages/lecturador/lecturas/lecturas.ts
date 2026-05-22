import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';
import { Html5Qrcode } from 'html5-qrcode';

import {
  LecturaRequest,
  LecturaResponse,
  Lecturador,
  SuministroLecturadorResponse
} from '../../../core/services/lecturador';

@Component({
  selector: 'app-lecturas',
  imports: [CommonModule, FormsModule],
  templateUrl: './lecturas.html',
  styleUrl: './lecturas.scss',
})
export class LecturasLecturador implements OnDestroy {
  codigoBusqueda = '';

  suministro: SuministroLecturadorResponse | null = null;
  lecturaGenerada: LecturaResponse | null = null;

  cargando = false;
  registrando = false;
  escaneando = false;

  error = '';
  exito = '';

  lecturaForm: LecturaRequest = this.crearLecturaVacia();

  private qrScanner: Html5Qrcode | null = null;
  private qrProcesado = false;

  readonly qrRegionId = 'qr-reader-lecturador';

  constructor(
    private lecturadorService: Lecturador,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnDestroy(): void {
    this.detenerEscaneo();
  }

  buscarSuministro(desdeQr: boolean = false): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;
    this.suministro = null;

    const codigo = this.codigoBusqueda.trim().toUpperCase();

    if (!codigo) {
      this.error = 'Ingrese o escanee el código del suministro.';
      return;
    }

    this.codigoBusqueda = codigo;
    this.cargando = true;

    this.lecturadorService.buscarSuministro(codigo)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.suministro = data;

          this.lecturaForm = {
            codigoSuministro: data.codigoSuministro,
            anio: new Date().getFullYear(),
            mes: new Date().getMonth() + 1,
            lecturaActual: 0,
            observacion: 'Lectura mensual registrada'
          };

          const nombreCliente = this.nombreUsuarioSuministro(data);

          this.exito = desdeQr
            ? `QR escaneado correctamente. Usuario encontrado: ${nombreCliente}. Ahora registra la lectura.`
            : `Suministro encontrado correctamente. Usuario: ${nombreCliente}.`;

          this.cdr.detectChanges();

          setTimeout(() => {
            this.irARegistroLectura();
          }, 300);
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se encontró el suministro.';
          this.cdr.detectChanges();
        }
      });
  }

  registrarLectura(): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;

    if (!this.suministro) {
      this.error = 'Primero busque un suministro.';
      return;
    }

    if (!this.lecturaForm.anio || this.lecturaForm.anio < 2024) {
      this.error = 'Ingrese un año válido.';
      return;
    }

    if (!this.lecturaForm.mes || this.lecturaForm.mes < 1 || this.lecturaForm.mes > 12) {
      this.error = 'Ingrese un mes válido entre 1 y 12.';
      return;
    }

    if (!this.lecturaForm.lecturaActual || Number(this.lecturaForm.lecturaActual) <= 0) {
      this.error = 'Ingrese la lectura actual.';
      return;
    }

    if (Number(this.lecturaForm.lecturaActual) < Number(this.suministro.lecturaInicial)) {
      this.error = 'La lectura actual no puede ser menor a la lectura inicial/anterior.';
      return;
    }

    this.registrando = true;

    const payload: LecturaRequest = {
      codigoSuministro: this.suministro.codigoSuministro,
      anio: Number(this.lecturaForm.anio),
      mes: Number(this.lecturaForm.mes),
      lecturaActual: Number(this.lecturaForm.lecturaActual),
      observacion: this.lecturaForm.observacion?.trim() || 'Lectura mensual registrada'
    };

    this.lecturadorService.registrarLectura(payload)
      .pipe(
        finalize(() => {
          this.registrando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturaGenerada = data;
          this.exito = 'Lectura registrada y recibo generado correctamente.';
          this.cdr.detectChanges();

          setTimeout(() => {
            document.getElementById('recibo-generado')?.scrollIntoView({
              behavior: 'smooth',
              block: 'start'
            });
          }, 300);
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar la lectura.';
          this.cdr.detectChanges();
        }
      });
  }

  async iniciarEscaneo(): Promise<void> {
    this.error = '';
    this.exito = '';
    this.qrProcesado = false;

    if (this.escaneando) {
      return;
    }

    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.error = 'Tu navegador no permite acceso a la cámara.';
      return;
    }

    this.escaneando = true;
    this.cdr.detectChanges();

    setTimeout(async () => {
      try {
        const camaras = await Html5Qrcode.getCameras();

        if (!camaras || camaras.length === 0) {
          this.error = 'No se encontró ninguna cámara disponible.';
          this.escaneando = false;
          this.cdr.detectChanges();
          return;
        }

        const camaraTrasera = camaras.find((camara) => {
          const label = camara.label.toLowerCase();

          return (
            label.includes('back') ||
            label.includes('rear') ||
            label.includes('environment') ||
            label.includes('trasera') ||
            label.includes('posterior')
          );
        });

        const cameraId = camaraTrasera?.id || camaras[0].id;

        this.qrScanner = new Html5Qrcode(this.qrRegionId);

        await this.qrScanner.start(
          cameraId,
          {
            fps: 10,
            qrbox: {
              width: 260,
              height: 260
            }
          },
          async (decodedText: string) => {
            if (this.qrProcesado) {
              return;
            }

            this.qrProcesado = true;

            const codigo = this.normalizarCodigoQr(decodedText);

            if (!codigo) {
              this.error = 'El QR escaneado no contiene un código válido.';
              this.qrProcesado = false;
              this.cdr.detectChanges();
              return;
            }

            this.codigoBusqueda = codigo;
            this.exito = 'QR detectado correctamente. Deteniendo cámara y buscando usuario...';
            this.cdr.detectChanges();

            await this.detenerEscaneo();

            setTimeout(() => {
              this.buscarSuministro(true);
            }, 250);
          },
          () => {
            // No mostrar errores temporales del lector para evitar mensajes repetidos.
          }
        );
      } catch {
        this.error = 'No se pudo iniciar la cámara. Verifique permisos del navegador.';
        this.escaneando = false;
        this.qrScanner = null;
        this.cdr.detectChanges();
      }
    }, 250);
  }

  async detenerEscaneo(): Promise<void> {
    try {
      if (this.qrScanner) {
        if (this.escaneando) {
          await this.qrScanner.stop();
        }

        await this.qrScanner.clear();
      }
    } catch {
      // Puede fallar si la cámara ya estaba detenida.
    } finally {
      this.qrScanner = null;
      this.escaneando = false;
      this.cdr.detectChanges();
    }
  }

  limpiar(): void {
    this.detenerEscaneo();

    this.codigoBusqueda = '';
    this.suministro = null;
    this.lecturaGenerada = null;
    this.error = '';
    this.exito = '';
    this.qrProcesado = false;
    this.lecturaForm = this.crearLecturaVacia();
  }

  cerrarSesion(): void {
    this.detenerEscaneo();

    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] ?? 'Mes inválido';
  }

  nombreUsuarioSuministro(suministro: SuministroLecturadorResponse | null = this.suministro): string {
    const item: any = suministro || {};

    const nombreDirecto =
      item.cliente ||
      item.nombreCliente ||
      item.clienteNombre ||
      item.nombreCompletoCliente ||
      item.nombreCompleto ||
      item.usuarioNombre ||
      item.usuario ||
      '';

    if (nombreDirecto) {
      return String(nombreDirecto);
    }

    const nombres =
      item.nombresCliente ||
      item.nombres ||
      item.nombre ||
      '';

    const apellidos =
      item.apellidosCliente ||
      item.apellidos ||
      item.apellido ||
      '';

    const completo = `${nombres} ${apellidos}`.trim();

    return completo || 'No disponible';
  }

  dniUsuarioSuministro(suministro: SuministroLecturadorResponse | null = this.suministro): string {
    const item: any = suministro || {};

    return String(
      item.dniCliente ||
      item.documentoCliente ||
      item.numeroDocumentoCliente ||
      item.dni ||
      item.documento ||
      item.numeroDocumento ||
      '-'
    );
  }

  inicialesUsuario(): string {
    const nombre = this.nombreUsuarioSuministro();

    if (nombre === 'No disponible') {
      return 'U';
    }

    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }

  private irARegistroLectura(): void {
    document.getElementById('registro-lectura')?.scrollIntoView({
      behavior: 'smooth',
      block: 'start'
    });
  }

  private normalizarCodigoQr(valor: string): string {
    const texto = String(valor || '').trim();

    if (!texto) {
      return '';
    }

    try {
      const url = new URL(texto);
      const codigoParam = url.searchParams.get('codigo');

      if (codigoParam) {
        return codigoParam.trim().toUpperCase();
      }

      const partes = url.pathname.split('/').filter(Boolean);
      return (partes.pop() || '').trim().toUpperCase();
    } catch {
      return texto.trim().toUpperCase();
    }
  }

  private crearLecturaVacia(): LecturaRequest {
    return {
      codigoSuministro: '',
      anio: new Date().getFullYear(),
      mes: new Date().getMonth() + 1,
      lecturaActual: 0,
      observacion: 'Lectura mensual registrada'
    };
  }
}