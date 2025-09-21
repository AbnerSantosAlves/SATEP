import 'package:flutter/material.dart';
import 'package:satep/models/configuration_model.dart';

class Configuration extends StatelessWidget {
  Configuration({super.key});

  final ConfigurationModel configurationModel = ConfigurationModel(
    id: '01',
    nome: "Abner",
    email: "abnersantos121@gmail.com",
    telefone: "(11)997010985",
    cpf: "201121292",
    endereco: "Rua cidade de Osasco, Itaóca",
    urlImage: "None",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(249, 249, 249, 249),

      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho fora do padding
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.west_outlined),
                  onPressed: () {
                    Navigator.pop(context); // volta para a tela anterior
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Configurações",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 48), // para balancear a seta
              ],
            ),
            SizedBox(height: 20),

            // Conteúdo principal rolável
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: ListView(
                  children: [
                    // Perfil
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          configurationModel.nome,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Informações
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        SizedBox(height: 30),
                        Text("Email",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        _textbox(configurationModel.email),
                        Text("Telefone",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        _textbox(configurationModel.telefone),
                        Text("CPF",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        _textbox(configurationModel.cpf),
                        Text("Endereço",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        _textbox(configurationModel.endereco),
                      ],
                    ),

                    // Botão Salvar
                    Center(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          fixedSize: Size(100, 50),
                        ),
                        child: const Text(
                          "Salvar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget reutilizável para campos
Widget _textbox(String label) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          suffixIcon: const Icon(Icons.edit),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
