import 'package:flutter/material.dart';
import 'package:satep/screen/CadastroUsuario/CadastroUsuarioScreen.dart';
import 'package:satep/screen/Login/login.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo azul
          Container(
            color: const Color(0xFF4AC1F0), // cor do fundo da imagem
          ),

          // Conteúdo da tela
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo ou título
                Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.public, // substituindo logo por ícone
                        color: Colors.white,
                        size: 60,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "SATEP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Texto informativo
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    "Ajudando você a se manter saudável!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),

                const Spacer(),

                // Imagem da pessoa
                SizedBox(
                  height: 250,
                  child: Image.asset(
                    'assets/images/person.png', // substitua pelo caminho da imagem
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Botões
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context,  MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Entrar"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context,  MaterialPageRoute(builder: (context) => CadastroUsuarioScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Crie uma conta",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
