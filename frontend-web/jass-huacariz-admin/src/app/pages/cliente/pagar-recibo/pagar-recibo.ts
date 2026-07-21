import { CommonModule, Location } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  PagoRequest,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

import {
  CanalPago,
  CanalPagoResponse
} from '../../../core/services/canal-pago';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

interface MetodoPagoCliente {
  codigo: string;
  nombre: string;
  descripcion: string;
  icono: string;
}

@Component({
  selector: 'app-pagar-recibo',
  imports: [
    CommonModule,
    FormsModule,
    RouterModule
  ],
  templateUrl: './pagar-recibo.html',
  styleUrl: './pagar-recibo.scss',
})
export class PagarRecibo implements OnInit {

  idRecibo = 0;

  recibo: ReciboClienteResponse | null = null;
  recibos: ReciboClienteResponse[] = [];
  canalesPago: CanalPagoResponse[] = [];

  canalSeleccionadoId: number | null = null;

  comprobanteArchivo: File | null = null;
  comprobantePreview = '';

  ayudaOperacionAbierta = false;
  modalAyudaAbierto = false;

  cargando = false;
  cargandoCanales = false;
  procesando = false;

  error = '';
  errorCanales = '';
  exito = '';

  metodosPago: MetodoPagoCliente[] = [
    {
      codigo: 'YAPE',
      nombre: 'Yape',
      descripcion:
        'Paga desde tu aplicaciÃ³n Yape y registra el nÃºmero de operaciÃ³n.',
      icono: 'Y'
    },
    {
      codigo: 'PLIN',
      nombre: 'Plin',
      descripcion:
        'Paga desde tu aplicaciÃ³n bancaria con Plin.',
      icono: 'P'
    },
    {
      codigo: 'TRANSFERENCIA',
      nombre: 'Transferencia bancaria',
      descripcion:
        'Realiza una transferencia y registra el cÃ³digo de operaciÃ³n.',
      icono: 'T'
    }
  ];

  pago: PagoRequest = {
    metodoPago: 'YAPE',
    codigoOperacion: ''
  };

  constructor(
    private route: ActivatedRoute,
    private location: Location,
    private clientePortal: ClientePortal,
    private canalPagoService: CanalPago,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarCanalesPago();

    this.route.paramMap.subscribe((params) => {
      this.idRecibo = Number(params.get('id') || 0);
      this.cargarRecibo();
    });
  }

  cargarRecibo(): void {
    if (!this.idRecibo) {
      this.error = 'No se recibiÃ³ el ID del recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.obtenerReciboPorId(this.idRecibo)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.recibo = data;
          this.cargarHistorialParaImpresion();
          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error('Error cargando recibo:', err);

          this.error =
            err?.error?.mensaje ||
            err?.error?.error ||
            'No se pudo cargar el recibo seleccionado.';

          this.recibo = null;
          this.cdr.detectChanges();
        }
      });
  }

  cargarHistorialParaImpresion(): void {
    this.clientePortal.listarMisRecibos().subscribe({
      next: (data) => {
        this.recibos = data || [];
        this.cdr.detectChanges();
      },
      error: () => {
        this.recibos = [];
        this.cdr.detectChanges();
      }
    });
  }

  cargarCanalesPago(): void {
    this.cargandoCanales = true;
    this.errorCanales = '';

    this.canalPagoService.listarActivos()
      .pipe(
        finalize(() => {
          this.cargandoCanales = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.canalesPago = Array.isArray(data)
            ? data
            : [];

          const canalesIniciales =
            this.canalesDelMetodoSeleccionado();

          this.canalSeleccionadoId =
            canalesIniciales.length > 0
              ? canalesIniciales[0].id
              : null;

          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error(
            'Error cargando canales de pago:',
            err
          );

          this.canalesPago = [];

          this.errorCanales =
            err?.error?.mensaje ||
            err?.error?.error ||
            'No se pudieron cargar los canales de pago autorizados.';

          this.cdr.detectChanges();
        }
      });
  }

  seleccionarMetodo(codigo: string): void {
    this.pago.metodoPago =
      this.normalizarCodigoMetodo(codigo);

    const canales =
      this.canalesDelMetodoSeleccionado();

    this.canalSeleccionadoId =
      canales.length > 0
        ? canales[0].id
        : null;

    this.pago.codigoOperacion = '';
    this.ayudaOperacionAbierta = false;
    this.modalAyudaAbierto = false;

    this.error = '';
    this.exito = '';
  }

  metodoSeleccionado(): MetodoPagoCliente | null {
    const codigoSeleccionado =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    return this.metodosPago.find((item) => {
      return this.normalizarCodigoMetodo(item.codigo) ===
        codigoSeleccionado;
    }) || null;
  }

  canalesDelMetodoSeleccionado(): CanalPagoResponse[] {
    const metodoSeleccionado =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    return this.canalesPago.filter((canal) => {
      const metodoCanal =
        this.normalizarCodigoMetodo(
          canal.metodoPago
        );

      return metodoCanal === metodoSeleccionado;
    });
  }

  normalizarCodigoMetodo(metodo?: string): string {
    const valor = String(metodo || '')
      .trim()
      .toUpperCase();

    if (valor.includes('YAPE')) {
      return 'YAPE';
    }

    if (valor.includes('PLIN')) {
      return 'PLIN';
    }

    if (
      valor.includes('TRANSFERENCIA') ||
      valor.includes('BANCO') ||
      valor.includes('BANCARIA')
    ) {
      return 'TRANSFERENCIA';
    }

    return valor;
  }
    seleccionarCanal(canal: CanalPagoResponse): void {
    this.canalSeleccionadoId = canal.id;

    this.pago.codigoOperacion = '';
    this.ayudaOperacionAbierta = false;
    this.modalAyudaAbierto = false;

    this.error = '';
    this.exito = '';
  }

  canalPagoElegido(): CanalPagoResponse | null {
    const canales =
      this.canalesDelMetodoSeleccionado();

    if (!canales.length) {
      return null;
    }

    const seleccionado = canales.find(
      (canal) =>
        Number(canal.id) ===
        Number(this.canalSeleccionadoId)
    );

    return seleccionado || canales[0];
  }

  nombreCanal(canal: CanalPagoResponse): string {
    const metodo =
      this.normalizarCodigoMetodo(
        canal.metodoPago
      );

    if (metodo === 'YAPE') {
      return canal.numero
        ? `Yape Â· ${canal.numero}`
        : 'Yape';
    }

    if (metodo === 'PLIN') {
      return canal.numero
        ? `Plin Â· ${canal.numero}`
        : 'Plin';
    }

    if (metodo === 'TRANSFERENCIA') {
      return canal.banco
        ? `Transferencia Â· ${canal.banco}`
        : 'Transferencia bancaria';
    }

    return canal.metodoPago || 'Canal de pago';
  }

  esMetodo(
    canal: CanalPagoResponse,
    metodo: string
  ): boolean {
    return this.normalizarCodigoMetodo(
      canal.metodoPago
    ) === this.normalizarCodigoMetodo(metodo);
  }

  esBilleteraCanal(
    canal: CanalPagoResponse
  ): boolean {
    const metodo =
      this.normalizarCodigoMetodo(
        canal.metodoPago
      );

    return metodo === 'YAPE' ||
      metodo === 'PLIN';
  }

  esTransferenciaCanal(
    canal: CanalPagoResponse
  ): boolean {
    return this.normalizarCodigoMetodo(
      canal.metodoPago
    ) === 'TRANSFERENCIA';
  }

  tieneQr(canal: CanalPagoResponse): boolean {
    return Boolean(
      canal.qrUrl &&
      String(canal.qrUrl).trim()
    );
  }

  urlQrCanal(qrUrl?: string): string {
    const valor =
      String(qrUrl || '').trim();

    if (!valor) {
      return '';
    }

    if (
      valor.startsWith('http://') ||
      valor.startsWith('https://') ||
      valor.startsWith('blob:')
    ) {
      return valor;
    }

    const ruta = valor.startsWith('/')
      ? valor
      : `/${valor}`;

    return `${ruta}`;
  }

  logoBanco(banco?: string): string {
    const nombre = String(banco || '')
      .trim()
      .toUpperCase();

    if (nombre.includes('INTERBANK')) {
      return 'assets/img/bancos/interbank.jpg';
    }

    if (nombre.includes('BCP')) {
      return 'assets/img/bancos/bcp.jpg';
    }

    if (nombre.includes('BBVA')) {
      return 'assets/img/bancos/bbva.jpg';
    }

    if (nombre.includes('SCOTIA')) {
      return 'assets/img/bancos/scotiabank.jpg';
    }

    if (nombre.includes('NACION')) {
      return 'assets/img/bancos/banco-nacion.jpg';
    }

    if (nombre.includes('CAJA PIURA')) {
      return 'assets/img/bancos/caja-piura.jpg';
    }

    if (nombre.includes('CAJA TRUJILLO')) {
      return 'assets/img/bancos/caja-trujillo.jpg';
    }

    return 'assets/img/bancos/banco.jpg';
  }

  copiarDato(valor?: string): void {
    const texto =
      String(valor || '').trim();

    if (!texto) {
      return;
    }

    if (!navigator.clipboard) {
      this.copiarDatoAlternativo(texto);
      return;
    }

    navigator.clipboard.writeText(texto)
      .then(() => {
        this.mostrarExitoTemporal(
          'Dato copiado correctamente.'
        );
      })
      .catch(() => {
        this.copiarDatoAlternativo(texto);
      });
  }

  private copiarDatoAlternativo(
    texto: string
  ): void {
    const textarea =
      document.createElement('textarea');

    textarea.value = texto;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';

    document.body.appendChild(textarea);
    textarea.select();

    try {
      document.execCommand('copy');

      this.mostrarExitoTemporal(
        'Dato copiado correctamente.'
      );
    } catch {
      this.error =
        'No se pudo copiar el dato.';
    } finally {
      document.body.removeChild(textarea);
      this.cdr.detectChanges();
    }
  }

  private mostrarExitoTemporal(
    mensaje: string
  ): void {
    this.exito = mensaje;
    this.error = '';
    this.cdr.detectChanges();

    setTimeout(() => {
      if (this.exito === mensaje) {
        this.exito = '';
        this.cdr.detectChanges();
      }
    }, 1800);
  }

  imagenInstruccionOperacion(): string {
    return 'assets/img/instrucciones-pago/instrucciones.png';
  }

  tituloAyudaOperacion(): string {
    const metodo =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    if (metodo === 'YAPE') {
      return 'Ubica el N.Â° de operaciÃ³n en Yape';
    }

    if (metodo === 'PLIN') {
      return 'Ubica el nÃºmero de operaciÃ³n en Plin';
    }

    if (metodo === 'TRANSFERENCIA') {
      const banco =
        this.canalPagoElegido()?.banco;

      return banco
        ? `Ubica el nÃºmero de operaciÃ³n en ${banco}`
        : 'Ubica el nÃºmero de operaciÃ³n bancaria';
    }

    return 'Ubica el cÃ³digo de operaciÃ³n';
  }

  descripcionAyudaOperacion(): string {
    const metodo =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    if (metodo === 'YAPE') {
      return 'Abre el detalle del pago y copia Ãºnicamente el dato que aparece junto a â€œNro. de operaciÃ³nâ€.';
    }

    if (metodo === 'PLIN') {
      return 'Abre el comprobante y copia el nÃºmero de operaciÃ³n o transacciÃ³n mostrado.';
    }

    if (metodo === 'TRANSFERENCIA') {
      return 'Abre la constancia del banco y copia el dato que aparece como nÃºmero de operaciÃ³n, transacciÃ³n o constancia.';
    }

    return 'Copia exactamente el cÃ³digo que aparece en tu comprobante.';
  }
    tituloCodigoOperacion(): string {
    const metodo =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    if (metodo === 'YAPE') {
      return 'N.Â° de operaciÃ³n de Yape';
    }

    if (metodo === 'PLIN') {
      return 'N.Â° de operaciÃ³n de Plin';
    }

    if (metodo === 'TRANSFERENCIA') {
      return 'NÃºmero de operaciÃ³n bancaria';
    }

    return 'CÃ³digo / nÃºmero de operaciÃ³n';
  }

  placeholderCodigoOperacion(): string {
    const metodo =
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      );

    if (metodo === 'YAPE') {
      return 'Ejemplo: 00343862';
    }

    if (metodo === 'PLIN') {
      return 'Ejemplo: 987654321';
    }

    if (metodo === 'TRANSFERENCIA') {
      return 'Ejemplo: 4309301 u OP-123456';
    }

    return 'Ingrese el cÃ³digo de operaciÃ³n';
  }

  alternarAyudaOperacion(): void {
    this.ayudaOperacionAbierta =
      !this.ayudaOperacionAbierta;
  }

  abrirModalAyuda(): void {
    this.modalAyudaAbierto = true;
  }

  cerrarModalAyuda(): void {
    this.modalAyudaAbierto = false;
  }

  seleccionarComprobante(event: Event): void {
    const input =
      event.target as HTMLInputElement;

    const archivo =
      input.files?.[0];

    if (!archivo) {
      return;
    }

    const formatosPermitidos = [
      'image/jpeg',
      'image/png',
      'image/webp'
    ];

    if (
      !formatosPermitidos.includes(
        archivo.type
      )
    ) {
      this.error =
        'Solo se permiten imÃ¡genes JPG, PNG o WEBP.';

      this.comprobanteArchivo = null;
      this.limpiarPreviewComprobante();
      input.value = '';

      return;
    }

    if (
      archivo.size >
      3 * 1024 * 1024
    ) {
      this.error =
        'La imagen no debe superar los 3 MB.';

      this.comprobanteArchivo = null;
      this.limpiarPreviewComprobante();
      input.value = '';

      return;
    }

    this.limpiarPreviewComprobante();

    this.comprobanteArchivo = archivo;
    this.comprobantePreview =
      URL.createObjectURL(archivo);

    this.error = '';
    this.exito = '';
  }

  confirmarPago(): void {
    if (!this.recibo) {
      this.error =
        'No hay recibo seleccionado.';
      return;
    }

    if (!this.puedePagar()) {
      this.error =
        'Este recibo ya se encuentra pagado o estÃ¡ en revisiÃ³n.';
      return;
    }

    if (
      !this.pago.metodoPago?.trim()
    ) {
      this.error =
        'Seleccione un mÃ©todo de pago.';
      return;
    }

    if (
      this.canalesDelMetodoSeleccionado()
        .length === 0
    ) {
      this.error =
        'No existe un canal activo para el mÃ©todo seleccionado.';
      return;
    }

    if (!this.canalPagoElegido()) {
      this.error =
        'Seleccione el canal donde realizarÃ¡ el pago.';
      return;
    }

    const codigoOperacion =
      String(
        this.pago.codigoOperacion || ''
      ).trim();

    if (!codigoOperacion) {
      this.error =
        'Ingrese el cÃ³digo o nÃºmero de operaciÃ³n.';
      return;
    }

    if (codigoOperacion.length < 4) {
      this.error =
        'El cÃ³digo de operaciÃ³n debe tener al menos 4 caracteres.';
      return;
    }

    if (!this.comprobanteArchivo) {
      this.error =
        'Debe subir una captura del comprobante.';
      return;
    }

    this.procesando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.pagarMiRecibo(
      this.recibo.id,
      this.normalizarCodigoMetodo(
        this.pago.metodoPago
      ),
      codigoOperacion,
      this.comprobanteArchivo
    )
      .pipe(
        finalize(() => {
          this.procesando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito =
            'Tu pago fue enviado para revisiÃ³n. Agua Potable Huacariz confirmarÃ¡ el pago cuando valide la operaciÃ³n.';

          this.pago.codigoOperacion = '';
          this.comprobanteArchivo = null;

          this.limpiarPreviewComprobante();
          this.cerrarModalAyuda();

          this.ayudaOperacionAbierta = false;

          this.cargarRecibo();
          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error(
            'Error enviando pago:',
            err
          );

          this.error =
            err?.error?.error ||
            err?.error?.mensaje ||
            err?.error?.message ||
            'No se pudo enviar el pago. Verifica el cÃ³digo de operaciÃ³n y la captura.';

          this.cdr.detectChanges();
        }
      });
  }

  limpiarPreviewComprobante(): void {
    if (this.comprobantePreview) {
      URL.revokeObjectURL(
        this.comprobantePreview
      );
    }

    this.comprobantePreview = '';
  }

  volver(): void {
    this.location.back();
  }

  imprimirRecibo(): void {
    if (!this.recibo) {
      return;
    }

    imprimirReciboJass(
      this.recibo,
      this.recibos
    );
  }

  puedePagar(): boolean {
    if (!this.recibo) {
      return false;
    }

    const estado = String(
      this.recibo.estadoRecibo || ''
    )
      .trim()
      .toUpperCase();

    return estado !== 'PAGADO' &&
      estado !== 'PAGO_EN_REVISION';
  }
    totalCargos(): number {
    if (!this.recibo) {
      return 0;
    }

    return Number(
      this.recibo.cargoMantenimiento || 0
    ) +
      Number(
        this.recibo.cargoLector || 0
      ) +
      Number(
        this.recibo.cargoOtros || 0
      ) +
      Number(
        this.recibo.mora || 0
      );
  }

  estadoClase(estado?: string): string {
    const valor = String(estado || '')
      .trim()
      .toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    if (valor === 'pago_en_revision') {
      return 'revision';
    }

    return 'pendiente';
  }

  periodo(
    recibo?: ReciboClienteResponse | null
  ): string {
    if (!recibo) {
      return '-';
    }

    return `${this.nombreMes(
      Number(recibo.mes)
    )} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    return meses[mes - 1] ||
      'Mes invÃ¡lido';
  }

  fechaCorta(fecha?: string): string {
    if (!fecha) {
      return '-';
    }

    return String(fecha)
      .split('T')[0] || fecha;
  }
}
