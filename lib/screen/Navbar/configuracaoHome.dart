import 'dart:io';
import 'package:flutter/material.dart';
import 'package:satep/screen/configuration.dart';

void main() {
  runApp(const Configuracaohome());
}

class Configuracaohome extends StatelessWidget {
  const Configuracaohome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfileScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Cartão de Perfil
              Card(
                color: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Substitua por sua imagem de perfil
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marco Nascimento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '(12) 99808-0765',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Seção de Itens de Menu 1
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Seu perfil'),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Configuration()),
                          );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sair do aplicativo'),
                      onTap: () {
                       Navigator.pop(exit(0));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Título "Mais"
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Mais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Seção de Itens de Menu 2
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre o aplicativo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Ação para "Sobre o aplicativo"
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}