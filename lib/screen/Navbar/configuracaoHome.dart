import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:satep/screen/Login/home.dart';
import 'package:satep/screen/configuration.dart'; 
import 'package:flutter/services.dart';

// Função de saída do app
void Function([int]) appExit = ([int code = 0]) => exit(code);

const String BASE_URL = 'https://backend-satep-1.onrender.com';

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

Widget _buildSettingItem(
  BuildContext context, {
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
// TELA PRINCIPAL DE CONFIGURAÇÃO (usa token da Home)
// =========================================================================

class ConfiguracaoScreen extends StatefulWidget {
  final String authToken; // ← Token vindo da HomeScreen

  const ConfiguracaoScreen({super.key, required this.authToken});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  String nomePaciente = "Carregando...";
  String telefonePaciente = "";

  @override
  void initState() {
    super.initState();
    fetchPaciente();
  }

  Future<void> fetchPaciente() async {
    final uri = Uri.parse('$BASE_URL/paciente/me');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.authToken}',
    };

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nomePaciente = data['nome'] ?? "Nome não disponível";
          telefonePaciente = data['telefone'] ?? "Telefone não informado";
        });
      } else {
        setState(() {
          nomePaciente = "Erro ao carregar";
          telefonePaciente = "";
        });
        debugPrint("Erro ao buscar paciente: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
      setState(() {
        nomePaciente = "Falha na conexão";
        telefonePaciente = "";
      });
    }
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
            children: <Widget>[
              // Cartão do perfil (sem alteração de design)
              Container(
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
                      child: Icon(Icons.person,
                          size: 40, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomePaciente,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          telefonePaciente,
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
              ),

              const SizedBox(height: 30),

              // Seção de Conta
              _buildSectionTitle('Conta'),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    _buildSettingItem(
                      context,
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
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Segurança e Senha',
                      iconColor: Colors.deepPurple.shade700,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Seção Mais
              _buildSectionTitle('Suporte e Ações'),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    _buildSettingItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'Sobre o aplicativo',
                      iconColor: Colors.green.shade700,
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Ajuda e FAQ',
                      iconColor: Colors.orange.shade700,
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.logout,
                      title: 'Sair do aplicativo',
                      iconColor: Colors.red.shade700,
                      showChevron: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                              Home(),
                          ),
                        );
                      },
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
}
