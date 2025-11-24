import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importação desnecessária, 'dart:io' foi removido e a saída será tratada com Services.
// import 'dart:io';
// import 'package:satep/screen/Login/home.dart'; // Mantido para o Logout
// import 'package:satep/screen/configuration.dart'; // Importação circular/confusa? Assumo que 'Configuration' é a tela de edição
import 'package:flutter/services.dart';

// Definindo classes para as telas (substitua pelos seus caminhos reais)
import 'package:satep/screen/Login/home.dart' show Home;
import 'package:satep/screen/configuration.dart' show Configuration;

// =========================================================================
// CONSTANTES E VARIÁVEIS GLOBAIS
// =========================================================================

// Usar um nome mais descritivo para a URL base.
const String kBaseUrl = 'https://backend-satep-6viy.onrender.com';

// Melhoria na função de saída do app:
// No Flutter, o 'exit' de dart:io não é recomendado. 'SystemNavigator.pop()' é o método preferencial.
void appExit() {
  SystemNavigator.pop();
}

// =========================================================================
// MODELO DE DADOS
// =========================================================================

/// Representa os dados básicos do paciente.
class Paciente {
  final String nome;
  final String telefone;

  const Paciente({required this.nome, required this.telefone});

  // Factory para criar um Paciente a partir de um JSON.
  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      // Usar null-aware operator para fornecer valores padrão e evitar crashes.
      nome: json['nome'] ?? "Nome não disponível",
      telefone: json['telefone'] ?? "Telefone não informado",
    );
  }

  // Objeto de paciente inicial para o estado de carregamento/erro
  static const Paciente loading = Paciente(
    nome: "Carregando...",
    telefone: "Aguarde",
  );
  static const Paciente error = Paciente(
    nome: "Erro ao carregar",
    telefone: "",
  );
  static const Paciente connectionFailure = Paciente(
    nome: "Falha na conexão",
    telefone: "",
  );
}

// =========================================================================
// WIDGETS AUXILIARES (Extraindo para métodos privados)
// =========================================================================

// Usar `const` no TextStyle e no Padding.
Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.blue.shade700,
      ),
    ),
  );
}

// Uso de parâmetros nomeados e `const` para ListTile.
Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required Color iconColor,
  required VoidCallback onTap,
  bool showChevron = true,
}) {
  return ListTile(
    leading: Icon(icon, color: iconColor, size: 26),
    title: Text(title, style: const TextStyle(fontSize: 16)),
    trailing:
        showChevron ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
    onTap: onTap,
  );
}

// =========================================================================
// SERVIÇO DE DADOS (Extração da lógica de rede)
// =========================================================================

/// Serviço responsável por interagir com a API de Pacientes.
class PacienteService {
  final String baseUrl;
  final String authToken;

  PacienteService({required this.baseUrl, required this.authToken});

  Future<Paciente> fetchPaciente() async {
    final uri = Uri.parse('$baseUrl/paciente/me');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Paciente.fromJson(data);
      } else {
        // Log de erro no console para debug
        debugPrint("Erro ao buscar paciente: ${response.statusCode}");
        return Paciente.error;
      }
    } catch (e) {
      // Log de exceção (erro de conexão, timeout, etc.)
      debugPrint("Erro de conexão: $e");
      return Paciente.connectionFailure;
    }
  }
}

// =========================================================================
// TELA PRINCIPAL DE CONFIGURAÇÃO
// =========================================================================

class ConfiguracaoScreen extends StatefulWidget {
  final String authToken; // Token vindo da HomeScreen

  const ConfiguracaoScreen({super.key, required this.authToken});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  // Inicializa o estado com o objeto de carregamento.
  Paciente _paciente = Paciente.loading;
  late final PacienteService _service; // Inicializa no initState

  @override
  void initState() {
    super.initState();
    // Instancia o serviço no initState, usando o token da widget.
    _service = PacienteService(
      baseUrl: kBaseUrl,
      authToken: widget.authToken,
    );
    _fetchPaciente();
  }

  Future<void> _fetchPaciente() async {
    final pacienteData = await _service.fetchPaciente();
    // Verifica se a widget ainda está montada antes de chamar setState.
    if (mounted) {
      setState(() {
        _paciente = pacienteData;
      });
    }
  }

  // Função para navegar e lidar com o logout
  void _logout(BuildContext context) {
    // Exemplo de modal/dialog para confirmar o logout (melhoria de UX)
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Sair do Aplicativo"),
          content: const Text("Tem certeza de que deseja sair?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Sair"),
              onPressed: () {
                // Fecha o dialog
                Navigator.of(dialogContext).pop();
                // Navega para a tela de Login (Home) e remove todas as rotas anteriores
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Home()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usar cores de fundo e foreground mais claras no AppBar, com elevation zero.
      appBar: AppBar(
        title: const Text('Configurações do Perfil'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Cartão do perfil
              _buildProfileCard(context, _paciente),

              const SizedBox(height: 30),

              // Seção de Conta
              _buildSectionTitle('Conta'),
              const SizedBox(height: 10),
              _buildAccountSettings(context),

              const SizedBox(height: 30),

              // Seção Mais
              _buildSectionTitle('Suporte e Ações'),
              const SizedBox(height: 10),
              _buildSupportAndActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // Extrai o Cartão do Perfil para um método separado (mais limpo no build).
  Widget _buildProfileCard(BuildContext context, Paciente paciente) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade500,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paciente.nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paciente.telefone,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // O ícone de edição (se for clicável, deve ter um GestureDetector ou ser um IconButton)
          const Icon(Icons.edit, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  // Extrai as configurações da Conta para um método separado.
  Widget _buildAccountSettings(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Seu perfil',
            iconColor: Colors.blue.shade700,
            onTap: () {
              // Uso de 'kBaseUrl' se for passado para a próxima tela
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Configuration(authToken: widget.authToken),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Segurança e Senha',
            iconColor: Colors.deepPurple.shade700,
            onTap: () {
              // Lógica para navegação de Segurança
            },
          ),
        ],
      ),
    );
  }

  // Extrai o Suporte e Ações para um método separado.
  Widget _buildSupportAndActions(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Sobre o aplicativo',
            iconColor: Colors.green.shade700,
            onTap: () {
              // Lógica para navegação Sobre
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Ajuda e FAQ',
            iconColor: Colors.orange.shade700,
            onTap: () {
              // Lógica para navegação Ajuda
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sair do aplicativo',
            iconColor: Colors.red.shade700,
            showChevron: false,
            onTap: () => _logout(context), // Chama a função de logout com confirmação
          ),
        ],
      ),
    );
  }
}