# Minhas localizações

Aplicativo Flutter para Android desenvolvido para a Atividade 1 da disciplina de Programação para Dispositivos Móveis II.

**Integrante:** Rodrigo Lima

**Professor:** Arley

## Funcionalidades

- Iniciar e parar a coleta contínua de localização, com intervalo solicitado de 20 segundos e alta precisão.
- Manter a coleta ao navegar entre telas ou minimizar o aplicativo, com notificação no Android.
- Salvar as posições em um banco SQLite local.
- Consultar as últimas 100 posições, da mais recente para a mais antiga, com data, hora, coordenadas e precisão.
- Visualizar as posições em um mapa interativo, destacando a mais recente em vermelho.
- Atualizar os registros e limpar todo o histórico mediante confirmação.
- Acessar as configurações de localização e permissões.

## Requisitos

- Flutter 3.47.3 ou versão compatível com Dart 3.13.3.
- Android SDK e um celular ou emulador Android.
- Internet para carregar as imagens do mapa que ainda não estejam em cache.

## Executar

```bash
git clone https://github.com/rodrigoaslima/app-localizacao.git
cd app-localizacao
flutter pub get
flutter devices
flutter run -d ID_DO_ANDROID
```

Substitua `ID_DO_ANDROID` pelo identificador listado por `flutter devices`.

No Android Studio, abra a pasta raiz do projeto, onde está o `pubspec.yaml`, com os plugins Flutter e Dart instalados. Inicie um emulador pelo **Device Manager**, selecione o dispositivo e execute `lib/main.dart`.

Ao iniciar a coleta, autorize localização e notificações. No emulador, utilize **Extended Controls → Location** para enviar posições e simular deslocamentos.

## Organização do código

```text
lib/
├── main.dart
├── app.dart
└── features/localizacoes/
    ├── models/                 Modelo Localizacao e conversões
    ├── data/
    │   ├── database/           Conexão e criação da tabela SQLite
    │   └── repositories/       Inserção, consulta e exclusão dos registros
    ├── services/               Permissões, localização e cache do mapa
    └── presentation/
        ├── screens/            Telas de coleta, histórico e mapa
        └── widgets/            Item de localização e mapa reutilizáveis
```

O estado das telas é controlado com `StatefulWidget` e `setState`. A navegação utiliza `Navigator` e `MaterialPageRoute`. As operações assíncronas utilizam `Future`, `async/await` e um stream de posições do Geolocator.

## Armazenamento e mapa

O banco `localizacoes.db` fica na pasta privada do aplicativo. As posições são armazenadas em UTC e apresentadas no horário local. O limite de 100 registros se aplica apenas à consulta; a limpeza exclui todas as linhas.

O mapa utiliza tiles do OpenStreetMap, com atribuição visível e cache local que respeita os cabeçalhos HTTP do provedor. Consulte a [política de uso do OpenStreetMap](https://operations.osmfoundation.org/policies/tiles/).

O intervalo e a precisão reais dependem do Android, das permissões e do sinal disponível. A coleta não reinicia automaticamente após o encerramento do processo ou a reinicialização do aparelho.

## Verificação e compilação

```bash
flutter analyze
flutter test
flutter build apk --debug
```

O APK será gerado em `build/app/outputs/flutter-apk/app-debug.apk`.
