import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  final bool Function() coletando;
  const TelaLocalizacoes({super.key, required this.coletando});

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = RepositorioLocalizacoes();
  List<Localizacao> _registros = [];
  bool _ocupado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final registros = await _repositorio.consultar();
      if (!mounted) return;
      setState(() => _registros = registros);
    } catch (erro) {
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível consultar o histórico. Tente atualizar.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _limpar() async {
    if (_ocupado) return;
    // Bloqueia também enquanto o diálogo está aberto.
    setState(() => _ocupado = true);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: Text(
          'A exclusão de TODOS os registros é permanente, incluindo '
          'os anteriores aos 100 exibidos.'
          '${widget.coletando() ? '\nA coleta está ativa: novos registros continuarão sendo salvos.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmou != true) {
      setState(() => _ocupado = false);
      return;
    }
    try {
      await _repositorio.limpar();
      if (!mounted) return;
      setState(() => _registros = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico limpo com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível limpar o histórico.')),
      );
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        await _carregar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            onPressed: _ocupado ? null : _carregar,
            tooltip: 'Atualizar registros',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _ocupado ? null : _limpar,
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Últimas 100 localizações • mais recentes primeiro'),
          ),
          if (_ocupado) const LinearProgressIndicator(),
          Expanded(
            child: _erro != null
                ? Center(child: Text(_erro!))
                : _registros.isEmpty
                ? const Center(child: Text('Nenhuma localização salva.'))
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _registros.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (_, index) =>
                          ItemLocalizacao(localizacao: _registros[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
