// home.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
const String PENDING_APPOINTMENTS_ENDPOINT = '/agendamentos/paciente';
const String PACIENTE_ME_ENDPOINT = '/paciente/me';
const String CANCEL_APPOINTMENT_ENDPOINT = '/agendamento'; // iremos usar '/agendamento/{id}/cancelar'

// =========================================================================
// MODELO DE DADOS (Agenda)
// =========================================================================

class Agendamento {
  final String id;
  final String hospital;
  final String detalhe;
  final String data;
  final String status;
  final IconData icon;
  final String pacienteNome; // adicionado para mostrar no modal (se disponível)

  Agendamento({
    required this.id,
    required this.hospital,
    required this.detalhe,
    required this.data,
    required this.status,
    required this.pacienteNome,
    this.icon = Icons.local_hospital,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    final idValue = json['id']?.toString() ?? '-1';
    // tenta obter nome do hospital (pode vir como hospital.nome ou hospital_nome)
    final hospitalNome =
        (json['hospital_nome'] as String?) ?? (json['hospital']?['nome'] as String?) ?? 'Hospital Indisponível';
    final procedimento = json['procedimento'] as String? ?? json['ds_agendamento'] as String? ?? 'Detalhe Não Informado';
    final dataAgendamento = json['data_agendamento'] as String? ?? json['data'] as String? ?? 'Data Não Definida';
    final statusAgendamento = (json['status_agendamento'] as String?) ??
        (json['status'] as String?) ??
        'Agendado';
    // tenta pegar nome do paciente se o backend retornar (joinedload)
    final pacienteNome = (json['paciente'] != null)
        ? (json['paciente']['nome'] as String? ?? 'Paciente')
        : (json['paciente_nome'] as String? ?? 'Paciente');

    return Agendamento(
      id: idValue,
      hospital: hospitalNome,
      detalhe: procedimento,
      data: dataAgendamento,
      status: statusAgendamento,
      pacienteNome: pacienteNome,
      icon: procedimento.toLowerCase().contains('exame') ? Icons.medical_services : Icons.health_and_safety,
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

  /// Busca a lista de agendamentos.
  /// Se `status` for fornecido, chama /agendamentos/paciente?status=...
  /// Se status == 'Em análise', usa endpoint de pendentes.
  Future<List<Agendamento>> fetchAgendamentos({String? status}) async {
    Uri uri;
    if (status != null && status == 'Em análise') {
      uri = Uri.parse('$BASE_URL$PENDING_APPOINTMENTS_ENDPOINT');
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
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  /// Busca os dados do paciente logado para saudação
  Future<String?> fetchPacienteNome() async {
    final uri = Uri.parse('$BASE_URL$PACIENTE_ME_ENDPOINT');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(utf8Body);
      return data['nome'] as String?;
    } else {
      debugPrint('Erro ao buscar paciente: ${response.statusCode}');
      return null;
    }
  }

  /// Cancela agendamento. Assumi endpoint DELETE /agendamento/{id}/cancelar
  Future<bool> cancelarAgendamento(String agendamentoId) async {
    final uri = Uri.parse('$BASE_URL/agendamento/$agendamentoId/cancelar');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      debugPrint('Falha ao cancelar: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}

// =========================================================================
// HOME SCREEN PRINCIPAL (Container com PageView e NavBar)
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
            if (_homeKey.currentState != null) _homeKey.currentState!._refetchAgendamentos();
          }
        },
        backgroundColor: Colors.blue.shade700,
        elevation: 6,
        child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
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
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: "Perfil"),
        ],
        unselectedItemColor: Colors.grey,
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
// CONTEÚDO DA PÁGINA HOME (Busca Agendamentos) - com filtros e modal
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

  // mapa de label para status que backend espera
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
    final name = await _apiService.fetchPacienteNome();
    if (mounted) {
      setState(() {
        _patientName = name ?? '';
        _loadingName = false;
      });
    }
  }

  Future<List<Agendamento>> _fetchAgendamentosByFilter(String filterLabel) {
    // 'Em análise' usa endpoint pendentes (segundo backend)
    if (filterLabel == 'Em análise') {
      return _apiService.fetchAgendamentos(status: 'Em análise');
    }

    final mapped = _filterToStatus[filterLabel];
    if (mapped != null && mapped.isNotEmpty) {
      return _apiService.fetchAgendamentos(status: mapped);
    }

    return _apiService.fetchAgendamentos();
  }

  void _refetchAgendamentos() {
    setState(() {
      _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilterLabel);
    });
  }

  @override
  void didChangeDependencies() {
  super.didChangeDependencies();
  _refetchAgendamentos(); // força atualização toda vez que a Home é reconstruída
  }

  Color _getChipColor(String label, bool isSelected) {
    if (!isSelected) return Colors.grey.shade100;
    switch (label) {
      case 'Confirmados':
        return Colors.green.shade100;
      case 'Recusados':
        return Colors.red.shade100;
      case 'Em análise':
        return Colors.orange.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getChipTextColor(String label, bool isSelected) {
    if (!isSelected) return Colors.black87;
    switch (label) {
      case 'Confirmados':
        return Colors.green.shade900;
      case 'Recusados':
        return Colors.red.shade900;
      case 'Em análise':
        return Colors.orange.shade900;
      default:
        return Colors.blue.shade900;
    }
  }

  // mostra modal com detalhes e opção de cancelar
  void _showAppointmentModal(BuildContext context, Agendamento agenda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: ListView(
                controller: controller,
                children: [
                  Container(
                    height: 6,
                    width: 60,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(agenda.icon, size: 28, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(agenda.hospital, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(agenda.detalhe, style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(agenda.pacienteNome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (agenda.status == 'Confirmado')
                                        ? Colors.green.shade50
                                        : (agenda.status == 'Recusado')
                                            ? Colors.red.shade50
                                            : (agenda.status == 'Em análise')
                                                ? Colors.orange.shade50
                                                : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    agenda.status,
                                    style: TextStyle(
                                      color: (agenda.status == 'Confirmado')
                                          ? Colors.green
                                          : (agenda.status == 'Recusado')
                                              ? Colors.red
                                              : (agenda.status == 'Em análise')
                                                  ? Colors.orange
                                                  : Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(_formatData(agenda.data)),
                      const SizedBox(width: 18),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      // se backend não fornecer hora, não mostra
                      Text(_extractHora(agenda.data)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Detalhes do Agendamento', style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(agenda.detalhe),
                  const SizedBox(height: 20),

                  // Botões: Cancelar e Fechar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmCancel(context, agenda.id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                          child: const Text('Cancelar Agendamento'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(), // fecha modal
                          child: const Text('Fechar'),
                        ),
                      ),
                    ],
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

  // diálogo de confirmação antes de chamar a API
  void _confirmCancel(BuildContext context, String agendamentoId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirmar cancelamento'),
          content: const Text('Tem certeza que deseja cancelar este agendamento?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Não')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () async {
                Navigator.of(ctx).pop(); // fecha confirm dialog
                Navigator.of(context).pop(); // fecha modal bottom sheet
                final success = await _apiService.cancelarAgendamento(agendamentoId);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento cancelado com sucesso.')));
                    _refetchAgendamentos();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao cancelar o agendamento.'), backgroundColor: Colors.redAccent));
                  }
                }
              },
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );
  }

  String _formatData(String dataString) {
    try {
      final datePart = dataString.split('T')[0];
      final parts = datePart.split('-'); // YYYY-MM-DD
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {
      return dataString;
    }
  }

  

  String _extractHora(String dataString) {
    try {
      if (dataString.contains('T')) {
        return dataString.split('T')[1].split('Z')[0].split('.')[0]; // HH:MM:SS
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // HEADER com saudação usando nome do paciente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    "Bem-vindo(a)!",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  _loadingName
                      ? const SizedBox(height: 26, width: 140, child: LinearProgressIndicator())
                      : Text(
                          _patientName.isEmpty ? "Olá, Paciente Satep" : "Olá, $_patientName",
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                ]),
              ],
            ),
            const SizedBox(height: 25),

            // CARD PROMOCIONAL (mantive igual)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(children: [
                const Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Guia Rápido Satep", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Veja nosso vídeo explicativo e saiba mais sobre os serviços.", style: TextStyle(color: Colors.white70, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_right_alt, color: Colors.blue),
                    label: const Text("Assistir Agora", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  )
                ]))
              ]),
            ),
            const SizedBox(height: 25),

            // SEARCH BAR (mantive)
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))]),
              child: const TextField(
                decoration: InputDecoration(hintText: "Busque seus agendamentos aqui", prefixIcon: Icon(Icons.search, color: Colors.blue), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(vertical: 15)),
              ),
            ),

            const SizedBox(height: 25),
            const Text("Próximos Agendamentos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // CHIPS DE FILTRO (mantive labels, conectei ao backend)
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _buildFilterChip("Agendados"),
                _buildFilterChip("Em análise"),
                _buildFilterChip("Confirmados"),
                _buildFilterChip("Recusados"),
                _buildFilterChip("Cancelados"),
              ]),
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
                          Text('Erro ao carregar agendamentos.\nDetalhe: ${snapshot.error.toString().split(':').last.trim()}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _refetchAgendamentos, child: const Text("Tentar Novamente"))
                        ]),
                      ),
                    );
                  }

                  final allAppointments = snapshot.data ?? [];
                  final filteredList = allAppointments; // já filtrados no backend quando passamos status

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.shade300), const SizedBox(height: 10), Text('Nenhum agendamento encontrado com status \"$_selectedFilterLabel\".', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final agenda = filteredList[index];
                      Color statusColor;
                      switch (agenda.status) {
                        case 'Confirmado':
                        case 'Confirmados':
                          statusColor = Colors.green;
                          break;
                        case 'Recusado':
                        case 'Recusados':
                          statusColor = Colors.red;
                          break;
                        case 'Em análise':
                          statusColor = Colors.orange;
                          break;
                        case 'Cancelado':
                        case 'Cancelados':
                          statusColor = Colors.grey;
                          break;
                        default:
                          statusColor = Colors.blue.shade700;
                          break;
                      }

                      final dataFormatada = _formatData(agenda.data);

                      return GestureDetector(
                        onTap: () => _showAppointmentModal(context, agenda),
                        child: _buildAppointmentCardUI(context, agenda.hospital, "Agendado para $dataFormatada", agenda.detalhe, agenda.status, agenda.icon, statusColor, agenda.id, widget.authToken),
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

  // Função buildFilterChip CORRIGIDA para disparar a nova busca
  Widget _buildFilterChip(String label) {
    final selected = _selectedFilterLabel == label;
    final chipColor = _getChipColor(label, selected);
    final textColor = _getChipTextColor(label, selected);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label),
        backgroundColor: chipColor,
        side: BorderSide(color: selected ? textColor.withOpacity(0.5) : Colors.grey.shade300, width: 1),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() {
            _selectedFilterLabel = label;
            _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilterLabel);
          });
        },
      ),
    );
  }

  // Mantive a função de construção de card, mas renomeei para não conflitar com a versão anterior
  Widget _buildAppointmentCardUI(
    BuildContext context,
    String title,
    String subtitle,
    String detail,
    String status,
    IconData icon,
    Color statusColor,
    String agendamentoId,
    String authToken,
  ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: statusColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 30, color: statusColor)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(detail, style: TextStyle(fontSize: 14, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
