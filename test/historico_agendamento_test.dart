import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satep/screen/Navbar/historicoAgendamento.dart';
import 'package:satep/screen/infoAgendamento.dart';

void main() {
  testWidgets('Renderiza elementos principais da tela de histórico', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HistoricoAgendamento()),
      ),
    );

    // Verifica título
    expect(find.text("Histórico de agendamentos"), findsOneWidget);

    // Verifica filtros
    expect(find.text("Concluídos"), findsOneWidget);
    expect(find.text("Cancelados"), findsOneWidget);

    // Verifica cards
    expect(find.text("Hospital das Clínicas"), findsWidgets);
    expect(find.text("Agendamento para 16/05"), findsOneWidget);
    expect(find.text("Agendamento para 18/05"), findsOneWidget);
  });

  testWidgets('Botão de voltar aciona Navigator.pop', (WidgetTester tester) async {
    bool voltou = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onPopPage: (route, result) {
            voltou = true;
            return route.didPop(result);
          },
          pages: const [
            MaterialPage(
              child: Scaffold(body: HistoricoAgendamento()),
            ),
          ],
        ),
      ),
    );

    // Pressiona botão voltar
    await tester.tap(find.byIcon(Icons.west_outlined));
    await tester.pumpAndSettle();

    expect(voltou, true);
  });

  testWidgets('Clicar no card abre InfoAgendamento', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HistoricoAgendamento()),
      ),
    );

    // Clica no primeiro card
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Verifica se InfoAgendamento foi aberto
    expect(find.byType(InfoAgendamento), findsOneWidget);
  });
}
