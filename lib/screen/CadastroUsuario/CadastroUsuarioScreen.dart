// cadastroUsuario.dart (Tela de Cadastro de Usuário estilizada)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Importe a tela de verificação pendente (baseado na imagem 655006.png)


// =========================================================================
// VARIÁVEIS DE ESTILO
// =========================================================================

const Color primaryColor = Color(0xFF4FC3F7); // Azul claro vibrante
const Color secondaryColor = Color(0xFF03A9F4); // Azul primário (botão)
const Color backgroundColor = Colors.white;
const Color inputFillColor = Color(0xFFF5F5F5); // Fundo cinza claro para inputs

// =========================================================================
// CONFIGURAÇÃO DA API E MODELOS (Mantidos)
// =========================================================================

const String BASE_URL = 'http://sua-api-aqui.com/api'; 
const String SIGNUP_ENDPOINT = '/usuario/cadastro'; 

class CadastroData {
  // Passo 1: Dados Pessoais
  String? nomeCompleto;
  String? cpf;
  String? telefone;
  String? email;
  String? senha;
  String? confirmarSenha;

  // Passo 2: Dados de Endereço
  String? endereco;
  String? bairro;
  String? complemento;

  Map<String, dynamic> toJson() => {
        'nomeCompleto': nomeCompleto,
        'cpf': cpf,
        'telefone': telefone,
        'email': email,
        'senha': senha,
        'endereco': endereco,
        'bairro': bairro,
        'complemento': complemento,
      };
}

class CadastroApiService {
  Future<bool> registerUser(CadastroData data) async {
    print("Enviando Cadastro: ${jsonEncode(data.toJson())}");
    
    // Simulação de Sucesso
    await Future.delayed(const Duration(seconds: 2));
    return true; 
  }
}

// =========================================================================
// WIDGET PRINCIPAL (CadastroUsuarioScreen)
// =========================================================================

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
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
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      Navigator.of(context).pop(); 
    }
  }

  Future<void> _submitRegistration() async {
    if (_currentStep == 2) {
      if (_addressFormKey.currentState!.validate()) {
        _addressFormKey.currentState!.save();

        setState(() {
          _isSubmitting = true;
        });

        final success = await _apiService.registerUser(_cadastroData);

        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Cadastro realizado. Verifique seu e-mail.'), backgroundColor: Colors.green));
            // Navega para a tela de Verificação Pendente
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const EmailVerificacaoScreen()), 
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Erro ao cadastrar. Tente novamente.'), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = _currentStep == 1 ? 'Próximo' : 'Concluir';
    VoidCallback? onPressed;

    if (_isSubmitting) {
      onPressed = null;
    } else if (_currentStep == 1) {
      onPressed = _goToNextStep;
    } else {
      onPressed = _submitRegistration;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header e Indicador de Passo (Top Bar)
            _buildHeader(context),
            
            // Título e Subtítulo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crie a sua conta', //
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Digite suas informações para fazer Login', //
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Conteúdo da Tela (Passo 1 ou 2)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _currentStep == 1
                    ? UserStep(formKey: _userFormKey, data: _cadastroData)
                    : AddressStep(formKey: _addressFormKey, data: _cadastroData),
              ),
            ),
            
            // Botão de Ação (Com Efeito Gradiente e Arredondamento)
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
                    backgroundColor: Colors.transparent, // Transparente para mostrar o gradiente
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          buttonText, 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
          // Indicador de Passo Estilizado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentStep}/2', 
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
// WIDGET DE CAMPO DE TEXTO ESTILIZADO (Reutilizável)
// =========================================================================

class CustomTextField extends StatelessWidget {
  final String label;
  final void Function(String?) onSaved;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.label,
    required this.onSaved,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: inputFillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: isPassword 
              ? Icon(Icons.visibility_off, color: Colors.grey.shade600) //
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordas arredondadas
            borderSide: BorderSide.none, // Sem borda visível
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: secondaryColor, width: 2), // Borda colorida ao focar
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1),
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
// PASSO 1: DADOS PESSOAIS (UserStep) - Usa CustomTextField
// =========================================================================

class UserStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final CadastroData data;

  const UserStep({super.key, required this.formKey, required this.data});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Nome completo', //
            onSaved: (value) => data.nomeCompleto = value,
            validator: (value) => value!.isEmpty ? 'Nome é obrigatório' : null,
          ),
          CustomTextField(
            label: 'CPF', 
            onSaved: (value) => data.cpf = value,
            validator: (value) => value!.length != 11 ? 'CPF inválido' : null,
            keyboardType: TextInputType.number,
          ),
          CustomTextField(
            label: 'Telefone', //
            onSaved: (value) => data.telefone = value,
            validator: (value) => value!.isEmpty ? 'Telefone é obrigatório' : null,
            keyboardType: TextInputType.phone,
          ),
          CustomTextField(
            label: 'Email', //
            onSaved: (value) => data.email = value,
            validator: (value) => value!.isEmpty || !value.contains('@') ? 'E-mail inválido' : null,
            keyboardType: TextInputType.emailAddress,
          ),
          CustomTextField(
            label: 'Senha', //
            onSaved: (value) => data.senha = value,
            validator: (value) => value!.length < 6 ? 'Mínimo de 6 caracteres' : null,
            isPassword: true,
          ),
          CustomTextField(
            label: 'Confirme a senha', //
            onSaved: (value) => data.confirmarSenha = value,
            validator: (value) {
              if (value!.isEmpty) return 'Confirmação obrigatória';
              if (value != data.senha) return 'As senhas não coincidem';
              return null;
            },
            isPassword: true,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =========================================================================
// PASSO 2: ENDEREÇO (AddressStep) - Usa CustomTextField
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Endereço', //
            onSaved: (value) => data.endereco = value,
            validator: (value) => value!.isEmpty ? 'Endereço é obrigatório' : null,
          ),
          CustomTextField(
            label: 'Bairro', //
            onSaved: (value) => data.bairro = value,
            validator: (value) => value!.isEmpty ? 'Bairro é obrigatório' : null,
          ),
          CustomTextField(
            label: 'Complemento', //
            onSaved: (value) => data.complemento = value,
            validator: (value) => null, // Campo opcional
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET PLACEHOLDER DE CONFIRMAÇÃO (EmailVerificacaoScreen)
// =========================================================================

// Crie este arquivo em 'satep/screen/EmailVerificacaoScreen.dart'
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
                const Text('Verificação pendente', style: TextStyle(color: Colors.grey)), //
                const SizedBox(height: 50),
                Icon(Icons.check_circle_outline, color: primaryColor, size: 80), 
                const SizedBox(height: 20),
                const Text(
                  'Confirme o seu E-mail',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Uma verificação foi enviada para o seu E-mail. O seu cadastro será concluído assim que for confirmado.', //
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                // Adicionando um placeholder para a imagem do celular
                Container(
                  width: 150,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Center(child: Icon(Icons.phone_android, size: 50, color: Colors.grey.shade500)),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Geralmente volta para a tela de login
                        Navigator.of(context).popUntil((route) => route.isFirst); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Fazer login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), //
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulação: E-mail de confirmação reenviado.')));
                  },
                  child: const Text(
                    'Enviar outra confirmação', //
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}