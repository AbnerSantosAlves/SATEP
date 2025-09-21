import 'package:flutter/material.dart';
import 'package:satep/screen/CadastroAgendamento/AgendamentoConcluido.dart';

class NovoAgendamentoStep2 extends StatefulWidget {
  const NovoAgendamentoStep2({super.key});

  @override
  State<NovoAgendamentoStep2> createState() => _NovoAgendamentoStep2State();
}

class _NovoAgendamentoStep2State extends State<NovoAgendamentoStep2> {
  String? _hospitalSelecionado;
  String? _dataSelecionada;
  String? _horarioSelecionado;

  final List<String> _hospitais = [
    "Hospital das Clínicas",
    "Hospital Municipal",
    "Santa Casa",
  ];

  final List<String> _datas = [
    "20/09/2025",
    "21/09/2025",
    "22/09/2025",
  ];

  final List<String> _horarios = [
    "08:00",
    "10:00",
    "14:00",
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
                "2/2",
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
                      bottom: BorderSide(color: Colors.green, width: 3),
                    ),
                    color: Colors.grey,
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text("Paciente",
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
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
                      "Viagem",
                      style: TextStyle(color: Colors.white),
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
                  // Hospital
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Hospital",
                      border: UnderlineInputBorder(),
                    ),
                    value: _hospitalSelecionado,
                    items: _hospitais.map((hosp) {
                      return DropdownMenuItem(
                        value: hosp,
                        child: Text(hosp),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _hospitalSelecionado = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Procedimento
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Procedimento",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data e Horário
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Data",
                            border: UnderlineInputBorder(),
                          ),
                          value: _dataSelecionada,
                          items: _datas.map((data) {
                            return DropdownMenuItem(
                              value: data,
                              child: Text(data),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _dataSelecionada = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Horário",
                            border: UnderlineInputBorder(),
                          ),
                          value: _horarioSelecionado,
                          items: _horarios.map((hora) {
                            return DropdownMenuItem(
                              value: hora,
                              child: Text(hora),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _horarioSelecionado = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Documento médico
                  const Text(
                    "Documento médico",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Anexe o documento da consulta",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Aqui você pode chamar o picker de arquivos
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Clique aqui para anexar o documento"),
                            SizedBox(width: 8),
                            Icon(Icons.upload_file, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
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
                  MaterialPageRoute(builder: (context) => AgendamentoConcluido()),
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
