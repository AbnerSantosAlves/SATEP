// cadastroUsuarioScreen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========================================================================
// VARIÁVEIS DE ESTILO
// =========================================================================

const Color primaryColor = Color(0xFF4FC3F7);
const Color secondaryColor = Color(0xFF03A9F4);
const Color backgroundColor = Colors.white;
const Color inputFillColor = Color(0xFFF5F5F5);

// =========================================================================
// CONFIGURAÇÃO DA API
// =========================================================================

const String BASE_URL = 'https://backend-satep-6viy.onrender.com';
const String SIGNUP_ENDPOINT = '/pacientes';

// =========================================================================
// MODELO DE DADOS
// =========================================================================

class CadastroData {
  String? nomeCompleto;
  String? cpf;
  String? telefone;
  String? email;
  String? senha;
  String? confirmarSenha;
  String? endereco;
  String? bairro;
  String? complemento;

  Map<String, dynamic> toJson() => {
  'nome': nomeCompleto,
  'cpf': cpf,
  'telefone': telefone,
  'email': email,
  'senha': senha,
  'nr_endereco': complemento, // se for o número ou complemento
  'nm_endereco': endereco,
  'nm_bairro': bairro,
  'nm_municipio': 'Mongaguá', // ou pegue de um input se quiser
};
}

class CadastroApiService {
  Future<bool> registerUser(CadastroData data) async {
    print("📦 Enviando Cadastro: ${jsonEncode(data.toJson())}");

    try {
      final uri = Uri.parse('$BASE_URL$SIGNUP_ENDPOINT');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      print("📡 Resposta: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Erro ao registrar: $e");
      return false;
    }
  }
}

// =========================================================================
// TELA PRINCIPAL DE CADASTRO
// =========================================================================

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final CadastroData _cadastroData = CadastroData();
  final CadastroApiService _apiService = CadastroApiService();
  int _currentStep = 1;
  bool _isSubmitting = false;

  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _addressFormKey = GlobalKey<FormState>();

  void _goToNextStep() {
    if (_currentStep == 1) {
      if (_userFormKey.currentState!.validate()) {
        _userFormKey.currentState!.save();
        setState(() => _currentStep = 2);
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegistration() async {
    if (_currentStep == 2) {
      if (_addressFormKey.currentState!.validate()) {
        _addressFormKey.currentState!.save();
        setState(() => _isSubmitting = true);

        final success = await _apiService.registerUser(_cadastroData);

        setState(() => _isSubmitting = false);

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cadastro realizado com sucesso! Verifique seu e-mail.'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const EmailVerificacaoScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao cadastrar. Tente novamente.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = _currentStep == 1 ? 'Próximo' : 'Concluir';
    VoidCallback? onPressed =
        _isSubmitting ? null : (_currentStep == 1 ? _goToNextStep : _submitRegistration);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crie a sua conta',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Digite suas informações para fazer login',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _currentStep == 1
                    ? UserStep(formKey: _userFormKey, data: _cadastroData)
                    : AddressStep(formKey: _addressFormKey, data: _cadastroData),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(buttonText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: _goToPreviousStep,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_currentStep/2',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// =========================================================================
// TEXTFIELD PERSONALIZADO
// =========================================================================

class CustomTextField extends StatelessWidget {
  final String label;
  final void Function(String?) onSaved;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.onSaved,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: inputFillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}

// =========================================================================
// PASSO 1: DADOS PESSOAIS
// =========================================================================

class UserStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final CadastroData data;

  const UserStep({super.key, required this.formKey, required this.data});

  @override
  State<UserStep> createState() => _UserStepState();
}

class _UserStepState extends State<UserStep> {
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Nome completo',
            onSaved: (v) => widget.data.nomeCompleto = v,
            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            label: 'CPF',
            keyboardType: TextInputType.number,
            onSaved: (v) => widget.data.cpf = v,
            validator: (v) => v!.length != 11 ? 'CPF inválido' : null,
          ),
          CustomTextField(
            label: 'Telefone',
            keyboardType: TextInputType.phone,
            onSaved: (v) => widget.data.telefone = v,
            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            onSaved: (v) => widget.data.email = v,
            validator: (v) =>
                v!.isEmpty || !v.contains('@') ? 'E-mail inválido' : null,
          ),
          CustomTextField(
            label: 'Senha',
            controller: senhaController,
            isPassword: true,
            onSaved: (v) => widget.data.senha = v,
            validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
          ),
          CustomTextField(
            label: 'Confirmar senha',
            controller: confirmarSenhaController,
            isPassword: true,
            onSaved: (v) => widget.data.confirmarSenha = v,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirmação obrigatória';
              if (v != senhaController.text) return 'As senhas não coincidem';
              return null;
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =========================================================================
// PASSO 2: ENDEREÇO
// =========================================================================

class AddressStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final CadastroData data;

  const AddressStep({super.key, required this.formKey, required this.data});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Endereço',
            onSaved: (v) => data.endereco = v,
            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            label: 'Bairro',
            onSaved: (v) => data.bairro = v,
            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            label: 'Complemento',
            onSaved: (v) => data.complemento = v,
            validator: (v) => null,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =========================================================================
// TELA DE VERIFICAÇÃO DE EMAIL
// =========================================================================

class EmailVerificacaoScreen extends StatelessWidget {
  const EmailVerificacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, color: primaryColor, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'Verificação pendente',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Um e-mail de verificação foi enviado. Confirme para concluir seu cadastro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: const Text('Voltar ao Login',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
