import 'package:flutter/material.dart';
import 'package:satep/screen/Navbar/home.dart';

class AgendamentoConcluido extends StatelessWidget {
  const AgendamentoConcluido({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // seta de voltar automática
        title: const Text(
          "Concluído",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            // Ícone verde
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 20),

            // Título
            const Text(
              "Você acabou de agendar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Texto explicativo
            const Text(
              "O seu agendamento passará por uma análise! Se tudo estiver de acordo, será marcada com sucesso.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Ilustração (usa AssetImage, mas você pode trocar pelo PNG/SVG que quiser)
            SizedBox(
              height: 150,
              child: Image.asset("assets/images/ilustracao.png"),
            ),
            const Spacer(),

            // Botão azul
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  ); // Exemplo de navegação
                },
                child: const Text(
                  "Página inicial",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Link de detalhes
            GestureDetector(
              onTap: () {
                // ação de visualizar detalhes
              },
              child: const Text(
                "Visualizar detalhes",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
