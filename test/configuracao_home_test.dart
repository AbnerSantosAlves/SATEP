import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satep/screen/Navbar/configuracaoHome.dart';
import 'package:satep/screen/configuration.dart';

void main() {
  setUp(() {
    // Reseta appExit antes de cada teste
    appExit = ([int code = 0]) {};
  });

  testWidgets('Renderiza elementos principais do ProfileScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    // Verifica título
    expect(find.text('Perfil'), findsOneWidget);

    // Verifica informações do usuário
    expect(find.text('Marco Nascimento'), findsOneWidget);
    expect(find.text('(12) 99808-0765'), findsOneWidget);

    // Verifica itens do menu
    expect(find.text('Seu perfil'), findsOneWidget);
    expect(find.text('Sair do aplicativo'), findsOneWidget);
    expect(find.text('Sobre o aplicativo'), findsOneWidget);
  });

  testWidgets('Clicar em "Seu perfil" navega para Configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    await tester.tap(find.text('Seu perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(Configuration), findsOneWidget);
  });

  testWidgets('Clicar em "Sair do aplicativo" chama appExit', (WidgetTester tester) async {
    bool saiu = false;
    appExit = ([int code = 0]) {
      saiu = true;
    };

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    await tester.tap(find.text('Sair do aplicativo'));
    await tester.pumpAndSettle();

    expect(saiu, true);
  });
}
