import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CacheMapa {
  static Future<void> preparar() async {
    final pasta = await getApplicationCacheDirectory();
    final diretorio = Directory(p.join(pasta.path, 'mapa'));
    await diretorio.create(recursive: true);
    // Deve acontecer antes de criar o primeiro TileLayer.
    // Sem overrideFreshAge: respeita os cabeçalhos HTTP do provedor.
    BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: diretorio.path,
      maxCacheSize: 100 * 1024 * 1024,
    );
  }
}
