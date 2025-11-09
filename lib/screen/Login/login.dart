import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/foundation.dart';
import 'package:satep/screen/Navbar/home.dart'; // Necessário para kIsWeb

// =========================================================================
// WIDGETS PLACEHOLDER (Em um projeto real, estariam em arquivos separados)
// =========================================================================

// Placeholder para a tela de cadastro
class CadastroUsuarioScreen extends StatelessWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Usuário')),
      body: const Center(
        child: Text(
          'Tela de Cadastro de Usuário (Placeholder)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// =========================================================================
// CONFIGURAÇÃO DA API (Robusta para diferentes ambientes)
// =========================================================================

// 10.0.2.2 é o IP especial para o host loopback (localhost) visto pelo Android Emulator.
// Usamos localhost para Web/Desktop.
const String BASE_URL = kIsWeb 
    ? 'https://backend-satep-6viy.onrender.com' 
    : 'https://backend-satep-6viy.onrender.com';

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

  // Função que realiza a requisição de login para a API
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Construção da URL da API
    final url = Uri.parse('$BASE_URL$LOGIN_ENDPOINT');
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Requisição POST com timeout de 10 segundos
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          // O backend FastAPI espera 'senha'
          'senha': password, 
        }),
      ).timeout(const Duration(seconds: 40000)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // A API FastAPI retorna o token no campo 'acess_token'
        final String token = data['acess_token'] as String; 
        
        if (mounted) {
          // Navegação para a HomeScreen, removendo a LoginPage da pilha
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(authToken: token), 
            ),
          );
        }

      } else {
        // Tratamento de erros específicos da API
        String errorMessage;
        if (response.statusCode == 400 || response.statusCode == 401) {
            errorMessage = 'Credenciais inválidas. Verifique seu e-mail e senha.'; 
        } else if (response.statusCode == 422) {
            errorMessage = 'Erro de validação: O formato da requisição está incorreto (422).';
        } else {
            errorMessage = 'Falha no login. Código de erro: ${response.statusCode}.';
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
      // Trata erros de tempo limite de conexão
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempo de conexão esgotado. Verifique sua rede.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Captura erros de rede/conexão gerais (e.g., servidor fora do ar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar com o servidor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Garante que o indicador de carregamento pare
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
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Insira um e-mail válido';
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
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidade "Esqueceu a senha" em desenvolvimento.')),
                    );
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
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login com Google em desenvolvimento.')),
                    );
                  },
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
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login com Facebook em desenvolvimento.')),
                    );
                  },
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
                       // Navegação para a tela de cadastro (placeholder)
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
        focusedBorder: OutlineInputBorder( // Adiciona um destaque sutil no foco
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
