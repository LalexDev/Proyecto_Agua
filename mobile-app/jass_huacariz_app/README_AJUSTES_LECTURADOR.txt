Ajuste final del módulo Lecturador móvil:
- Aviso de suministro operativo / pendiente de instalación / suspendido.
- Aviso de consumo cero.
- Aviso de consumo inusual.
- Aviso visual de cambio de medidor activado.
- Botón cambia a "Marcar consumo cero" cuando lectura actual = lectura anterior.
- Observación por defecto: "Lectura mensual registrada".

Reemplaza el archivo incluido respetando la ruta lib/features/lector/registrar_lectura_page.dart.
Luego ejecutar:

dart format lib
flutter clean
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://179.197.230.247/api
