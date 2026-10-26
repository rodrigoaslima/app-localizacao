import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Modelo grava UTC e recupera os valores tipados', () {
    final localizacao = Localizacao(
      latitude: 1.5,
      longitude: 2.5,
      precisao: 3.5,
      instante: DateTime.parse('2026-10-22T10:00:00-03:00'),
    );
    final mapa = localizacao.toMap();
    expect(mapa['instante'], '2026-10-22T13:00:00.000Z');
    expect(mapa.containsKey('id'), false);
    final recuperada = Localizacao.fromMap({...mapa, 'id': 7});
    expect(recuperada.id, 7);
    expect(recuperada.instante.isUtc, true);
    expect(recuperada.latitude, 1.5);
    expect(recuperada.longitude, 2.5);
    expect(recuperada.precisao, 3.5);
  });

  test(
    'SQLite mantém 105 posições, consulta 100 em ordem e limpa todas',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final pasta = await Directory.systemTemp.createTemp(
        'atividade_localizacoes_',
      );
      await databaseFactory.setDatabasesPath(pasta.path);
      final repositorio = RepositorioLocalizacoes();
      try {
        // Aberturas concorrentes devem compartilhar a conexão.
        await Future.wait([repositorio.preparar(), repositorio.preparar()]);
        for (var i = 0; i < 105; i++) {
          await repositorio.inserir(
            Localizacao(
              latitude: 0,
              longitude: 0,
              precisao: 1,
              instante: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
            ),
          );
        }
        final registros = await repositorio.consultar();
        expect(registros.length, 100);
        expect(registros.first.id, 105);
        expect(registros.last.id, 6);
        // Reabre o arquivo por outra conexão: verifica persistência em disco.
        final db = await databaseFactory.openDatabase(
          '${pasta.path}/localizacoes.db',
          options: OpenDatabaseOptions(singleInstance: false),
        );
        expect(
          (await db.rawQuery('SELECT COUNT(*) AS total FROM localizacoes'))
              .single['total'],
          105,
        );
        await repositorio.limpar();
        expect(await repositorio.consultar(), isEmpty);
        expect(
          (await db.rawQuery('SELECT COUNT(*) AS total FROM localizacoes'))
              .single['total'],
          0,
        );
        expect(
          await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE name = 'localizacoes'",
          ),
          hasLength(1),
        );
        await db.close();
      } finally {
        await databaseFactory.deleteDatabase('${pasta.path}/localizacoes.db');
        await pasta.delete(recursive: true);
      }
    },
  );
}
