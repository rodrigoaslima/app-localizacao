import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _repositorio = RepositorioLocalizacoes();
  final _servico = ServicoLocalizacao();
  StreamSubscription<Localizacao>? _assinatura;
  bool _ocupado = false;
  int _salvas = 0;
  Localizacao? _ultima;
  String _mensagem = 'Toque em Iniciar coleta para começar.';

  bool get _coletando => _assinatura != null;

  Future<void> _iniciar() async {
    if (_ocupado || _coletando) return;
    setState(() => _ocupado = true);
    try {
      await _servico.verificarPermissao();
      await _servico.verificarNotificacao();
      await _repositorio.preparar();
      if (!mounted) return;
      // asyncMap aguarda cada INSERT antes de processar a próxima posição.
      // Um listen com callback async sozinho NÃO garante essa sequência.
      _assinatura = _servico
          .posicoes()
          .asyncMap(_salvar)
          .listen(
            (localizacao) {
              if (!mounted) return;
              setState(() {
                _ultima = localizacao;
                _salvas++;
                _mensagem =
                    'Coleta ativa. $_salvas localização(ões) salva(s) nesta sessão.';
              });
            },
            onError: (Object erro) {
              unawaited(_parar(mensagem: 'A coleta foi interrompida: $erro'));
            },
            onDone: () {
              if (!mounted) return;
              setState(() {
                _assinatura = null;
                _mensagem = 'O fluxo de localização foi encerrado.';
              });
            },
          );
      setState(
        () => _mensagem = 'Coleta ativa. Aguardando localização do GPS...',
      );
    } catch (erro) {
      if (mounted) {
        setState(() => _mensagem = 'Não foi possível iniciar: $erro');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<Localizacao> _salvar(Position posicao) async {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp,
    );
    await _repositorio.inserir(localizacao);
    return localizacao;
  }

  Future<void> _parar({String mensagem = 'Coleta parada.'}) async {
    if (_ocupado || !_coletando) return;
    setState(() => _ocupado = true);
    try {
      await _assinatura?.cancel();
      if (!mounted) return;
      setState(() {
        _assinatura = null;
        _mensagem = mensagem;
      });
    } catch (erro) {
      if (mounted) setState(() => _mensagem = 'Falha ao parar a coleta: $erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _configuracoes({required bool permissao}) async {
    try {
      final abriu = permissao
          ? await _servico.abrirPermissoes()
          : await _servico.abrirLocalizacao();
      if (!abriu) throw Exception('Não foi possível abrir as configurações.');
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$erro')));
    }
  }

  @override
  void dispose() {
    // Navigator.push mantém esta tela na pilha: navegar não chama dispose.
    // Ao encerrar o componente responsável, liberamos a assinatura.
    unawaited(_assinatura?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas localizações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(
              _coletando ? Icons.gps_fixed : Icons.location_on_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(_mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_ocupado) const LinearProgressIndicator(),
            ElevatedButton.icon(
              onPressed: _ocupado || _coletando ? null : _iniciar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado || !_coletando ? null : () => _parar(),
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TelaLocalizacoes(coletando: () => _coletando),
                ),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const TelaMapa()),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver mapa'),
            ),
            TextButton(
              onPressed: () => _configuracoes(permissao: true),
              child: const Text('Configurações de permissão'),
            ),
            TextButton(
              onPressed: () => _configuracoes(permissao: false),
              child: const Text('Configurações de localização (GPS)'),
            ),
            const Text(
              'Intervalo solicitado: 20 segundos. O tempo real depende '
              'do Android e do sinal de localização. A coleta continua ao '
              'navegar e minimizar o app, enquanto o processo permanecer ativo.',
            ),
            if (_ultima != null) ...[
              const Divider(height: 32),
              const Text('Última localização salva'),
              ItemLocalizacao(localizacao: _ultima!),
            ],
          ],
        ),
      ),
    );
  }
}
