import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========================================================================
// CONFIGURAÇÃO DA API (Deve ser a mesma de home.dart)
// =========================================================================
const String BASE_URL = 'http://localhost:8000'; 

// =========================================================================
// MODELO DE DADOS PARA DETALHES COMPLETOS
// =========================================================================

class DetalhesAgendamento {
  final String id;
  final String pacienteNome;
  final String hospitalNome;
  final String dataAgendamento;
  final String procedimento;
  final String status;
  final String observacoes; 
  // Adicione outros campos necessários que sua API retorna
  
  DetalhesAgendamento({
    required this.id,
    required this.pacienteNome,
    required this.hospitalNome,
    required this.dataAgendamento,
    required this.procedimento,
    required this.status,
    this.observacoes = 'Nenhuma observação.', 
  });

  factory DetalhesAgendamento.fromJson(Map<String, dynamic> json) {
    return DetalhesAgendamento(
      id: json['id']?.toString() ?? 'ID Desconhecido',
      pacienteNome: json['paciente_nome'] ?? 'Paciente Desconhecido',
      hospitalNome: json['hospital_nome'] ?? 'Hospital Não Informado',
      dataAgendamento: json['data_agendamento'] ?? 'Data Não Definida',
      procedimento: json['procedimento'] ?? 'Procedimento Não Informado',
      status: json['status'] ?? 'Desconhecido',
      observacoes: json['observacoes'] ?? 'Nenhuma observação.', 
    );
  }
}

// =========================================================================
// WIDGET PRINCIPAL (Stateful para gerenciar a busca)
// =========================================================================

class InfoAgendamento extends StatefulWidget {
  final String agendamentoId;
  final String authToken; // Novo campo para autenticação

  const InfoAgendamento({
    super.key,
    required this.agendamentoId,
    required this.authToken, // Receber o token
  });

  @override
  State<InfoAgendamento> createState() => _InfoAgendamentoState();
}

class _InfoAgendamentoState extends State<InfoAgendamento> {
  late Future<DetalhesAgendamento> _agendamentoDetalhesFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a busca dos detalhes ao inicializar o estado
    _agendamentoDetalhesFuture = _fetchDetalhesAgendamento();
  }

  // =========================================================================
  // FUNÇÃO DE BUSCA DA API
  // =========================================================================

  Future<DetalhesAgendamento> _fetchDetalhesAgendamento() async {
    final url = '$BASE_URL/agendamentos/${widget.agendamentoId}';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DetalhesAgendamento.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Agendamento com ID ${widget.agendamentoId} não encontrado.');
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Token inválido ou expirado.');
      } else {
        throw Exception('Falha ao carregar detalhes do agendamento. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na busca de detalhes do agendamento: $e');
      // Lança a exceção para ser capturada pelo FutureBuilder
      rethrow; 
    }
  }

  // =========================================================================
  // CONSTRUÇÃO DA INTERFACE
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Agendamento'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<DetalhesAgendamento>(
        future: _agendamentoDetalhesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Erro ao carregar os detalhes: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            // Se os dados foram carregados, exibe o conteúdo detalhado
            final detalhes = snapshot.data!;
            return _buildDetalhesContent(detalhes);
          }
          
          // Caso padrão (nunca deve acontecer se hasData for bem tratado)
          return const Center(child: Text('Nenhum dado para exibir.'));
        },
      ),
    );
  }

  Widget _buildDetalhesContent(DetalhesAgendamento detalhes) {
    // Determina a cor do status
    Color statusColor;
    switch (detalhes.status) {
      case 'Confirmados':
        statusColor = Colors.green.shade700;
        break;
      case 'Recusados':
        statusColor = Colors.red.shade700;
        break;
      case 'Em análise':
        statusColor = Colors.orange.shade700;
        break;
      default:
        statusColor = Colors.blue.shade700;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detalhes da Consulta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Text(
                  detalhes.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1),
          
          // Data e Procedimento
          _buildInfoRow(
            icon: Icons.calendar_today, 
            label: 'Data e Hora', 
            value: detalhes.dataAgendamento,
          ),
          _buildInfoRow(
            icon: Icons.medical_services, 
            label: 'Procedimento', 
            value: detalhes.procedimento,
          ),
          
          // Local
          _buildInfoRow(
            icon: Icons.local_hospital, 
            label: 'Hospital', 
            value: detalhes.hospitalNome,
          ),

          const Divider(height: 30, thickness: 1),

          // Informações Adicionais
          const Text(
            'Informações Adicionais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.person_outline, 
            label: 'ID do Agendamento', 
            value: detalhes.id,
          ),

          // Observações (em um bloco de texto maior)
          _buildObservationBlock(detalhes.observacoes),
          
          const SizedBox(height: 30),
          
          // Botão de Ação (ex: Cancelar, Reagendar)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Implementar a lógica de cancelamento aqui
              },
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text('Cancelar Agendamento', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGETS AUXILIARES PARA DETALHES
  // =========================================================================

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade400, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationBlock(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          'Observações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            text.isEmpty ? 'Nenhuma observação detalhada.' : text,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
