import 'package:flutter/material.dart';
import 'package:satep/screen/InfoAgendamento.dart';

class Historicoagendamento extends StatelessWidget {
  const Historicoagendamento({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      "Histórico de agendamentos",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 48), // para balancear a seta
              ],
            ),
            SizedBox(height: 30),            // Filtros
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip("Concluídos", true),
                  _buildFilterChip("Cancelados", false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de cards
            Expanded(
              child: ListView(
                children: [
                  _buildAppointmentCard(
                    context,
                    "Hospital das Clínicas",
                    "Agendamento para 16/05",
                    "Otorrino",
                    "Cancelado",
                    Icons.local_hospital,
                    Colors.red,
                  ),
                  _buildAppointmentCard(
                    context,
                    "Hospital das Clínicas",
                    "Agendamento para 18/05",
                    "Dermatologista",
                    "Concluído",
                    Icons.health_and_safety,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reutilizamos o mesmo estilo dos chips
Widget _buildFilterChip(String label, bool selected) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
    ),
  );
}

// Card com personalização de cor no status
Widget _buildAppointmentCard(
    BuildContext context,
    String title,
    String subtitle,
    String detail,
    String status,
    IconData icon,
    Color statusColor) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: Icon(icon, size: 40, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const Infoagendamento(),
        );
      },
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Text(detail),
          Text(
            status,
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}