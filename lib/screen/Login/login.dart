// login.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Necessário para TimeoutException
import 'package:satep/screen/Navbar/home.dart'; 
import 'package:satep/screen/CadastroUsuario/CadastroUsuarioScreen.dart'; 

// =========================================================================
// CONFIGURAÇÃO DA API
// =========================================================================

const String BASE_URL = 'http://localhost:8000'; 
const String LOGIN_ENDPOINT = '/paciente/token'; 

// =========================================================================
// WIDGET PRINCIPAL (Gerencia o estado e a requisição)
// =========================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$BASE_URL$LOGIN_ENDPOINT');
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          // CORREÇÃO ESSENCIAL: O backend FastAPI espera 'senha'
          'senha': password, 
        }),
      ).timeout(const Duration(seconds: 10)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // A API FastAPI retorna o token no campo 'acess_token'
        final String token = data['acess_token'] as String; 
        
        print('Login SUCESSO! Token recebido: $token');

        // >>>>>>>>> TRECHO DE NAVEGAÇÃO VERIFICADO E CORRIGIDO <<<<<<<<<<
        if (mounted) {
          // pushReplacement remove a LoginPage da pilha, impedindo o retorno pelo botão "Voltar"
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(authToken: token), 
            ),
          );
        }

      } else {
        // Tratamento de erros específicos da API (400, 401, 422)
        String errorMessage;
        if (response.statusCode == 400 || response.statusCode == 401) {
             errorMessage = 'Email ou senha inválidos. Tente novamente.'; 
        } else if (response.statusCode == 422) {
             errorMessage = 'Erro de dados: O formato da requisição está incorreto (422).';
        } else {
             errorMessage = 'Falha no login (${response.statusCode}).';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on TimeoutException catch (_) {
      // Garante que o loader pare se demorar demais
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A conexão demorou demais. Tente novamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Captura erros de rede/conexão (como bloqueio de CORS no Web)
      print('Erro crítico na requisição: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de rede ou servidor. Verifique o console do navegador (F12).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // ESSENCIAL: Sempre para o loader.
        });
      }
    }
  }


  // =========================================================================
  // UI (Estrutura do Layout)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(24.0),
        child: Form( 
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Título
              const Text(
                "Entre na sua conta",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                "Digite seu e-mail e senha para fazer login",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Campo Email
              _buildTextField(
                controller: _emailController,
                hintText: "E-mail", 
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O e-mail é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Senha
              _buildTextField(
                controller: _passwordController,
                hintText: "Senha", 
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A senha é obrigatória';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Esqueceu a senha
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implementar navegação para "Esqueceu a senha"
                  },
                  child: const Text(
                    "Esqueceu a senha?", 
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botão Entrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _login, 
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Entrar",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider com "Ou"
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("Ou", style: TextStyle(color: Colors.grey)), 
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Botões Sociais (Placeholder)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.black54),
                  label: const Text("Continuar com Google", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.grey), 
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.facebook, color: Colors.blue, size: 24),
                  label: const Text("Continuar com Facebook", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.grey), 
                  ),
                  onPressed: () {},
                ),
              ),
              
              const SizedBox(height: 60),

              // Rodapé - cadastre-se (Navega para a tela de Cadastro)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não tem uma conta? "),
                  GestureDetector(
                    onTap: () {
                       // Assume que CadastroUsuarioScreen está disponível para navegação
                       if (mounted) {
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (context) => const CadastroUsuarioScreen()), 
                         );
                       }
                    },
                    child: const Text(
                      "Cadastre-se agora",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para os campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText, 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
