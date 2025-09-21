import 'package:flutter/material.dart';
import 'package:satep/screen/Login/login.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Texto superior
              const Text(
                "Verificação pendente",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 30),

              // Ícone de sucesso (círculo com check)
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),

              // Título
              const Text(
                "Confirme o seu E-mail",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtítulo
              const Text(
                "Uma verificação foi enviada para o seu E-mail. "
                "O seu cadastro será concluído assim que for confirmado.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Imagem do celular (placeholder ou asset seu)
              SizedBox(
                height: 140,
                child: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/747/747376.png",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // Botão Fazer Login
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.lightBlue),
                    ),
                  ),
                  child: const Text(
                    "Fazer login",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Link para reenviar
              GestureDetector(
                onTap: () {
                  // ação para reenviar e-mail
                },
                child: const Text(
                  "Enviar outra confirmação",
                  style: TextStyle(
                    color: Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
