import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = 'https://backend-satep-6viy.onrender.com/';

class Configuration extends StatefulWidget {
  final String authToken;

  const Configuration({super.key, required this.authToken});

  @override
  State<Configuration> createState() => _ConfigurationState();
}

class _ConfigurationState extends State<Configuration> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController nrEnderecoController = TextEditingController();
  final TextEditingController nmEnderecoController = TextEditingController();
  final TextEditingController nmBairroController = TextEditingController();
  final TextEditingController nmMunicipioController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchPaciente();
  }

  // ======================================================
  // GET /paciente/me
  // ======================================================
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
          nomeController.text = data['nome'] ?? '';
          emailController.text = data['email'] ?? '';
          telefoneController.text = data['telefone'] ?? '';
          cpfController.text = data['cpf'] ?? '';
          nrEnderecoController.text = data['nr_endereco']?.toString() ?? '';
          nmEnderecoController.text = data['nm_endereco'] ?? '';
          nmBairroController.text = data['nm_bairro'] ?? '';
          nmMunicipioController.text = data['nm_municipio'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar paciente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar dados do paciente.')),
        );
      }
    }
  }

  // ======================================================
  // PUT /paciente/editar
  // ======================================================
  Future<void> updatePaciente() async {
    final uri = Uri.parse('$BASE_URL/paciente/editar');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.authToken}',
    };

    final body = jsonEncode({
      'nome': nomeController.text,
      'email': emailController.text,
      'telefone': telefoneController.text,
      'cpf': cpfController.text,
      'nr_endereco': nrEnderecoController.text,
      'nm_endereco': nmEnderecoController.text,
      'nm_bairro': nmBairroController.text,
      'nm_municipio': nmMunicipioController.text,
    });

    setState(() => isSaving = true);

    try {
      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informações atualizadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar paciente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao salvar as alterações.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ======================================================
  // INTERFACE
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : updatePaciente,
        backgroundColor: Colors.blue.shade700,
        label: isSaving
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : const Text(
                "Salvar Alterações",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        icon: isSaving ? null : const Icon(Icons.save_rounded),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ======================================================
                    // CABEÇALHO COM VOLTAR E AVATAR
                    // ======================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                          top: 30, bottom: 40, left: 20, right: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person_rounded,
                                color: Colors.blue, size: 50),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            nomeController.text.isEmpty
                                ? "Paciente"
                                : nomeController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            emailController.text.isEmpty
                                ? "E-mail não informado"
                                : emailController.text,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ======================================================
                    // CAMPOS EDITÁVEIS
                    // ======================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildInfoField(
                            label: "Nome Completo",
                            controller: nomeController,
                            icon: Icons.person_outline,
                          ),
                          _buildInfoField(
                            label: "E-mail",
                            controller: emailController,
                            icon: Icons.email_outlined,
                          ),
                          _buildInfoField(
                            label: "Telefone",
                            controller: telefoneController,
                            icon: Icons.phone_android_rounded,
                          ),
                          _buildInfoField(
                            label: "CPF",
                            controller: cpfController,
                            icon: Icons.badge_outlined,
                          ),
                          _buildInfoField(
                            label: "Número do Endereço",
                            controller: nrEnderecoController,
                            icon: Icons.confirmation_number_outlined,
                          ),
                          _buildInfoField(
                            label: "Nome do Endereço",
                            controller: nmEnderecoController,
                            icon: Icons.location_on_outlined,
                          ),
                          _buildInfoField(
                            label: "Bairro",
                            controller: nmBairroController,
                            icon: Icons.home_work_outlined,
                          ),
                          _buildInfoField(
                            label: "Município",
                            controller: nmMunicipioController,
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ======================================================
  // COMPONENTE REUTILIZÁVEL PARA OS CAMPOS
  // ======================================================
  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
      ),
    );
  }
}
