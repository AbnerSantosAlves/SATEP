import 'package:flutter/material.dart';
// Certifique-se de que este arquivo existe no seu projeto,
// senão este código não irá compilar.
// import 'package:satep/models/configuration_model.dart'; 

// =========================================================================
// MODELO DE DADOS DE CONFIGURAÇÃO (Simulação)
// =========================================================================
// Coloque esta classe em lib/models/configuration_model.dart se ela não existir
class ConfigurationModel {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String cpf;
  final String endereco;
  final String urlImage;
  
  ConfigurationModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpf,
    required this.endereco,
    required this.urlImage,
  });
}

// =========================================================================
// WIDGET REUTILIZÁVEL PARA CAMPOS DE INFORMAÇÃO
// =========================================================================

Widget _buildInfoField({
  required String label, 
  required String value, 
  required IconData icon, 
  bool readOnly = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 14, 
            color: Colors.blue.shade800,
          ),
        ),
      ),
      TextField(
        readOnly: readOnly,
        controller: TextEditingController(text: value),
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
          suffixIcon: readOnly ? null : const Icon(Icons.edit, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2.0),
          ),
        ),
      ),
      const SizedBox(height: 25),
    ],
  );
}

// =========================================================================
// TELA DE CONFIGURAÇÃO DE PERFIL
// =========================================================================

class Configuration extends StatelessWidget {
  Configuration({super.key});

  // Simulação de dados do usuário (Deve ser substituído por dados reais da API)
  final ConfigurationModel configurationModel = ConfigurationModel(
    id: '01',
    nome: "Abner Santos",
    email: "abnersantos121@gmail.com",
    telefone: "(11) 99701-0985",
    cpf: "201.121.292-XX", // Formatado
    endereco: "Rua Cidade de Osasco, 123 - Itaóca, SP", // Endereço mais completo
    urlImage: "None",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fundo branco suave

      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho Customizado (Substitui o AppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                    onPressed: () {
                      Navigator.pop(context); // volta para a tela anterior
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Configurações do Perfil",
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.black87
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Para balancear o IconButton
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Conteúdo principal rolável
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                children: [
                  // Seção de Perfil
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade500, width: 3),
                            color: Colors.blue.shade50,
                          ),
                          child: Icon(Icons.person_rounded, size: 70, color: Colors.blue.shade700),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          configurationModel.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800, 
                            fontSize: 22, 
                            color: Colors.black87
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "ID: ${configurationModel.id}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w400, 
                            fontSize: 14, 
                            color: Colors.grey
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Botão de editar imagem (opcional)
                        TextButton.icon(
                          onPressed: () { /* Lógica para alterar foto */ }, 
                          icon: const Icon(Icons.camera_alt_outlined, size: 20), 
                          label: const Text("Editar Foto", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  
                  // Seção de Informações
                  const Text(
                    "Informações de Contato e Pessoais",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 30, 90, 150),
                    ),
                  ),
                  const Divider(color: Colors.blueGrey, height: 25),
                  
                  // Campos estilizados
                  _buildInfoField(
                    label: "Nome Completo",
                    value: configurationModel.nome,
                    icon: Icons.person_outline,
                    readOnly: false, // Permitindo edição
                  ),
                  _buildInfoField(
                    label: "Email",
                    value: configurationModel.email,
                    icon: Icons.email_outlined,
                  ),
                  _buildInfoField(
                    label: "Telefone",
                    value: configurationModel.telefone,
                    icon: Icons.phone_outlined,
                    readOnly: false,
                  ),
                  _buildInfoField(
                    label: "CPF",
                    value: configurationModel.cpf,
                    icon: Icons.badge_outlined,
                  ),
                  _buildInfoField(
                    label: "Endereço",
                    value: configurationModel.endereco,
                    icon: Icons.location_on_outlined,
                    readOnly: false,
                  ),

                  // Botão Salvar
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: ElevatedButton(
                        onPressed: () { /* Lógica de Salvar */ },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          "Salvar Alterações",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
