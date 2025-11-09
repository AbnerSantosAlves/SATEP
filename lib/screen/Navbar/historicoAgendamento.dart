// historicoAgendamento.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:satep/screen/infoAgendamento.dart';

// =========================================================================
// CONFIGURAÇÃO DA API
// =========================================================================
const String BASE_URL = 'https://backend-satep-6viy.onrender.com';
const String APPOINTMENTS_ENDPOINT = '/agendamentos/paciente';

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
    final hospitalNome =
        (json['hospital_nome'] as String?) ??
        (json['hospital']?['nome'] as String?) ??
        'Hospital Indisponível';
    final procedimento = json['procedimento'] as String? ?? 'Detalhe não informado';
    final dataAgendamento = json['data_agendamento'] as String? ?? 'Data não definida';
    final statusAgendamento =
        json['status_agendamento'] as String? ?? json['status'] as String? ?? 'Desconhecido';

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
// SERVIÇO DE API PARA AGENDAMENTOS
// =========================================================================
class ApiService {
  final String authToken;
  ApiService({required this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<List<Agendamento>> fetchAgendamentos() async {
    final uri = Uri.parse('$BASE_URL$APPOINTMENTS_ENDPOINT');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isEmpty) return [];

        final decoded = jsonDecode(body);
        if (decoded is List) {
          return decoded.map((item) => Agendamento.fromJson(item)).toList();
        } else {
          // Caso venha um objeto em vez de lista
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro de rede: $e');
      throw Exception('Erro de conexão com servidor: $e');
    }
  }
}

// =========================================================================
// HISTÓRICO DE AGENDAMENTO SCREEN
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

  // Status considerados histórico
  static const List<String> HISTORIC_STATUSES = [
    'Finalizado',
    'Cancelado',
    'Recusado'
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken);
    _historicoFuture = _apiService.fetchAgendamentos();
  }

  void _refetchHistorico() {
    setState(() {
      _historicoFuture = _apiService.fetchAgendamentos();
    });
  }

  // Estilo dos filtros (chips)
  Color _getChipColor(String label, bool isSelected) {
    if (!isSelected) return Colors.grey.shade100;
    switch (label) {
      case 'Finalizados':
        return Colors.green.shade100;
      case 'Cancelados':
        return Colors.red.shade100;
      case 'Recusados':
        return Colors.orange.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getChipTextColor(String label, bool isSelected) {
    if (!isSelected) return Colors.black87;
    switch (label) {
      case 'Finalizados':
        return Colors.green.shade900;
      case 'Cancelados':
        return Colors.red.shade900;
      case 'Recusados':
        return Colors.orange.shade900;
      default:
        return Colors.blue.shade900;
    }
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label),
        backgroundColor: _getChipColor(label, selected),
        side: BorderSide(
          color: selected
              ? _getChipTextColor(label, selected).withOpacity(0.5)
              : Colors.grey.shade300,
          width: 1,
        ),
        labelStyle: TextStyle(
          color: _getChipTextColor(label, selected),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Agendamento agenda, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: statusColor.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InfoAgendamento(agendamentoId: agenda.id, authToken: widget.authToken),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(agenda.icon, size: 30, color: statusColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agenda.hospital,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(agenda.detalhe,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Data: ${agenda.data}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            agenda.status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_toggle_off, color: Colors.blue, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "Histórico de Agendamentos",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              const Text("Filtrar por Status:",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 10),

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip("Finalizados"),
                    _buildFilterChip("Recusados"),
                    _buildFilterChip("Cancelados"),
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
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Erro ao carregar histórico.\nDetalhe: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: _refetchHistorico,
                                  child: const Text("Tentar Novamente"))
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('Nenhum histórico encontrado.',
                              style: TextStyle(color: Colors.grey)));
                    }

                    final all = snapshot.data!;
                    final filteredList = all
                        .where((agenda) =>
                            HISTORIC_STATUSES.contains(agenda.status) &&
                            agenda.status == _selectedFilter)
                        .toList();

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Text(
                            'Nenhum agendamento com status "${_selectedFilter}".',
                            style: TextStyle(color: Colors.grey.shade600)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, i) {
                        final agenda = filteredList[i];
                        Color statusColor;
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
                          default:
                            statusColor = Colors.grey;
                            break;
                        }
                        return _buildHistoryCard(context, agenda, statusColor);
                      },
                    );
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
