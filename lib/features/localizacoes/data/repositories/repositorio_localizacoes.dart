import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  final BancoLocalizacoes _banco = BancoLocalizacoes();

  Future<void> preparar() async {
    await _banco.abrir();
  }

  Future<void> inserir(Localizacao localizacao) async {
    final db = await _banco.abrir();
    await db.insert('localizacoes', localizacao.toMap());
  }

  Future<List<Localizacao>> consultar() async {
    final db = await _banco.abrir();
    final registros = await db.query(
      'localizacoes',
      orderBy: 'instante DESC, id DESC',
      limit: 100, // Limita a consulta; não apaga os registros antigos.
    );
    return registros.map(Localizacao.fromMap).toList();
  }

  Future<void> limpar() async {
    final db = await _banco.abrir();
    await db.delete('localizacoes'); // Sem WHERE: remove todas as linhas.
  }
}
