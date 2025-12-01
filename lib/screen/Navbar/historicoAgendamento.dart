// historicoAgendamento.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

// =========================================================================
// CONFIGURAÇÃO DA API
// =========================================================================
const String BASE_URL = 'https://backend-satep-6viy.onrender.com';
const String APPOINTMENTS_ENDPOINT = '/agendamentos/paciente';

// =========================================================================
// FUNÇÃO PARA CORRIGIR UTF-8
// =========================================================================
String fixUtf8(String text) {
  try {
    return utf8.decode(text.runes.toList());
  } catch (_) {
    return text;
  }
}

// =========================================================================
// MODELO DE DADOS
// =========================================================================
class Agendamento {
  final String id;
  final String hospital;
  final String detalhe;
  final String data;
  final String status;
  final IconData icon;

  Agendamento({
    required this.id,
    required this.hospital,
    required this.detalhe,
    required this.data,
    required this.status,
    this.icon = Icons.local_hospital,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    final idValue = json['id']?.toString() ?? '-1';

    final hospitalNome = fixUtf8(
      (json['hospital_nome'] as String?) ??
      (json['hospital']?['nome'] as String?) ??
      'Hospital Indisponível',
    );

    final procedimento = fixUtf8(
      json['procedimento'] as String? ?? 'Detalhe não informado',
    );

    final dataAgendamento = json['data_agendamento'] as String? ?? 'Data não definida';

    final statusAgendamento = fixUtf8(
      json['status_agendamento'] as String? ??
      json['status'] as String? ??
      'Desconhecido'
    );

    return Agendamento(
      id: idValue,
      hospital: hospitalNome,
      detalhe: procedimento,
      data: dataAgendamento,
      status: statusAgendamento,
      icon: procedimento.toLowerCase().contains('exame')
          ? Icons.medical_services
          : Icons.health_and_safety,
    );
  }
}

// =========================================================================
// SERVIÇO DA API
// =========================================================================
class ApiService {
  final String authToken;
  ApiService({required this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<List<Agendamento>> fetchAgendamentos(String statusFilter) async {
    final apiStatus = statusFilter.replaceAll(RegExp(r's$'), '');

    final uri = Uri.parse('$BASE_URL$APPOINTMENTS_ENDPOINT')
        .replace(queryParameters: {'status': apiStatus});

    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isEmpty) return [];

        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded.map((item) => Agendamento.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception("Erro ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}

// =========================================================================
// TELA DE HISTÓRICO
// =========================================================================
class HistoricoAgendamento extends StatefulWidget {
  final String authToken;
  const HistoricoAgendamento({super.key, required this.authToken});

  @override
  State<HistoricoAgendamento> createState() => _HistoricoAgendamentoState();
}

class _HistoricoAgendamentoState extends State<HistoricoAgendamento> {
  late Future<List<Agendamento>> _historicoFuture;
  late ApiService _apiService;
  String _selectedFilter = "Finalizados";

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken);
    _historicoFuture = _apiService.fetchAgendamentos(_selectedFilter);
  }

  Future<void> _fetchAgendamentosWithFilter() async {
    setState(() {
      _historicoFuture = _apiService.fetchAgendamentos(_selectedFilter);
    });
  }

  // =========================================================================
  // MODAL DE DETALHES
  // =========================================================================
  void _openDetailsModal(Agendamento agenda) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(agenda.icon, color: Colors.blue, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        agenda.hospital,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 15),

                Text("Procedimento:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(agenda.detalhe),

                const SizedBox(height: 10),

                Text("Data do Agendamento:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(agenda.data),

                const SizedBox(height: 10),

                Text("Status:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(agenda.status),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fechar"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // CHIP DE FILTRO
  // =========================================================================
  Color _getChipColor(String label, bool selected) {
    if (!selected) return Colors.grey.shade200;
    switch (label) {
      case 'Finalizados':
        return Colors.green.shade200;
      case 'Cancelados':
        return Colors.red.shade200;
      case 'Recusados':
        return Colors.orange.shade200;
      default:
        return Colors.blue.shade200;
    }
  }

  // =========================================================================
  // CARD DE AGENDAMENTO
  // =========================================================================
  Widget _buildHistoryCard(Agendamento agenda, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: InkWell(
        onTap: () => _openDetailsModal(agenda),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(agenda.icon, color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agenda.hospital,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(agenda.detalhe,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Data: ${agenda.data}",
                            style: TextStyle(color: Colors.grey.shade700)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            agenda.status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD PRINCIPAL
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.blue, size: 32),
                  SizedBox(width: 10),
                  Text(
                    "Histórico de Agendamentos",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Filtrar por status:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final label in ["Finalizados", "Recusados", "Cancelados"])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _selectedFilter == label,
                          selectedColor: _getChipColor(label, true),
                          onSelected: (_) {
                            setState(() => _selectedFilter = label);
                            _fetchAgendamentosWithFilter();
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: FutureBuilder<List<Agendamento>>(
                  future: _historicoFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Erro ao carregar histórico.\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final list = snapshot.data ?? [];

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum agendamento com status "${_selectedFilter}".',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final agenda = list[i];
                        Color statusColor = Colors.grey;

                        switch (agenda.status) {
                          case 'Finalizado':
                            statusColor = Colors.green;
                            break;
                          case 'Cancelado':
                            statusColor = Colors.red;
                            break;
                          case 'Recusado':
                            statusColor = Colors.orange;
                            break;
                        }

                        return _buildHistoryCard(agenda, statusColor);
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
