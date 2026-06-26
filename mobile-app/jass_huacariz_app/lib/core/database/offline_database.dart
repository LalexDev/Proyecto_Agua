import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();

  static const String _databaseName =
      'jass_huacariz_offline.db';

  static const int _databaseVersion = 1;

  static const String tablaSuministros =
      'suministros_cache';

  static const String tablaLecturas =
      'lecturas_pendientes';

  Database? _database;

  Future<Database> get database async {
    final actual = _database;

    if (actual != null && actual.isOpen) {
      return actual;
    }

    _database = await _abrirBaseDatos();

    return _database!;
  }

  Future<Database> _abrirBaseDatos() async {
    final databasesPath = await getDatabasesPath();

    final path = join(
      databasesPath,
      _databaseName,
    );

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _crearTablas,
      onUpgrade: _actualizarBaseDatos,
    );
  }

  Future<void> _crearTablas(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE $tablaSuministros (
        codigo_suministro TEXT PRIMARY KEY,
        id_servidor INTEGER,
        nombre_cliente TEXT,
        dni_cliente TEXT,
        nombre_sector TEXT,
        direccion_suministro TEXT,
        referencia TEXT,
        alias_suministro TEXT,

        lectura_inicial REAL NOT NULL DEFAULT 0,
        lectura_anterior REAL NOT NULL DEFAULT 0,
        anio_ultima_lectura INTEGER,
        mes_ultima_lectura INTEGER,

        estado INTEGER NOT NULL DEFAULT 1,
        estado_instalacion TEXT,
        permite_registrar_lectura INTEGER NOT NULL DEFAULT 0,
        permite_generar_mantenimiento INTEGER NOT NULL DEFAULT 0,
        mensaje_estado TEXT,

        fecha_actualizacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablaLecturas (
        id_local TEXT PRIMARY KEY,
        codigo_suministro TEXT NOT NULL,

        lectura_anterior REAL NOT NULL,
        lectura_actual REAL NOT NULL,
        consumo REAL NOT NULL,

        anio INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        observacion TEXT,

        fecha_registro_local TEXT NOT NULL,
        fecha_sincronizacion TEXT,

        estado_sincronizacion TEXT NOT NULL
          DEFAULT 'PENDIENTE',

        intentos INTEGER NOT NULL DEFAULT 0,
        mensaje_error TEXT,
        respuesta_servidor TEXT,
        lector_id TEXT,

        FOREIGN KEY (codigo_suministro)
          REFERENCES $tablaSuministros(codigo_suministro)
          ON UPDATE CASCADE
          ON DELETE RESTRICT,

        UNIQUE (codigo_suministro, anio, mes)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_lecturas_estado
      ON $tablaLecturas(estado_sincronizacion)
    ''');

    await db.execute('''
      CREATE INDEX idx_lecturas_codigo
      ON $tablaLecturas(codigo_suministro)
    ''');

    await db.execute('''
      CREATE INDEX idx_lecturas_periodo
      ON $tablaLecturas(anio, mes)
    ''');
  }

  Future<void> _actualizarBaseDatos(
    Database db,
    int versionAnterior,
    int versionNueva,
  ) async {
    // Las próximas modificaciones de tablas
    // se agregarán aquí aumentando _databaseVersion.
  }

  // =========================================================
  // CONVERSIONES
  // =========================================================

  String _texto(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  double _numero(
    dynamic value, [
    double fallback = 0,
  ]) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  int? _enteroNullable(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  bool _booleano(
    dynamic value, [
    bool fallback = false,
  ]) {
    if (value is bool) return value;

    if (value == null) return fallback;

    final text = value
        .toString()
        .trim()
        .toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'activo' ||
        text == 'activa' ||
        text == 'instalado';
  }

  int _boolToInt(bool value) {
    return value ? 1 : 0;
  }

  bool intToBool(dynamic value) {
    return value == 1 ||
        value == true ||
        value?.toString() == '1';
  }

  String normalizarCodigo(dynamic value) {
    return _texto(value).toUpperCase();
  }

  Map<String, dynamic> _suministroServidorALocal(
    Map<String, dynamic> suministro,
  ) {
    final codigo = normalizarCodigo(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
    );

    return {
      'codigo_suministro': codigo,
      'id_servidor': _enteroNullable(
        suministro['id'] ??
            suministro['idSuministro'],
      ),
      'nombre_cliente': _texto(
        suministro['nombreCliente'] ??
            suministro['titular'] ??
            suministro['cliente'],
        'No disponible',
      ),
      'dni_cliente': _texto(
        suministro['dniCliente'] ??
            suministro['dni'],
        '-',
      ),
      'nombre_sector': _texto(
        suministro['nombreSector'] ??
            suministro['sector'] ??
            suministro['sectorNombre'],
        '-',
      ),
      'direccion_suministro': _texto(
        suministro['direccionSuministro'] ??
            suministro['direccion'],
        '-',
      ),
      'referencia': _texto(
        suministro['referencia'],
        '-',
      ),
      'alias_suministro': _texto(
        suministro['aliasSuministro'] ??
            suministro['alias'],
        '-',
      ),
      'lectura_inicial': _numero(
        suministro['lecturaInicial'],
      ),
      'lectura_anterior': _numero(
        suministro['lecturaAnterior'] ??
            suministro['ultimaLectura'] ??
            suministro['lecturaActual'] ??
            suministro['lecturaInicial'],
      ),
      'anio_ultima_lectura': _enteroNullable(
        suministro['anioUltimaLectura'] ??
            suministro['anio'],
      ),
      'mes_ultima_lectura': _enteroNullable(
        suministro['mesUltimaLectura'] ??
            suministro['mes'],
      ),
      'estado': _boolToInt(
        _booleano(
          suministro['estado'] ??
              suministro['activo'],
          true,
        ),
      ),
      'estado_instalacion': _texto(
        suministro['estadoInstalacion'],
        'PENDIENTE_INSTALACION',
      ).toUpperCase(),
      'permite_registrar_lectura': _boolToInt(
        _booleano(
          suministro['permiteRegistrarLectura'],
        ),
      ),
      'permite_generar_mantenimiento': _boolToInt(
        _booleano(
          suministro[
              'permiteGenerarMantenimiento'],
        ),
      ),
      'mensaje_estado': _texto(
        suministro['mensajeEstado'],
      ),
      'fecha_actualizacion':
          DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> suministroLocalAFlutter(
    Map<String, dynamic> local,
  ) {
    return {
      'id': local['id_servidor'],
      'codigoSuministro':
          local['codigo_suministro'],
      'nombreCliente':
          local['nombre_cliente'],
      'dniCliente': local['dni_cliente'],
      'nombreSector': local['nombre_sector'],
      'direccionSuministro':
          local['direccion_suministro'],
      'referencia': local['referencia'],
      'aliasSuministro':
          local['alias_suministro'],
      'lecturaInicial':
          _numero(local['lectura_inicial']),
      'lecturaAnterior':
          _numero(local['lectura_anterior']),
      'anioUltimaLectura':
          local['anio_ultima_lectura'],
      'mesUltimaLectura':
          local['mes_ultima_lectura'],
      'estado': intToBool(local['estado']),
      'estadoInstalacion':
          local['estado_instalacion'],
      'permiteRegistrarLectura': intToBool(
        local['permite_registrar_lectura'],
      ),
      'permiteGenerarMantenimiento': intToBool(
        local[
            'permite_generar_mantenimiento'],
      ),
      'mensajeEstado':
          local['mensaje_estado'],
      'fechaActualizacionLocal':
          local['fecha_actualizacion'],
      'origenOffline': true,
    };
  }

  // =========================================================
  // CACHÉ DE SUMINISTROS
  // =========================================================

  Future<void> _upsertSuministro(
    DatabaseExecutor executor,
    Map<String, dynamic> data,
  ) async {
    final codigo =
        data['codigo_suministro'].toString();

    final actualizados = await executor.update(
      tablaSuministros,
      data,
      where: 'codigo_suministro = ?',
      whereArgs: [codigo],
    );

    if (actualizados == 0) {
      await executor.insert(
        tablaSuministros,
        data,
        conflictAlgorithm:
            ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> guardarSuministro(
    Map<String, dynamic> suministro,
  ) async {
    final db = await database;

    final data =
        _suministroServidorALocal(suministro);

    final codigo =
        data['codigo_suministro'].toString();

    if (codigo.isEmpty) {
      throw Exception(
        'El suministro no tiene código.',
      );
    }

    await _upsertSuministro(
      db,
      data,
    );
  }

  Future<int> reemplazarSuministros(
    List<Map<String, dynamic>> suministros,
  ) async {
    final db = await database;

    return db.transaction<int>((transaction) async {
      int guardados = 0;

      for (final suministro in suministros) {
        final data =
            _suministroServidorALocal(suministro);

        final codigo =
            data['codigo_suministro'].toString();

        if (codigo.isEmpty) continue;

        await _upsertSuministro(
          transaction,
          data,
        );

        guardados++;
      }

      return guardados;
    });
  }

  Future<Map<String, dynamic>?>
      buscarSuministroPorCodigo(
    String codigo,
  ) async {
    final db = await database;

    final codigoNormalizado =
        normalizarCodigo(codigo);

    final resultados = await db.query(
      tablaSuministros,
      where: 'codigo_suministro = ?',
      whereArgs: [codigoNormalizado],
      limit: 1,
    );

    if (resultados.isEmpty) {
      return null;
    }

    return suministroLocalAFlutter(
      resultados.first,
    );
  }

  Future<List<Map<String, dynamic>>>
      listarSuministros() async {
    final db = await database;

    final resultados = await db.query(
      tablaSuministros,
      orderBy: 'codigo_suministro ASC',
    );

    return resultados
        .map(suministroLocalAFlutter)
        .toList();
  }

  Future<int> contarSuministros() async {
    final db = await database;

    final resultado = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $tablaSuministros
      ''',
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> actualizarLecturaAnterior({
    required String codigoSuministro,
    required double lecturaAnterior,
    required int anio,
    required int mes,
  }) async {
    final db = await database;

    await db.update(
      tablaSuministros,
      {
        'lectura_anterior': lecturaAnterior,
        'anio_ultima_lectura': anio,
        'mes_ultima_lectura': mes,
        'fecha_actualizacion':
            DateTime.now().toIso8601String(),
      },
      where: 'codigo_suministro = ?',
      whereArgs: [
        normalizarCodigo(codigoSuministro),
      ],
    );
  }

  // =========================================================
  // LECTURAS LOCALES
  // =========================================================

  Future<void> insertarLecturaPendiente(
    Map<String, dynamic> lectura,
  ) async {
    final db = await database;

    final codigo = normalizarCodigo(
      lectura['codigoSuministro'] ??
          lectura['codigo_suministro'],
    );

    if (codigo.isEmpty) {
      throw Exception(
        'No se encontró el código del suministro.',
      );
    }

    final idLocal = _texto(
      lectura['idLocal'] ??
          lectura['id_local'],
    );

    if (idLocal.isEmpty) {
      throw Exception(
        'La lectura no tiene identificador local.',
      );
    }

    final anio = _enteroNullable(
      lectura['anio'],
    );

    final mes = _enteroNullable(
      lectura['mes'],
    );

    if (anio == null || mes == null) {
      throw Exception(
        'La lectura no tiene un periodo válido.',
      );
    }

    final lecturaAnterior = _numero(
      lectura['lecturaAnterior'] ??
          lectura['lectura_anterior'],
    );

    final lecturaActual = _numero(
      lectura['lecturaActual'] ??
          lectura['lectura_actual'],
    );

    final consumo = lecturaActual -
        lecturaAnterior;

    await db.transaction<void>((transaction) async {
      final suministroExiste = await transaction.query(
        tablaSuministros,
        columns: ['codigo_suministro'],
        where: 'codigo_suministro = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (suministroExiste.isEmpty) {
        throw Exception(
          'El suministro $codigo no está guardado '
          'en el catálogo local.',
        );
      }

      await transaction.insert(
        tablaLecturas,
        {
          'id_local': idLocal,
          'codigo_suministro': codigo,
          'lectura_anterior': lecturaAnterior,
          'lectura_actual': lecturaActual,
          'consumo':
              consumo < 0 ? 0 : consumo,
          'anio': anio,
          'mes': mes,
          'observacion': _texto(
            lectura['observacion'],
          ),
          'fecha_registro_local': _texto(
            lectura['fechaRegistroLocal'] ??
                lectura['fecha_registro_local'],
            DateTime.now().toIso8601String(),
          ),
          'fecha_sincronizacion': null,
          'estado_sincronizacion':
              'PENDIENTE',
          'intentos': 0,
          'mensaje_error': null,
          'respuesta_servidor': null,
          'lector_id': _texto(
            lectura['lectorId'] ??
                lectura['lector_id'],
          ),
        },
        conflictAlgorithm:
            ConflictAlgorithm.abort,
      );

      await transaction.update(
        tablaSuministros,
        {
          'lectura_anterior': lecturaActual,
          'anio_ultima_lectura': anio,
          'mes_ultima_lectura': mes,
          'fecha_actualizacion':
              DateTime.now().toIso8601String(),
        },
        where: 'codigo_suministro = ?',
        whereArgs: [codigo],
      );
    });
  }

  Future<Map<String, dynamic>?>
      buscarLecturaPorPeriodo({
    required String codigoSuministro,
    required int anio,
    required int mes,
  }) async {
    final db = await database;

    final resultados = await db.query(
      tablaLecturas,
      where: '''
        codigo_suministro = ?
        AND anio = ?
        AND mes = ?
      ''',
      whereArgs: [
        normalizarCodigo(codigoSuministro),
        anio,
        mes,
      ],
      limit: 1,
    );

    if (resultados.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(
      resultados.first,
    );
  }

  Future<List<Map<String, dynamic>>>
      listarLecturasLocales() async {
    final db = await database;

    final resultados = await db.query(
      tablaLecturas,
      orderBy: '''
        anio DESC,
        mes DESC,
        fecha_registro_local DESC
      ''',
    );

    return resultados
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      listarPendientesSincronizacion() async {
    final db = await database;

    final resultados = await db.query(
      tablaLecturas,
      where: '''
        estado_sincronizacion IN (?, ?)
      ''',
      whereArgs: [
        'PENDIENTE',
        'ERROR',
      ],
      orderBy: 'fecha_registro_local ASC',
    );

    return resultados
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  Future<int> contarPendientes() async {
    final db = await database;

    final resultado = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $tablaLecturas
      WHERE estado_sincronizacion
      IN ('PENDIENTE', 'ERROR', 'SINCRONIZANDO')
      ''',
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> marcarSincronizando(
    String idLocal,
  ) async {
    final db = await database;

    await db.rawUpdate(
      '''
      UPDATE $tablaLecturas
      SET
        estado_sincronizacion = ?,
        intentos = intentos + 1,
        mensaje_error = NULL
      WHERE id_local = ?
      ''',
      [
        'SINCRONIZANDO',
        idLocal,
      ],
    );
  }

  Future<void> marcarSincronizada({
    required String idLocal,
    required dynamic respuestaServidor,
  }) async {
    final db = await database;

    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion':
            'SINCRONIZADA',
        'fecha_sincronizacion':
            DateTime.now().toIso8601String(),
        'mensaje_error': null,
        'respuesta_servidor':
            jsonEncode(respuestaServidor),
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> marcarError({
    required String idLocal,
    required String mensaje,
  }) async {
    final db = await database;

    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion': 'ERROR',
        'mensaje_error': mensaje,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void>
      restaurarLecturasInterrumpidas() async {
    final db = await database;

    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion':
            'PENDIENTE',
        'mensaje_error':
            'Sincronización interrumpida. Se volverá a intentar.',
      },
      where: 'estado_sincronizacion = ?',
      whereArgs: ['SINCRONIZANDO'],
    );
  }

  Future<void> eliminarLecturaLocal(
    String idLocal,
  ) async {
    final db = await database;

    await db.delete(
      tablaLecturas,
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  // =========================================================
  // MANTENIMIENTO
  // =========================================================

  Future<void> eliminarCacheSuministros() async {
    final db = await database;

    // Conserva los suministros que todavía tienen
    // lecturas locales relacionadas.
    await db.rawDelete(
      '''
      DELETE FROM $tablaSuministros
      WHERE codigo_suministro NOT IN (
        SELECT DISTINCT codigo_suministro
        FROM $tablaLecturas
      )
      ''',
    );
  }

  Future<void> eliminarLecturasSincronizadas() async {
    final db = await database;

    await db.delete(
      tablaLecturas,
      where: 'estado_sincronizacion = ?',
      whereArgs: ['SINCRONIZADA'],
    );
  }

  Future<void> cerrar() async {
    final db = _database;

    if (db != null && db.isOpen) {
      await db.close();
    }

    _database = null;
  }
  
}