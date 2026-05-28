import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';
import { Html5Qrcode } from 'html5-qrcode';

import {
  LecturaRequest,
  Lecturador,
  MantenimientoRequest,
  SuministroLecturadorResponse
} from '../../../core/services/lecturador';

type ModoOperacion = 'LECTURA' | 'MANTENIMIENTO' | null;

@Component({
  selector: 'app-lecturas',
  imports: [CommonModule, FormsModule],
  templateUrl: './lecturas.html',
  styleUrl: './lecturas.scss',
})
export class LecturasLecturador implements OnInit, OnDestroy {
  codigoBusqueda = '';

  suministro: SuministroLecturadorResponse | null = null;
  lecturaGenerada: any = null;

  cargando = false;
  registrando = false;
  generandoMantenimiento = false;
  escaneando = false;

  error = '';
  exito = '';

  isDarkMode = false;
  modoOperacion: ModoOperacion = null;

  lecturaForm: LecturaRequest = this.crearLecturaVacia();
  mantenimientoForm: MantenimientoRequest = this.crearMantenimientoVacio();

  private qrScanner: Html5Qrcode | null = null;
  private qrProcesado = false;

  readonly qrRegionId = 'qr-reader-lecturador';

  constructor(
    private lecturadorService: Lecturador,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarTema();
  }

  ngOnDestroy(): void {
    this.detenerEscaneo();
  }

  cargarTema(): void {
    const temaGuardado = localStorage.getItem('jass-theme');
    this.isDarkMode = temaGuardado === 'dark';

    document.body.setAttribute('data-theme', this.isDarkMode ? 'dark' : 'light');
    document.body.classList.toggle('jass-dark-theme', this.isDarkMode);
  }

  cambiarTema(): void {
    this.isDarkMode = !this.isDarkMode;

    localStorage.setItem('jass-theme', this.isDarkMode ? 'dark' : 'light');

    document.body.setAttribute('data-theme', this.isDarkMode ? 'dark' : 'light');
    document.body.classList.toggle('jass-dark-theme', this.isDarkMode);
  }

  buscarSuministro(desdeQr: boolean = false): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;
    this.suministro = null;
    this.modoOperacion = null;

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
            lecturaActual: Number(data.lecturaInicial || 0),
            observacion: 'Lectura mensual registrada'
          };

          this.mantenimientoForm = {
            codigoSuministro: data.codigoSuministro,
            anio: new Date().getFullYear(),
            mes: new Date().getMonth() + 1,
            observacion: 'Recibo generado por mantenimiento. Suministro pendiente de instalación.'
          };

          if (this.puedeRegistrarLectura()) {
            this.modoOperacion = 'LECTURA';
          } else if (this.puedeGenerarMantenimiento()) {
            this.modoOperacion = 'MANTENIMIENTO';
          }

          const nombreCliente = this.nombreUsuarioSuministro(data);

          this.exito = desdeQr
            ? `QR escaneado correctamente. Cliente encontrado: ${nombreCliente}.`
            : `Suministro encontrado correctamente. Cliente: ${nombreCliente}.`;

          this.cdr.detectChanges();

          setTimeout(() => {
            document.getElementById('panel-operacion')?.scrollIntoView({
              behavior: 'smooth',
              block: 'start'
            });
          }, 250);
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'No se encontró el suministro.';
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

    if (!this.puedeRegistrarLectura()) {
      this.error = this.mensajeEstadoVisible() || 'Este suministro no permite registrar lectura.';
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

    if (this.lecturaForm.lecturaActual === null || this.lecturaForm.lecturaActual === undefined) {
      this.error = 'Ingrese la lectura actual.';
      return;
    }

    if (Number(this.lecturaForm.lecturaActual) < 0) {
      this.error = 'La lectura actual no puede ser negativa.';
      return;
    }

    if (Number(this.lecturaForm.lecturaActual) < this.lecturaAnterior()) {
      this.error = 'La lectura actual no puede ser menor a la lectura anterior.';
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
          this.irAReciboGenerado();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'No se pudo registrar la lectura.';
          this.cdr.detectChanges();
        }
      });
  }

  registrarMantenimiento(): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;

    if (!this.suministro) {
      this.error = 'Primero busque un suministro.';
      return;
    }

    if (!this.puedeGenerarMantenimiento()) {
      this.error = this.mensajeEstadoVisible() || 'Este suministro no permite generar mantenimiento.';
      return;
    }

    if (!this.mantenimientoForm.anio || this.mantenimientoForm.anio < 2024) {
      this.error = 'Ingrese un año válido.';
      return;
    }

    if (!this.mantenimientoForm.mes || this.mantenimientoForm.mes < 1 || this.mantenimientoForm.mes > 12) {
      this.error = 'Ingrese un mes válido entre 1 y 12.';
      return;
    }

    this.generandoMantenimiento = true;

    const payload: MantenimientoRequest = {
      codigoSuministro: this.suministro.codigoSuministro,
      anio: Number(this.mantenimientoForm.anio),
      mes: Number(this.mantenimientoForm.mes),
      observacion: this.mantenimientoForm.observacion?.trim()
        || 'Recibo generado por mantenimiento. Suministro pendiente de instalación.'
    };

    this.lecturadorService.registrarMantenimiento(payload)
      .pipe(
        finalize(() => {
          this.generandoMantenimiento = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturaGenerada = data;
          this.exito = 'Recibo por mantenimiento generado correctamente.';
          this.cdr.detectChanges();
          this.irAReciboGenerado();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'No se pudo generar el recibo por mantenimiento.';
          this.cdr.detectChanges();
        }
      });
  }

  marcarConsumoCero(): void {
    if (!this.suministro) {
      return;
    }

    this.lecturaForm.lecturaActual = this.lecturaAnterior();
    this.lecturaForm.observacion = 'Consumo cero registrado. Lectura igual a la anterior.';

    this.exito = 'Consumo cero preparado. Ahora puedes registrar la lectura y generar el recibo.';
    this.error = '';
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
            this.exito = 'QR detectado correctamente. Deteniendo cámara y buscando suministro...';
            this.cdr.detectChanges();

            await this.detenerEscaneo();

            setTimeout(() => {
              this.buscarSuministro(true);
            }, 250);
          },
          () => {}
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
    this.modoOperacion = null;
    this.lecturaForm = this.crearLecturaVacia();
    this.mantenimientoForm = this.crearMantenimientoVacio();
  }

  cerrarSesion(): void {
    this.detenerEscaneo();

    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  puedeRegistrarLectura(): boolean {
    return Boolean(this.suministro?.estado) && this.estadoOperativo() === 'INSTALADO';
  }

  puedeGenerarMantenimiento(): boolean {
    return Boolean(this.suministro?.estado) && this.estadoOperativo() === 'PENDIENTE';
  }

  estadoOperativo(): 'INSTALADO' | 'PENDIENTE' | 'INACTIVO' {
    if (!this.suministro) {
      return 'PENDIENTE';
    }

    if (this.suministro.estado === false) {
      return 'INACTIVO';
    }

    const estado = this.normalizarTexto(this.suministro.estadoInstalacion);

    if (estado.includes('INSTALADO') && !estado.includes('PENDIENTE')) {
      return 'INSTALADO';
    }

    return 'PENDIENTE';
  }

  esInstalado(): boolean {
    return this.estadoOperativo() === 'INSTALADO';
  }

  esPendienteInstalacion(): boolean {
    return this.estadoOperativo() === 'PENDIENTE';
  }

  estadoInstalacionTexto(estado?: string): string {
    const operativo = this.estadoOperativo();

    if (operativo === 'INSTALADO') {
      return 'Instalado';
    }

    if (operativo === 'INACTIVO') {
      return 'Inactivo';
    }

    return 'Pendiente de instalación';
  }

  estadoInstalacionClase(estado?: string): string {
    const operativo = this.estadoOperativo();

    if (operativo === 'INSTALADO') {
      return 'instalado';
    }

    if (operativo === 'INACTIVO') {
      return 'suspendido';
    }

    return 'pendiente-instalacion';
  }

  mensajeEstadoVisible(): string {
    if (!this.suministro) {
      return '';
    }

    if (this.suministro.estado === false) {
      return 'El suministro está inactivo. No se permite registrar lectura ni generar recibo. Comunicar al administrador.';
    }

    if (this.estadoOperativo() === 'PENDIENTE') {
      return 'Este suministro aún no está instalado. Puede generar recibo por mantenimiento hasta que administración lo marque como instalado.';
    }

    return 'Suministro instalado y activo. Puede registrar la lectura actual del medidor.';
  }

  lecturaAnterior(): number {
    return Number(this.suministro?.lecturaInicial || 0);
  }

  lecturaActual(): number {
    return Number(this.lecturaForm.lecturaActual || 0);
  }

  consumoEstimado(): number {
    const consumo = this.lecturaActual() - this.lecturaAnterior();
    return consumo > 0 ? consumo : 0;
  }

  estadoConsumoClase(): string {
    if (!this.suministro) {
      return 'neutral';
    }

    if (this.lecturaActual() < this.lecturaAnterior()) {
      return 'error';
    }

    if (this.consumoEstimado() === 0) {
      return 'warning';
    }

    return 'success';
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

  nombreLecturador(): string {
    return localStorage.getItem('nombreUsuario') ||
      localStorage.getItem('codigoUsuario') ||
      'Lecturador';
  }

  inicialLecturador(): string {
    return this.nombreLecturador().substring(0, 1).toUpperCase();
  }

  private irAReciboGenerado(): void {
    setTimeout(() => {
      document.getElementById('recibo-generado')?.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    }, 300);
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

  private normalizarTexto(value: any): string {
    return String(value ?? '')
      .trim()
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/_/g, ' ')
      .replace(/-/g, ' ');
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

  private crearMantenimientoVacio(): MantenimientoRequest {
    return {
      codigoSuministro: '',
      anio: new Date().getFullYear(),
      mes: new Date().getMonth() + 1,
      observacion: 'Recibo generado por mantenimiento. Suministro pendiente de instalación.'
    };
  }
}