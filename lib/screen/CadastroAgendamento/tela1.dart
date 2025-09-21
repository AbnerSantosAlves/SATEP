import 'package:flutter/material.dart';
import 'package:satep/screen/CadastroAgendamento/tela2.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  bool _acompanha = false;
  String? _enderecoSelecionado;

  final List<String> _enderecos = [
    "Av. Nossa Sra. de Fátima, 204 - Balneário",
    "Av. Monteiro Lobato, 12092 - Balneário",
    "Adicionar um novo endereço",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: const Text(
                "1/2",
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Novo agendamento",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs Paciente/Viagem
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 3),
                    ),
                    color: Colors.lightBlueAccent,
                  ),
                  child: const Center(
                    child: Text(
                      "Paciente",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                    color: Colors.grey,
                  ),
                  child: const Center(
                    child: Text(
                      "Viagem",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Nome
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Nome",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sobrenome
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Sobrenome",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acompanhante
                  Row(
                    children: [
                      Radio(
                        value: true,
                        groupValue: _acompanha,
                        onChanged: (val) {
                          setState(() => _acompanha = !_acompanha);
                        },
                      ),
                      const Text("Com acompanhante"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Endereço
                  const Text(
                    "Endereço",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Nos informe o seu endereço",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Selecione o endereço"),
                    value: _enderecoSelecionado,
                    items: _enderecos.map((end) {
                      return DropdownMenuItem(
                        value: end,
                        child: Text(end, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _enderecoSelecionado = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Botão Next fixo no rodapé
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[100],
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NovoAgendamentoStep2()),
                          );
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}
