import 'package:flutter/material.dart';
import 'package:satep/screen/Login/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Adicione este import



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Suporte para Português do Brasil
        Locale('en', 'US'), // Opcional: manter o Inglês
      ],
      // ------------------------------------
      home: Home(),
    );

  }
}












