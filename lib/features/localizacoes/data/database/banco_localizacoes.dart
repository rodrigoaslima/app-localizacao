import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  // Compartilhamos a conexão entre coleta, histórico e mapa.
  static Database? _banco;
  static Future<Database>? _abertura;

  Future<Database> abrir() async {
    if (_banco != null) return _banco!;
    // Chamadas simultâneas aguardam a mesma abertura.
    _abertura ??= _abrirBanco();
    try {
      _banco = await _abertura!;
      return _banco!;
    } finally {
      // Se falhar, a próxima chamada poderá tentar novamente.
      _abertura = null;
    }
  }

  Future<Database> _abrirBanco() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      p.join(pasta, 'localizacoes.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE localizacoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
