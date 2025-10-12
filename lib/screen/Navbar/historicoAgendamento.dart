import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:satep/screen/infoAgendamento.dart';

// =========================================================================
// CONFIGURAÇÃO DA API (Reutilizando a estrutura de home.dart)
// =========================================================================

const String BASE_URL = 'http://localhost:8000'; 
// Usaremos o mesmo endpoint para buscar todos os agendamentos e filtrar o histórico
const String APPOINTMENTS_ENDPOINT = '/agendamentos/paciente'; 

// =========================================================================
// MODELO DE DADOS (Agenda - Copiado de home.dart)
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
    final idValue = json['id'] ?? -1;
    final hospitalNome = json['hospital_nome'] ?? 'Hospital Indisponível';
    final procedimento = json['procedimento'] ?? 'Detalhe Não Informado';
    final dataAgendamento = json['data_agendamento'] ?? 'Data Não Definida';
    final statusAgendamento = json['status'] ?? 'Desconhecido';
    
    return Agendamento(
      id: idValue.toString(),
      hospital: hospitalNome as String,
      detalhe: procedimento as String,
      data: dataAgendamento as String, 
      status: statusAgendamento as String, 
      icon: (procedimento as String).contains('Exame') 
            ? Icons.medical_services : Icons.health_and_safety,
    );
  }
}

// =========================================================================
// SERVIÇO DE API PARA AGENDAMENTOS (Copiado de home.dart)
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
        if (response.body.isEmpty) {
          return [];
        }
        
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Agendamento.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Faça login novamente.');
      } else {
        throw Exception('Falha ao carregar histórico: ${response.statusCode}. Corpo: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro de rede ao buscar histórico: $e');
      throw Exception('Erro ao conectar com o servidor. Verifique a URL: $e'); 
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
  String _selectedFilter = "Todos"; // Filtro inicial para histórico
  
  // Status considerados como "Histórico" (diferente de "Agendados", "Em análise")
  static const List<String> HISTORIC_STATUSES = [
    'Confirmados', // Que já ocorreram ou foram finalizados
    'Recusados', 
    'Cancelados'
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken);
    // Assumimos que fetchAgendamentos retorna TUDO, e o filtro cuida da separação.
    _historicoFuture = _apiService.fetchAgendamentos();
  }

  void _refetchHistorico() {
    setState(() {
      _historicoFuture = _apiService.fetchAgendamentos();
    });
  }

  // Funções de estilo de chips replicadas de home.dart
  Color _getChipColor(String label, bool isSelected) {
    if (!isSelected) return Colors.grey.shade100;

    switch (label) {
      case 'Finalizados':
        return Colors.green.shade100;
      case 'Cancelados':
        return Colors.red.shade100;
      case 'Recusados':
        return Colors.red.shade100;
      default: // Todos
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
        return Colors.red.shade900;
      default: // Todos
        return Colors.blue.shade900;
    }
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    final chipColor = _getChipColor(label, selected);
    final textColor = _getChipTextColor(label, selected);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label),
        backgroundColor: chipColor,
        side: BorderSide(
          color: selected ? textColor.withOpacity(0.5) : Colors.grey.shade300,
          width: 1,
        ),
        labelStyle: TextStyle(
          color: textColor,
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

  // Widget auxiliar para o Card de Histórico (reutilizando o estilo)
  Widget _buildHistoryCard(
      BuildContext context,
      Agendamento agenda,
      Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: statusColor.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          // Navega para a tela de detalhes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InfoAgendamento(
                agendamentoId: agenda.id, 
                authToken: widget.authToken, 
              ), 
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone de destaque
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
                    Text(
                      agenda.hospital, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agenda.detalhe, 
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Data: ${agenda.data}", 
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        // Status (trailing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            agenda.status,
                            style: TextStyle(
                              color: statusColor.withOpacity(0.15),
                              fontWeight: FontWeight.bold, 
                              fontSize: 11
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Estilo Home)
              const Row(
                children: [
                  Icon(Icons.history_toggle_off, color: Colors.blue, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "Histórico de Agendamentos",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // 2. CHIPS DE FILTRO DE HISTÓRICO
              const Text(
                "Filtrar por Status:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip("Todos"),
                    _buildFilterChip("Confirmados"), // Assumindo confirmados são finalizados no contexto histórico
                    _buildFilterChip("Recusados"),
                    _buildFilterChip("Cancelados"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 3. LISTA DE AGENDAMENTOS (Histórico)
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
                                'Erro ao carregar histórico. Verifique o servidor/token.\nDetalhe: ${snapshot.error}', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _refetchHistorico,
                                child: const Text("Tentar Novamente"),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Nenhum histórico encontrado.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    // Lista que inclui todos os agendamentos (e filtra por status histórico)
                    final List<Agendamento> historyCandidates = snapshot.data!;

                    // Filtra a lista pelo status selecionado (e exclui os "Próximos Agendamentos")
                    final filteredList = historyCandidates
                        .where((agenda) {
                           // Inclui todos os status que não são "Agendados" ou "Em análise"
                           // E aplica o filtro de status selecionado
                           final isHistory = HISTORIC_STATUSES.contains(agenda.status);

                           if (_selectedFilter == "Todos") {
                               return isHistory;
                           }
                           return isHistory && agenda.status == _selectedFilter;
                        })
                        .toList();

                    if (filteredList.isEmpty) {
                         return Center(
                           child: Text('Nenhum agendamento histórico com status "$_selectedFilter".', style: TextStyle(color: Colors.grey)),
                         );
                    }
                    
                    // Ordena a lista para mostrar os mais recentes primeiro (por data, se disponível)
                    // Nota: A ordenação real por data dependeria de um formato de data parseável.
                    // Para simplificar, vou apenas exibir a lista filtrada.

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final agenda = filteredList[index];
                        
                        // Define cor do status de forma robusta
                        Color statusColor;
                        switch (agenda.status) {
                          case 'Confirmados':
                          case 'Finalizados':
                            statusColor = Colors.green;
                            break;
                          case 'Recusados':
                          case 'Cancelados':
                            statusColor = Colors.red;
                            break;
                          default: 
                            statusColor = Colors.grey.shade600;
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
