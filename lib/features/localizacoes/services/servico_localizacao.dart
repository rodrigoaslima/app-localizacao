import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ServicoLocalizacao {
  Future<void> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        'Ative o GPS em Configurações de localização e tente novamente.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Autorize a localização em Configurações de permissão.');
    }
    if (permissao != LocationPermission.whileInUse &&
        permissao != LocationPermission.always) {
      throw Exception(
        'Permissão negada. Toque em Iniciar coleta para tentar novamente.',
      );
    }
  }

  Future<void> verificarNotificacao() async {
    // Android 13+: permite que a notificação apareça na bandeja.
    final permissao = await Permission.notification.request();
    if (!permissao.isGranted) {
      throw Exception(
        'Autorize as notificações em Configurações de permissão para acompanhar a coleta.',
      );
    }
  }

  Stream<Position> posicoes() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        // Usa o GPS do Android sem depender dos serviços de localização Google.
        forceLocationManager: true,
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 20),
        // Mantém o serviço ativo ao minimizar o aplicativo Android.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localizações ativa',
          notificationText:
              'Sua localização está sendo salva. Abra o app para parar.',
          enableWakeLock: true,
          setOngoing: true,
          notificationIcon: AndroidResource(
            name: 'ic_stat_localizacao',
            defType: 'drawable',
          ),
        ),
      ),
    );
  }

  Future<bool> abrirPermissoes() => Geolocator.openAppSettings();
  Future<bool> abrirLocalizacao() => Geolocator.openLocationSettings();
}
