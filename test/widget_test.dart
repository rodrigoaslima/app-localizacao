import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/app.dart';

void main() {
  testWidgets(
    'Inicialmente permite iniciar e impede parar uma coleta inexistente',
    (tester) async {
      await tester.pumpWidget(const App());
      expect(find.text('Minhas localizações'), findsOneWidget);
      final iniciar = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Iniciar coleta'),
      );
      final parar = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Parar coleta'),
      );
      expect(iniciar.onPressed, isNotNull);
      expect(parar.onPressed, isNull);
      expect(find.text('Consultar histórico'), findsOneWidget);
      expect(find.text('Ver mapa'), findsOneWidget);
    },
  );
}
