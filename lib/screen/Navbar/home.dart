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

// CORREÇÃO ESSENCIAL: Usando o IP do host (10.0.2.2) para emuladores Android.
const String BASE_URL = 'http://localhost:8000'; 
const String PATIENT_APPOINTMENTS_ENDPOINT = '/agendamentos/paciente'; 
const String PENDING_APPOINTMENTS_ENDPOINT = '/agendamentos/pendentes'; 

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

  Agendamento({
    required this.id,
    required this.hospital,
    required this.detalhe,
    required this.data,
    required this.status,
    this.icon = Icons.local_hospital,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    // Tratamento de tipos e valores nulos mais seguro
    final idValue = json['id']?.toString() ?? '-1';
    final hospitalNome = json['hospital_nome'] as String? ?? 'Hospital Indisponível';
    final procedimento = json['procedimento'] as String? ?? 'Detalhe Não Informado';
    final dataAgendamento = json['data_agendamento'] as String? ?? 'Data Não Definida';
    final statusAgendamento = json['status'] as String? ?? 'Agendados'; // 'Agendados' é um bom default

    return Agendamento(
      id: idValue,
      hospital: hospitalNome,
      detalhe: procedimento,
      data: dataAgendamento, 
      status: statusAgendamento, 
      // Lógica de ícone mantida
      icon: procedimento.toLowerCase().contains('exame') 
            ? Icons.medical_services : Icons.health_and_safety,
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

  /// Busca a lista de agendamentos no endpoint especificado.
  Future<List<Agendamento>> fetchAgendamentos({
    String endpoint = PATIENT_APPOINTMENTS_ENDPOINT
  }) async {
    final uri = Uri.parse('$BASE_URL$endpoint');
    
    debugPrint('Buscando agendamentos em: $uri'); 
    
    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == '[]') {
          return [];
        }
        
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Agendamento.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Não autorizado. Faça login novamente.');
      } else {
        throw Exception('Falha ao carregar agendamentos: ${response.statusCode}. Corpo: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro de rede ao buscar agendamentos: $e');
      throw Exception('Erro ao conectar com o servidor. Verifique a URL e a conexão: $e'); 
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
  
  // Variável para armazenar a chave da HomePageContent, permitindo recarregá-la
  // de forma forçada se necessário (embora _refetchAgendamentos seja preferível)
  final GlobalKey<_HomePageContentState> _homeKey = GlobalKey<_HomePageContentState>(); 

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Passa o token e a chave para a página Home
    _pages = [
      _HomePageContent(key: _homeKey, authToken: widget.authToken), 
      HistoricoAgendamento(authToken: widget.authToken), 
      const ConfiguracaoScreen(), 
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (context.mounted) {
            // Usa await para esperar o retorno da NewAppointmentScreen
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewAppointmentScreen(authToken: widget.authToken), 
              ),
            );
            
            // AUTOMATIC REFRESH: Após voltar da tela de cadastro, recarrega a lista
            if (_homeKey.currentState != null) {
              _homeKey.currentState!._refetchAgendamentos();
            }
          }
        },
        backgroundColor: Colors.blue.shade700, 
        elevation: 6, 
        child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 30), 
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off), label: "Histórico"), 
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: "Perfil"), 
        ],
        unselectedItemColor: Colors.grey.shade500,
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
// CONTEÚDO DA PÁGINA HOME (Busca Agendamentos)
// =========================================================================

class _HomePageContent extends StatefulWidget {
  final String authToken;
  const _HomePageContent({super.key, required this.authToken});

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  late Future<List<Agendamento>> _agendamentosFuture;
  late ApiService _apiService;
  String _selectedFilter = "Agendados"; 
  
  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken);
    _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilter);
  }

  /// NOVA FUNÇÃO: Obtém o Future com base no filtro selecionado
  Future<List<Agendamento>> _fetchAgendamentosByFilter(String filter) {
    // Endpoint para 'Em análise' (pendentes)
    if (filter == 'Em análise') {
      return _apiService.fetchAgendamentos(endpoint: PENDING_APPOINTMENTS_ENDPOINT);
    } else {
      // Endpoint padrão. O filtro de status será aplicado localmente.
      return _apiService.fetchAgendamentos(endpoint: PATIENT_APPOINTMENTS_ENDPOINT);
    }
  }

  /// Função pública para atualizar a busca (refetch), usada após a criação de um novo agendamento.
  void _refetchAgendamentos() {
    // Limpa a lista atual e recarrega a busca.
    setState(() {
      _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilter);
    });
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
      default: // Agendados
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
      default: // Agendados
        return Colors.blue.shade900;
    }
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
              // 1. HEADER 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bem-vindo(a)!",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Olá, Paciente Satep", 
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // 3. CARD Promocional/Informativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Guia Rápido Satep",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Veja nosso vídeo explicativo e saiba mais sobre os serviços.",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Implementar link para vídeo aqui
                            },
                            icon: const Icon(Icons.arrow_right_alt, color: Colors.blue),
                            label: const Text("Assistir Agora", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              
              // 2. BUSCA (Search Bar) - Funcionalidade de filtro local pode ser adicionada aqui
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), 
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Busque seus agendamentos aqui",
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),


              const SizedBox(height: 25), 
              // Título da Lista
              const Text(
                "Próximos Agendamentos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // 4. CHIPS DE FILTRO 
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip("Agendados"),
                    _buildFilterChip("Em análise"),
                    _buildFilterChip("Confirmados"),
                    _buildFilterChip("Recusados"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 5. LISTA DE AGENDAMENTOS (FutureBuilder)
              Expanded(
                child: FutureBuilder<List<Agendamento>>(
                  future: _agendamentosFuture,
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
                                // Exibindo o erro de forma mais controlada
                                'Erro ao carregar agendamentos.\nDetalhe: ${snapshot.error.toString().split(':').last.trim()}', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _refetchAgendamentos,
                                child: const Text("Tentar Novamente"),
                              ),
                            ],
                          ),
                        ),
                      );
                    } 

                    final allAppointments = snapshot.data ?? [];
                    List<Agendamento> filteredList;

                    // Filtra localmente APENAS se o filtro NÃO for 'Em análise'.
                    // Assume-se que o endpoint /pendentes já faz o filtro de Em análise no backend.
                    if (_selectedFilter == 'Em análise') {
                      filteredList = allAppointments; // Usa a lista completa da API /pendentes
                    } else {
                      // Filtra a lista padrão (PATIENT_APPOINTMENTS_ENDPOINT) localmente
                      filteredList = allAppointments
                          .where((agenda) => agenda.status == _selectedFilter)
                          .toList();
                    }

                    if (filteredList.isEmpty) {
                        return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  'Nenhum agendamento encontrado com status "$_selectedFilter".', 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                                ),
                              ],
                            ),
                          );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final agenda = filteredList[index];
                        
                        Color statusColor;
                        switch (agenda.status) {
                          case 'Confirmados':
                            statusColor = Colors.green;
                            break;
                          case 'Recusados':
                            statusColor = Colors.red;
                            break;
                          case 'Em análise':
                            statusColor = Colors.orange;
                            break;
                          default: // Agendados
                            statusColor = Colors.blue.shade700;
                            break;
                        }

                        // Função auxiliar para formatar a data
                        String formatarData(String dataString) {
                          try {
                            // Tenta parsear e extrair apenas a parte da data (YYYY-MM-DD)
                            // Se for um formato como "2023-10-27T10:00:00Z"
                            return dataString.split('T')[0].split('-').reversed.join('/'); // Ex: 27/10/2023
                          } catch (e) {
                            return dataString; // Retorna a string original se falhar
                          }
                        }
                        
                        final dataFormatada = formatarData(agenda.data);

                        return _buildAppointmentCard(
                          context,
                          agenda.hospital,
                          "Agendado para $dataFormatada", // Data formatada
                          agenda.detalhe,
                          agenda.status,
                          agenda.icon,
                          statusColor,
                          agenda.id, 
                          widget.authToken, 
                        );
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

  // Função buildFilterChip CORRIGIDA para disparar a nova busca
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
          // Atualiza o filtro e dispara a nova busca
          setState(() {
            _selectedFilter = label;
            _agendamentosFuture = _fetchAgendamentosByFilter(_selectedFilter);
          });
        },
      ),
    );
  }
}

// =========================================================================
// WIDGET AUXILIAR PARA O CARD (Melhorado)
// =========================================================================

Widget _buildAppointmentCard(
    BuildContext context,
    String title,
    String subtitle, // Agora contém a data formatada
    String detail,
    String status,
    IconData icon,
    Color statusColor,
    String agendamentoId, 
    String authToken, 
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 6, 
    shadowColor: statusColor.withOpacity(0.2), 
    child: InkWell( 
      onTap: () {
        // Navega para a tela de detalhes, passando o ID e o Token
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoAgendamento(
              agendamentoId: agendamentoId, 
              authToken: authToken, 
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
              child: Icon(icon, size: 30, color: statusColor),
            ),
            const SizedBox(width: 15),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e Hospital
                  Text(
                    title, 
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Detalhe do Procedimento
                  Text(
                    detail, 
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Data e Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle, // Data formatada
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
                          status,
                          style: TextStyle(
                            color: statusColor, 
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
