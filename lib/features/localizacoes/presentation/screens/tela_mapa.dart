import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _repositorio = RepositorioLocalizacoes();
  List<Localizacao> _registros = [];
  bool _carregando = false;
  String? _erro;
  int _versao = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final registros = await _repositorio.consultar();
      if (registros.isNotEmpty) await CacheMapa.preparar();
      if (!mounted) return;
      setState(() {
        _registros = registros;
        _versao++;
      });
    } catch (erro) {
      if (mounted) {
        setState(
          () => _erro = 'Não foi possível carregar o mapa. Tente atualizar.',
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget conteudo;
    if (_carregando) {
      conteudo = const Center(child: CircularProgressIndicator());
    } else if (_erro != null) {
      conteudo = Center(child: Text(_erro!));
    } else if (_registros.isEmpty) {
      conteudo = const Center(
        child: Text('Nenhuma localização salva. Inicie uma coleta.'),
      );
    } else {
      conteudo = MapaLocalizacoes(
        key: ValueKey(_versao),
        registros: _registros,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de localizações'),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregar,
            tooltip: 'Atualizar registros',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: conteudo),
    );
  }
}
