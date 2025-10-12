import 'dart:io';
import 'package:flutter/material.dart';
import 'package:satep/screen/configuration.dart'; // Mantendo a importação original

// Função que pode ser substituída nos testes
void Function([int]) appExit = ([int code = 0]) => exit(code);

// =========================================================================
// WIDGETS AUXILIARES PARA REUSO E ESTILO
// =========================================================================

// Constrói o título de uma seção com um estilo mais moderno e destacado
Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700, // Cor de destaque
            ),
        ),
    );
}

// Constrói um item de configuração no formato ListTile com ícone colorido
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
        trailing: showChevron ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: onTap,
    );
}

// =========================================================================
// TELA PRINCIPAL DE CONFIGURAÇÃO (Substitui ProfileScreen)
// =========================================================================

class ConfiguracaoScreen extends StatelessWidget {
  const ConfiguracaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed MaterialApp wrapper to avoid nesting issues in the main navigation
    return Scaffold(
      // AppBar limpa e minimalista para a tela de configurações
      appBar: AppBar(
        title: const Text('Configurações do Perfil'),
        elevation: 0, 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Aumento de padding geral
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Cartão de Perfil Aprimorado
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade500, // Cor primária de destaque
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
                      child: Icon(Icons.person, size: 40, color: Colors.blue), // Ícone placeholder
                      // backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Opção para imagem real
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marco Nascimento',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '(12) 99808-0765',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, color: Colors.white, size: 24), // Ícone para editar
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Seção de Conta/Geral
              _buildSectionTitle('Conta'),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4, // Elevação sutil
                child: Column(
                  children: [
                    _buildSettingItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Seu perfil',
                      iconColor: Colors.blue.shade700,
                      onTap: () {
                          // Navega para a tela Configuration
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Configuration()),
                          );
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Segurança e Senha',
                      iconColor: Colors.deepPurple.shade700,
                      onTap: () {
                        // Ação futura
                      },
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
                      onTap: () {
                        // Ação futura
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Ajuda e FAQ',
                      iconColor: Colors.orange.shade700,
                      onTap: () {
                        // Ação futura
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSettingItem(
                      context,
                      icon: Icons.logout,
                      title: 'Sair do aplicativo',
                      iconColor: Colors.red.shade700,
                      showChevron: false, // Não mostra a seta para a ação de sair
                      onTap: () {
                        appExit(0); // Função para sair do app
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
