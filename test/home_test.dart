import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satep/screen/Navbar/home.dart';
import 'package:satep/screen/infoAgendamento.dart';
import 'package:satep/screen/CadastroAgendamento/tela1.dart';

void main() {
  testWidgets('Renderiza itens principais do HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Verifica se BottomNavigationBar tem os itens corretos
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verifica se o texto inicial aparece
    expect(find.text("Olá, pessoa!"), findsOneWidget);
  });

  testWidgets('Navegar entre abas altera o conteúdo', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Aba inicial é a Home
    expect(find.text("Olá, pessoa!"), findsOneWidget);

    // Vai para Histórico
    await tester.tap(find.text("Histórico"));
    await tester.pumpAndSettle();
    expect(find.text("Histórico de agendamentos"), findsOneWidget);

    // Vai para Profile
    await tester.tap(find.text("Profile"));
    await tester.pumpAndSettle();
    expect(find.text("Perfil"), findsOneWidget);
  });

  testWidgets('Clicar no FAB abre NovoAgendamento', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verifica se abriu a tela de NovoAgendamento
    expect(find.byType(NovoAgendamento), findsOneWidget);
  });

  testWidgets('Clicar no card abre InfoAgendamento', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Deve abrir o diálogo InfoAgendamento
    expect(find.byType(InfoAgendamento), findsOneWidget);
  });
}
