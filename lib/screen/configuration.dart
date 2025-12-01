import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = 'https://backend-satep-6viy.onrender.com';

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

  String decodeUtf8(String text) {
    try {
      return utf8.decode(text.runes.toList());
    } catch (_) {
      return text;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPaciente();
  }

  Future<void> fetchPaciente() async {
    final uri = Uri.parse('$BASE_URL/paciente/me');

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

        if (mounted) {
          setState(() {
            nomeController.text = decodeUtf8(data['nome'] ?? '');
            emailController.text = decodeUtf8(data['email'] ?? '');
            telefoneController.text = decodeUtf8(data['telefone'] ?? '');
            cpfController.text = data['cpf'] ?? '';

            nrEnderecoController.text = data['nr_endereco']?.toString() ?? '';
            nmEnderecoController.text = decodeUtf8(data['nm_endereco'] ?? '');
            nmBairroController.text = decodeUtf8(data['nm_bairro'] ?? '');
            nmMunicipioController.text = decodeUtf8(data['nm_municipio'] ?? '');

            isLoading = false;
          });
        }
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar paciente: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar dados do paciente.'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => isLoading = false);
    }
  }

  Future<void> updatePaciente() async {
    setState(() => isSaving = true);

    final uri = Uri.parse('$BASE_URL/paciente/editar');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'nome': nomeController.text.isEmpty ? null : nomeController.text,
          'email': emailController.text.isEmpty ? null : emailController.text,
          'telefone': telefoneController.text.isEmpty ? null : telefoneController.text,
          'cpf': cpfController.text.isEmpty ? null : cpfController.text,
          'nr_endereco': nrEnderecoController.text.isEmpty ? null : nrEnderecoController.text,
          'nm_endereco': nmEnderecoController.text.isEmpty ? null : nmEnderecoController.text,
          'nm_bairro': nmBairroController.text.isEmpty ? null : nmBairroController.text,
          'nm_municipio': nmMunicipioController.text.isEmpty ? null : nmMunicipioController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informações atualizadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar: $e');
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

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : updatePaciente,
        backgroundColor: Colors.blue.shade700,
        icon: isSaving ? null : const Icon(Icons.save_rounded, color: Colors.white),
        label: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Salvar Alterações",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ======================================================
                    // HEADER COM BOTÃO DE VOLTAR + CENTRALIZADO
                    // ======================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),

                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // BOTÃO DE VOLTAR
                          Positioned(
                            top: 0,
                            left: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),

                          // CONTEÚDO CENTRALIZADO
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, size: 50, color: Colors.blue),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                nomeController.text.isEmpty ? "Paciente" : nomeController.text,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                emailController.text.isEmpty
                                    ? "E-mail não informado"
                                    : emailController.text,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildInfoField(label: "Nome Completo", icon: Icons.person, controller: nomeController),
                          _buildInfoField(label: "E-mail", icon: Icons.email, controller: emailController),
                          _buildInfoField(label: "Telefone", icon: Icons.phone, controller: telefoneController),
                          _buildInfoField(label: "CPF", icon: Icons.badge, controller: cpfController),
                          _buildInfoField(label: "Número", icon: Icons.numbers, controller: nrEnderecoController, numeric: true),
                          _buildInfoField(label: "Endereço", icon: Icons.location_on, controller: nmEnderecoController),
                          _buildInfoField(label: "Bairro", icon: Icons.home_work, controller: nmBairroController),
                          _buildInfoField(label: "Município", icon: Icons.location_city, controller: nmMunicipioController),
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
}
