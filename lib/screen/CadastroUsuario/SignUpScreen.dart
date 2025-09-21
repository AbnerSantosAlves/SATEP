import 'package:flutter/material.dart';
import 'package:satep/screen/CadastroUsuario/SignUpAddressSreen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de progresso
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                "Crie a sua conta",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Digite suas informações para fazer Login",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 25),

              // Campos de input
              _buildTextField("Nome completo"),
              _buildTextField("CPF"),
              _buildTextField("Telefone"),
              _buildTextField("Email"),
              _buildPasswordField("Senha"),
              _buildPasswordField("Confirme a senha"),
              const SizedBox(height: 30),

              // Botão próximo
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpAddressScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[100],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.lightBlue),
                    ),
                  ),
                  child: const Text(
                    "Próximo",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Campo de texto comum
  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }

  // Campo de senha
  Widget _buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.visibility_off),
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }
}
