import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  final List<Localizacao> registros;
  const MapaLocalizacoes({super.key, required this.registros});

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controlador = MapController();
  bool _falhaNasRuas = false;

  List<LatLng> get _pontos => widget.registros
      .map((registro) => LatLng(registro.latitude, registro.longitude))
      .toList();

  CameraFit get _enquadramento => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(_pontos),
    padding: const EdgeInsets.all(56),
    maxZoom: 16, // Também atende um único ponto ou posições repetidas.
  );

  void _detalhes(Localizacao registro) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ItemLocalizacao(localizacao: registro),
        ),
      ),
    );
  }

  Future<void> _atribuicao() async {
    try {
      final abriu = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      );
      if (!abriu) throw Exception('Link indisponível');
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acesse openstreetmap.org/copyright para ver a licença.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const Expanded(
                child: Text(
                  'Vermelho: mais recente. Toque nos pontos para ver detalhes.',
                ),
              ),
              IconButton(
                onPressed: () => _controlador.fitCamera(_enquadramento),
                tooltip: 'Enquadrar todos os pontos',
                icon: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
        ),
        if (_falhaNasRuas)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Falha ao carregar algumas ruas. Verifique a internet e toque em Atualizar.',
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _controlador,
            options: MapOptions(initialCameraFit: _enquadramento, maxZoom: 19),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.edu.localizacoes.atividade1',
                maxNativeZoom: 19,
                panBuffer: 0, // Carrega apenas a área visualizada; sem download em massa.
                errorTileCallback: (tile, error, stackTrace) {
                  // Erros podem chegar durante o desenho do mapa.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_falhaNasRuas) {
                      setState(() => _falhaNasRuas = true);
                    }
                  });
                },
              ),
              MarkerLayer(
                markers: [
                  // Desenha a mais recente por último, para ficar por cima.
                  for (
                    var index = widget.registros.length - 1;
                    index >= 0;
                    index--
                  )
                    Marker(
                      point: LatLng(
                        widget.registros[index].latitude,
                        widget.registros[index].longitude,
                      ),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _detalhes(widget.registros[index]),
                        child: Icon(
                          Icons.location_on,
                          size: 42,
                          color: index == 0 ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Fora da área de arraste, sempre visível e clicável.
        TextButton(
          onPressed: _atribuicao,
          child: const Text('© OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
