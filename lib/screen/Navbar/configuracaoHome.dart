import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

// Definindo classes para as telas
import 'package:satep/screen/Login/home.dart' show Home;
import 'package:satep/screen/configuration.dart' show Configuration;

// =========================================================================
// CONSTANTES E VARIÁVEIS GLOBAIS
// =========================================================================

const String kBaseUrl = 'https://backend-satep-6viy.onrender.com';

void appExit() {
  SystemNavigator.pop();
}

// =========================================================================
// FUNÇÃO PARA CORRIGIR ACENTOS (UTF-8 quebrado)
// =========================================================================

String corrigirEncoding(String texto) {
  try {
    return utf8.decode(texto.runes.toList());
  } catch (_) {
    return texto;
  }
}

// =========================================================================
// MODELO DE DADOS
// =========================================================================

class Paciente {
  final String nome;
  final String telefone;

  const Paciente({
    required this.nome,
    required this.telefone,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      nome: corrigirEncoding(json['nome'] ?? "Nome não disponível"),
      telefone: corrigirEncoding(json['telefone'] ?? "Telefone não informado"),
    );
  }

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
// WIDGETS AUXILIARES
// =========================================================================

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
    trailing: showChevron
        ? const Icon(Icons.chevron_right, color: Colors.grey)
        : null,
    onTap: onTap,
  );
}

// =========================================================================
// SERVIÇO DE DADOS
// =========================================================================

class PacienteService {
  final String baseUrl;
  final String authToken;

  PacienteService({
    required this.baseUrl,
    required this.authToken,
  });

  Future<Paciente> fetchPaciente() async {
    final uri = Uri.parse('$baseUrl/paciente/me');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Paciente.fromJson(data);
      } else {
        debugPrint("Erro ao buscar paciente: ${response.statusCode}");
        return Paciente.error;
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
      return Paciente.connectionFailure;
    }
  }
}

// =========================================================================
// TELA PRINCIPAL DE CONFIGURAÇÃO
// =========================================================================

class ConfiguracaoScreen extends StatefulWidget {
  final String authToken;

  const ConfiguracaoScreen({super.key, required this.authToken});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  Paciente _paciente = Paciente.loading;
  late final PacienteService _service;

  @override
  void initState() {
    super.initState();
    _service = PacienteService(
      baseUrl: kBaseUrl,
      authToken: widget.authToken,
    );
    _fetchPaciente();
  }

  Future<void> _fetchPaciente() async {
    final pacienteData = await _service.fetchPaciente();
    if (mounted) {
      setState(() {
        _paciente = pacienteData;
      });
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Sair do Aplicativo"),
          content: const Text("Tem certeza de que deseja sair?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: const Text("Sair"),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Home()),
                  (route) => false,
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
            children: [
              _buildProfileCard(context, _paciente),
              const SizedBox(height: 30),
              _buildSectionTitle('Conta'),
              const SizedBox(height: 10),
              _buildAccountSettings(context),
              const SizedBox(height: 30),
              _buildSectionTitle('Suporte e Ações'),
              const SizedBox(height: 10),
              _buildSupportAndActions(context),
            ],
          ),
        ),
      ),
    );
  }

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
                corrigirEncoding(paciente.nome),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                corrigirEncoding(paciente.telefone),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit, color: Colors.white, size: 24),
        ],
      ),
    );
  }

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Configuration(authToken: widget.authToken),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
            onTap: () {},
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Ajuda e FAQ',
            iconColor: Colors.orange.shade700,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sair do aplicativo',
            iconColor: Colors.red.shade700,
            showChevron: false,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
