// home.dart (Otimizado)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Adicionado para formatação de data mais robusta

// Importa os outros arquivos (mantendo a estrutura original)
import 'package:satep/screen/CadastroAgendamento/cadastroAgendamento.dart';
import 'package:satep/screen/Navbar/configuracaoHome.dart';
import 'package:satep/screen/Navbar/historicoAgendamento.dart';
import 'package:satep/screen/infoAgendamento.dart';

// =========================================================================
// CONFIGURAÇÃO DA API
// =========================================================================
const String BASE_URL = 'https://backend-satep-6viy.onrender.com';
const String PATIENT_APPOINTMENTS_ENDPOINT = '/agendamentos/paciente';
const String PENDING_APPOINTMENTS_ENDPOINT = '/agendamentos/paciente'; // Mudança para /agendamentos/pendentes seria melhor
const String PACIENTE_ME_ENDPOINT = '/paciente/me';

// =========================================================================
// MODELO DE DADOS (Agenda)
// =========================================================================

class Agendamento {
  final String id;
  final String hospital;
  final String detalhe;
  final DateTime dataHora; // Alterado para DateTime
  final String status;
  final IconData icon;
  final String pacienteNome; 

  Agendamento({
    required this.id,
    required this.hospital,
    required this.detalhe,
    required this.dataHora, // Alterado
    required this.status,
    required this.pacienteNome,
    this.icon = Icons.local_hospital,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    final idValue = json['id']?.toString() ?? '-1';
    final hospitalNome = (json['hospital_nome'] as String?) ?? (json['hospital']?['nome'] as String?) ?? 'Hospital Indisponível';
    final procedimento = json['procedimento'] as String? ?? json['ds_agendamento'] as String? ?? 'Detalhe Não Informado';
    final dataString = json['data_agendamento'] as String? ?? json['data'] as String? ?? '';
    
    // Tenta fazer o parse da data. Se falhar, usa DateTime.now() para evitar crash.
    DateTime dataAgendamento;
    try {
        dataAgendamento = DateTime.parse(dataString).toLocal();
    } catch (e) {
        dataAgendamento = DateTime.now();
    }

    final statusAgendamento = (json['status_agendamento'] as String?) ?? (json['status'] as String?) ?? 'Agendado';
    final pacienteNome = (json['paciente'] != null)
        ? (json['paciente']['nome'] as String? ?? 'Paciente')
        : (json['paciente_nome'] as String? ?? 'Paciente');

    return Agendamento(
      id: idValue,
      hospital: hospitalNome,
      detalhe: procedimento,
      dataHora: dataAgendamento, // Usando DateTime
      status: statusAgendamento,
      pacienteNome: pacienteNome,
      icon: procedimento.toLowerCase().contains('exame') ? Icons.medical_services : Icons.health_and_safety,
    );
  }
}

// =========================================================================
// SERVIÇO DE API PARA AGENDAMENTOS (Mantido com pequenas correções)
// =========================================================================

class ApiService {
  final String authToken;
  ApiService({required this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<List<Agendamento>> fetchAgendamentos({String? status}) async {
    Uri uri;
    if (status != null && status == 'Em análise') {
      // Uso do endpoint genérico com filtro se backend tratar 'Em análise'
      uri = Uri.parse('$BASE_URL$PENDING_APPOINTMENTS_ENDPOINT').replace(queryParameters: {'status': 'Em análise'});
    } else {
      if (status != null && status.isNotEmpty) {
        uri = Uri.parse('$BASE_URL$PATIENT_APPOINTMENTS_ENDPOINT').replace(queryParameters: {'status': status});
      } else {
        uri = Uri.parse('$BASE_URL$PATIENT_APPOINTMENTS_ENDPOINT');
      }
    }

    debugPrint('Buscando agendamentos em: $uri');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == '[]') return [];
      final utf8Body = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(utf8Body);
      return data.map((item) => Agendamento.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Não autorizado (token inválido).');
    } else {
      // Tenta decodificar a resposta de erro para melhor mensagem
      String errorMsg = 'Erro ${response.statusCode}: Falha ao carregar agendamentos.';
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['detail'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  Future<String?> fetchPacienteNome() async {
    final uri = Uri.parse('$BASE_URL$PACIENTE_ME_ENDPOINT');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(utf8Body);
      // Retorna apenas o primeiro nome
      return (data['nome'] as String?)?.split(' ').first; 
    } else {
      debugPrint('Erro ao buscar paciente: ${response.statusCode}');
      return null;
    }
  }

  Future<bool> cancelarAgendamento(String agendamentoId) async {
    final uri = Uri.parse('$BASE_URL/agendamento/$agendamentoId/cancelar');
    final response = await http.delete(uri, headers: _headers);
    return response.statusCode == 200 || response.statusCode == 204;
  }
}

// =========================================================================
// HOME SCREEN PRINCIPAL (Container com PageView e NavBar) - Mantida
// =========================================================================

class HomeScreen extends StatefulWidget {
  final String authToken;
  const HomeScreen({super.key, required this.authToken});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey<_HomePageContentState> _homeKey = GlobalKey<_HomePageContentState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      _HomePageContent(key: _homeKey, authToken: widget.authToken),
      HistoricoAgendamento(authToken: widget.authToken),
      ConfiguracaoScreen(authToken: widget.authToken),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewAppointmentScreen(authToken: widget.authToken)),
            );
            // Recarregar agendamentos após o retorno, se a Home estiver ativa
            _homeKey.currentState?._refetchAgendamentos(); 
          }
        },
        backgroundColor: Colors.blue.shade700,
        elevation: 6,
        // Ícone de adição mais simples
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off), label: "Histórico"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"), // Icone mais comum
        ],
        unselectedItemColor: Colors.grey.shade600, // Tom de cinza mais escuro
        selectedItemColor: Colors.blue.shade700,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

// =========================================================================
// CONTEÚDO DA PÁGINA HOME (Busca Agendamentos) - Otimizado
// =========================================================================

class _HomePageContent extends StatefulWidget {
  final String authToken;
  const _HomePageContent({super.key, required this.authToken});

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  late ApiService _apiService;
  late Future<List<Agendamento>> _agendamentosFuture;
  String _selectedFilterLabel = "Agendados";
  String _patientName = '';
  bool _loadingName = true;

  final Map<String, String> _filterToStatus = {
    'Agendados': 'Agendado',
    'Em análise': 'Em análise',
    'Confirmados': 'Confirmado',
    'Recusados': 'Recusado',
    'Cancelados': 'Cancelado',
  };

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken);
    _fetchPatientName();
    _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilterLabel);
  }

  Future<void> _fetchPatientName() async {
    setState(() => _loadingName = true);
    // Armazena apenas o primeiro nome para uma saudação concisa
    final name = await _apiService.fetchPacienteNome();
    if (mounted) {
      setState(() {
        _patientName = name ?? '';
        _loadingName = false;
      });
    }
  }

  Future<List<Agendamento>> _fetchAgendamentosByFilter(String filterLabel) {
    final mapped = _filterToStatus[filterLabel];
    // Se não for um status mapeado, retorna todos (se o backend suportar, ou 'Agendado' como default)
    return _apiService.fetchAgendamentos(status: mapped ?? 'Agendado');
  }

  void _refetchAgendamentos() {
    setState(() {
      _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilterLabel);
    });
  }

  @override
  // A remoção de didChangeDependencies evita recarregamentos desnecessários
  // Usar o _homeKey.currentState!._refetchAgendamentos() no pop do Navigator já é suficiente.
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   _refetchAgendamentos(); 
  // }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmado':
        return Colors.green.shade700;
      case 'Recusado':
      case 'Cancelado':
        return Colors.red.shade700;
      case 'Em análise':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
  
  // Funções de formatação movidas/simplificadas:
  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);


  // Diálogo de confirmação com um visual mais moderno
  void _confirmCancel(BuildContext context, String agendamentoId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancelar Agendamento? ⚠️'),
          content: const Text('Esta ação não pode ser desfeita. Tem certeza que deseja cancelar este agendamento?', style: TextStyle(color: Colors.black87)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Manter', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.of(ctx).pop(); // fecha confirm dialog
                Navigator.of(context).pop(); // fecha modal bottom sheet

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelando...'), duration: Duration(seconds: 1)));

                final success = await _apiService.cancelarAgendamento(agendamentoId);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Agendamento cancelado com sucesso.')));
                    _refetchAgendamentos();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('❌ Falha ao cancelar o agendamento.'), backgroundColor: Colors.redAccent));
                  }
                }
              },
              child: const Text('Sim, Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Novo Modal de Detalhes
  void _showAppointmentModal(BuildContext context, Agendamento agenda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            final color = _getStatusColor(agenda.status);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 50,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                        child: Icon(agenda.icon, size: 30, color: color),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(agenda.hospital, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                            const SizedBox(height: 5),
                            // Status em destaque
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                agenda.status,
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Data e Hora (Mais visíveis)
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(_formatDate(agenda.dataHora), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(width: 15),
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(_formatTime(agenda.dataHora), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('Procedimento Agendado', style: TextStyle(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(agenda.detalhe, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 20),
                  // Se o status permitir cancelamento, mostra o botão
                  if (agenda.status != 'Cancelado' && agenda.status != 'Recusado')
                    ElevatedButton.icon(
                      onPressed: () => _confirmCancel(context, agenda.id),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                      label: const Text('Cancelar Agendamento', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar Detalhes', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método build principal otimizado
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const SizedBox(height: 16),
              // HEADER
              _PatientGreetingHeader(patientName: _patientName, isLoading: _loadingName),
              const SizedBox(height: 25),

              // CARD PROMOCIONAL
              const _PromoCard(),
              const SizedBox(height: 25),

              // SEARCH BAR (melhorado com forma de campo)
              TextField(
                decoration: InputDecoration(
                  hintText: "Busque seus agendamentos aqui",
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 25),
              Text("Próximos Agendamentos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),

              // CHIPS DE FILTRO
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal, 
                  children: _filterToStatus.keys.map((label) => _buildFilterChip(label)).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // LISTA DE AGENDAMENTOS
              Expanded(
                child: FutureBuilder<List<Agendamento>>(
                  future: _agendamentosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Erro: ${snapshot.error.toString().split(':').last.trim()}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            ElevatedButton(onPressed: _refetchAgendamentos, child: const Text("Tentar Novamente"))
                          ]),
                        ),
                      );
                    }

                    final filteredList = snapshot.data ?? [];

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300), 
                          const SizedBox(height: 15), 
                          Text('Nenhum agendamento encontrado em \"$_selectedFilterLabel\".', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16))
                        ]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 0), // Removido padding extra
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final agenda = filteredList[index];
                        return GestureDetector(
                          onTap: () => _showAppointmentModal(context, agenda),
                          child: _AppointmentCard(agenda: agenda, statusColor: _getStatusColor(agenda.status)),
                        );
                      },
                    );
                  },
                ),
              )
            ]),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilterLabel == label;
    final color = _getStatusColor(label == 'Agendados' ? 'Agendado' : label);
    
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label),
        backgroundColor: selected ? color.withOpacity(0.1) : Colors.grey.shade100,
        side: BorderSide(color: selected ? color.withOpacity(0.5) : Colors.grey.shade300, width: 1),
        labelStyle: TextStyle(color: selected ? color : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Mais arredondado
        onPressed: () {
          if (!selected) {
            setState(() {
              _selectedFilterLabel = label;
              _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilterLabel);
            });
          }
        },
      ),
    );
  }
}

// =========================================================================
// WIDGETS DE COMPONENTE (Extraídos para clareza)
// =========================================================================

class _PatientGreetingHeader extends StatelessWidget {
  final String patientName;
  final bool isLoading;

  const _PatientGreetingHeader({required this.patientName, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final displayName = patientName.isEmpty ? "Paciente Satep" : patientName;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(
          "Bem-vindo(a) de volta!",
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        isLoading
            ? SizedBox(height: 30, width: 180, child: LinearProgressIndicator(color: Colors.blue.shade400))
            : Text(
                "Olá, $displayName",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18), // Mais arredondado
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.ondemand_video_outlined, color: Colors.white, size: 40), // Ícone mais moderno
          const SizedBox(width: 15),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Guia Rápido Satep", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Veja nosso vídeo explicativo e saiba mais sobre os serviços.", style: TextStyle(color: Colors.white70, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
              label: const Text("Assistir Agora", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                elevation: 0, 
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              ),
            )
          ]))
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Agendamento agenda;
  final Color statusColor;

  const _AppointmentCard({required this.agenda, required this.statusColor});

  String _formatDate(DateTime date) => DateFormat('dd/MM').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4, // Elevação um pouco menor
      shadowColor: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ícone e Cor de Status (Lado Esquerdo)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
            child: Icon(agenda.icon, size: 28, color: statusColor)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Título (Hospital)
              Text(agenda.hospital, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Detalhe/Procedimento
              Text(agenda.detalhe, style: TextStyle(fontSize: 14, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  // Data e Hora (Mais destacados)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(_formatDate(agenda.dataHora), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(_formatTime(agenda.dataHora), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(agenda.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ]
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// Manter os demais arquivos (HistoricoAgendamento, ConfiguracaoScreen, NewAppointmentScreen)