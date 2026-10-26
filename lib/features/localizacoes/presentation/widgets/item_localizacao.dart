import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  final Localizacao localizacao;
  const ItemLocalizacao({super.key, required this.localizacao});

  String _dois(int numero) => numero.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final data = localizacao.instante.toLocal();
    final horario =
        '${_dois(data.day)}/${_dois(data.month)}/${data.year} '
        '${_dois(data.hour)}:${_dois(data.minute)}:${_dois(data.second)}';
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(horario),
      subtitle: Text(
        'Latitude: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão estimada: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
