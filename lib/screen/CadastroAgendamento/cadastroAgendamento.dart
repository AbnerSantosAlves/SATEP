// cadastroAgendamento.dart 

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========================================================================
// CONFIGURAÇÃO DA API E MODELOS
// =========================================================================

const String BASE_URL = 'http://sua-api-aqui.com/api'; 
const String ADDRESS_ENDPOINT = '/paciente/enderecos';
const String OPTIONS_ENDPOINT = '/dados/opcoes'; 
const String APPOINTMENT_ENDPOINT = '/agendamento/novo';

// --- Modelos de Dados (Agendamento, Endereco, HospitalMunicipio) ---

class Endereco {
  final String id;
  final String logradouro;
  final String numero;
  final String bairro;

  Endereco({
    required this.id,
    required this.logradouro,
    required this.numero,
    required this.bairro,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['id'].toString(), 
      logradouro: json['logradouro'] as String,
      numero: json['numero'].toString(), 
      bairro: json['bairro'] as String,
    );
  }

  @override
  String toString() => '$logradouro, $numero - $bairro';
}

class HospitalMunicipio {
  final String id;
  final String nome;

  HospitalMunicipio({required this.id, required this.nome});

  factory HospitalMunicipio.fromJson(Map<String, dynamic> json) {
    return HospitalMunicipio(
      id: json['id'].toString(),
      nome: json['nome'] as String,
    );
  }
}

class AppointmentData {
  // Paciente (Tela 1)
  String? nome;
  String? sobrenome;
  bool comAcompanhante = false;
  Endereco? enderecoSelecionado;
  
  // Viagem/Consulta (Tela 2)
  HospitalMunicipio? hospitalSelecionado;
  HospitalMunicipio? municipioSelecionado;
  String? procedimento;
  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  String? documentoAnexado; 
  String? observacao;

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'sobrenome': sobrenome,
        'comAcompanhante': comAcompanhante,
        'enderecoId': enderecoSelecionado?.id,
        'hospitalId': hospitalSelecionado?.id,
        'municipioId': municipioSelecionado?.id,
        'procedimento': procedimento,
        'dataConsulta': dataSelecionada?.toIso8601String().substring(0, 10), 
        'horaConsulta': horaSelecionada != null ? 
            '${horaSelecionada!.hour.toString().padLeft(2, '0')}:${horaSelecionada!.minute.toString().padLeft(2, '0')}' : null,
        'documentoAnexadoNome': documentoAnexado, 
        'observacao': observacao,
      };
}

// --- Serviços de Requisições HTTP ---

class ApiService {
  final String authToken; 

  ApiService({required this.authToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken', 
  };

  Future<List<Endereco>> fetchUserAddresses() async {
    final uri = Uri.parse('$BASE_URL$ADDRESS_ENDPOINT');
    
    // Simulação de dados para facilitar o desenvolvimento se a API falhar
    if (authToken.isEmpty) {
        return [
            Endereco(id: '1', logradouro: 'Av. Nossa Sra. de Fátima', numero: '204', bairro: 'Balneario...'),
            Endereco(id: '2', logradouro: 'Av. Monteiro Lobato', numero: '12092', bairro: 'Balneário...'),
        ];
    }
    
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Endereco.fromJson(item)).toList();
      } else {
        throw Exception('Falha ao carregar endereços: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro de rede ao buscar endereços: $e');
      return []; 
    }
  }

  Future<List<HospitalMunicipio>> fetchOptions(String type) async {
    final uri = Uri.parse('$BASE_URL$OPTIONS_ENDPOINT?tipo=$type'); 
    
    // Simulação de dados para facilitar o desenvolvimento
    if (authToken.isEmpty) {
        if (type == 'hospital') {
            return [HospitalMunicipio(id: '101', nome: 'Hospital A'), HospitalMunicipio(id: '102', nome: 'Hospital B')];
        } else if (type == 'municipio') {
             return [HospitalMunicipio(id: '201', nome: 'Cidade X'), HospitalMunicipio(id: '202', nome: 'Cidade Y')];
        }
    }
    
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HospitalMunicipio.fromJson(item)).toList();
      } else {
        throw Exception('Falha ao carregar $type: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro de rede ao buscar $type: $e');
      return [];
    }
  }

  Future<bool> sendAppointmentData(AppointmentData data) async {
    final uri = Uri.parse('$BASE_URL$APPOINTMENT_ENDPOINT');
    
    print("Enviando Agendamento: ${jsonEncode(data.toJson())}");
    
    // Simulação de Sucesso
    if (authToken.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        return true; 
    }

    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(data.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true; 
      } else {
        print('Erro no servidor (${response.statusCode}): ${response.body}');
        return false; 
      }
    } catch (e) {
      print('Erro de rede/JSON: $e');
      return false;
    }
  }
}

// --- Simulação de File Picker ---

class DocumentPicker {
  Future<String?> pickDocument() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final simulatedFiles = [
      'consulta_exames.pdf',
      'laudo_medico.docx',
      'receita.pdf',
    ];
    final selectedFile =
        simulatedFiles[DateTime.now().millisecond % simulatedFiles.length];

    if (selectedFile.toLowerCase().endsWith('.pdf') ||
        selectedFile.toLowerCase().endsWith('.docx')) {
      return selectedFile;
    } else {
      return null;
    }
  }
}

// =========================================================================
// WIDGET PRINCIPAL (NewAppointmentScreen)
// =========================================================================

class NewAppointmentScreen extends StatefulWidget {
  final String authToken; 

  const NewAppointmentScreen({super.key, required this.authToken});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final AppointmentData _appointmentData = AppointmentData();
  late ApiService _apiService; 
  final DocumentPicker _documentPicker = DocumentPicker();
  int _currentStep = 1;
  bool _isSubmitting = false;

  final GlobalKey<FormState> _patientFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _travelFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authToken: widget.authToken); 
    // Inicializa o nome e sobrenome com valores padrão se necessário
    _appointmentData.nome = "João"; 
    _appointmentData.sobrenome = "Silva";
  }

  void _goToNextStep() {
    if (_currentStep == 1) {
      if (_patientFormKey.currentState!.validate()) {
        if (_appointmentData.enderecoSelecionado == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Selecione ou adicione um endereço.'), backgroundColor: Colors.orange));
          return;
        }

        _patientFormKey.currentState!.save();
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
      // Se estiver na tela 1, volta para Home
      Navigator.of(context).pop();
    }
  }

  // Lógica de Requisição Final
  Future<void> _submitAppointment() async {
    if (_currentStep == 2) {
      if (_appointmentData.dataSelecionada == null || _appointmentData.horaSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor, selecione a Data e o Horário.'),
            backgroundColor: Colors.red));
        return;
      }

      if (_travelFormKey.currentState!.validate()) {
        _travelFormKey.currentState!.save();

        setState(() {
          _isSubmitting = true;
        });

        // REQUISIÇÃO SENDO ENVIADA
        final success = await _apiService.sendAppointmentData(_appointmentData);
        // REQUISIÇÃO CONCLUÍDA

        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Agendamento enviado para análise!'), backgroundColor: Colors.green));
            // Navega para a tela de confirmação após o sucesso (substituindo a tela atual)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const VerificacaoConcluida()), 
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Erro ao enviar agendamento. Tente novamente.'), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _goToPreviousStep,
        ),
        title: const Text('Novo agendamento'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _currentStep == 1
                  ? PatientStep(
                      formKey: _patientFormKey,
                      data: _appointmentData,
                      apiService: _apiService,
                      onDataChanged: () => setState(() {}),
                    )
                  : TravelStep(
                      formKey: _travelFormKey,
                      data: _appointmentData,
                      apiService: _apiService,
                      documentPicker: _documentPicker,
                      onDataChanged: () => setState(() {}),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : (_currentStep == 1 ? _goToNextStep : _submitAppointment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                        _currentStep == 1 ? 'Próximo' : 'Concluir', 
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// COMPONENTES DE PASSO (Indicadores, PatientStep, TravelStep)
// =========================================================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    // Layout baseado nas imagens de 1/2 e 2/2
    return Row(
      children: [
        Expanded(
          child: Container(
            color: currentStep == 1 ? Colors.lightBlue.shade400 : Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: currentStep == 1 ? Colors.white : (currentStep > 1 ? Colors.green : Colors.grey.shade400),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: currentStep == 1 ? Colors.lightBlue.shade400 : (currentStep > 1 ? Colors.white : Colors.grey.shade600),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Paciente',
                  style: TextStyle(
                      color: currentStep == 1 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: currentStep == 2 ? Colors.lightBlue.shade400 : Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: currentStep == 2 ? Colors.white : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: currentStep == 2 ? Colors.lightBlue.shade400 : Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Viagem',
                  style: TextStyle(
                      color: currentStep == 2 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// PRIMEIRA TELA: PatientStep
// =========================================================================

class PatientStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AppointmentData data;
  final ApiService apiService;
  final VoidCallback onDataChanged;

  const PatientStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.apiService,
    required this.onDataChanged,
  });

  @override
  State<PatientStep> createState() => _PatientStepState();
}

class _PatientStepState extends State<PatientStep> {
  late Future<List<Endereco>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = widget.apiService.fetchUserAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: widget.data.nome,
            decoration: const InputDecoration(labelText: 'Nome'), // Baseado na imagem
            validator: (value) =>
                value!.isEmpty ? 'O nome é obrigatório' : null,
            onSaved: (value) => widget.data.nome = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.data.sobrenome,
            decoration: const InputDecoration(labelText: 'Sobrenome'), // Baseado na imagem
            validator: (value) =>
                value!.isEmpty ? 'O sobrenome é obrigatório' : null,
            onSaved: (value) => widget.data.sobrenome = value,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: widget.data.comAcompanhante,
                onChanged: (value) {
                  setState(() {
                    widget.data.comAcompanhante = value!;
                    widget.onDataChanged();
                  });
                },
              ),
              const Text('Com acompanhante'), // Baseado na imagem
            ],
          ),
          const SizedBox(height: 24),
          const Text('Endereço',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Nos informe o seu endereço',
              style: TextStyle(color: Colors.grey)), // Baseado na imagem
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FutureBuilder<List<Endereco>>(
              future: _addressesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erro ao carregar endereços: ${snapshot.error}'),
                  );
                }

                return _buildAddressOptions(snapshot.data ?? [], context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressOptions(List<Endereco> addresses, BuildContext context) {
    return Column(
      children: [
        ...addresses.map((address) {
          return RadioListTile<Endereco>(
            title: Text(address.toString()),
            value: address,
            groupValue: widget.data.enderecoSelecionado,
            onChanged: (Endereco? value) {
              setState(() {
                widget.data.enderecoSelecionado = value;
                widget.onDataChanged();
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
          );
        }).toList(),
        RadioListTile<Endereco?>(
          title: const Text('Adicionar um novo endereço'),
          value: null,
          groupValue: widget.data.enderecoSelecionado,
          onChanged: (Endereco? value) {
            setState(() {
              widget.data.enderecoSelecionado = null;
              widget.onDataChanged();
              // Simulação de navegação para Adicionar Endereço
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Simulação: Navegando para Adicionar Endereço.')));
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ],
    );
  }
}

// =========================================================================
// SEGUNDA TELA: TravelStep
// =========================================================================

class TravelStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AppointmentData data;
  final ApiService apiService;
  final DocumentPicker documentPicker;
  final VoidCallback onDataChanged;

  const TravelStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.apiService,
    required this.documentPicker,
    required this.onDataChanged,
  });

  @override
  State<TravelStep> createState() => _TravelStepState();
}

class _TravelStepState extends State<TravelStep> {
  late Future<List<HospitalMunicipio>> _hospitalsFuture;
  late Future<List<HospitalMunicipio>> _municipalitiesFuture;

  @override
  void initState() {
    super.initState();
    _hospitalsFuture = widget.apiService.fetchOptions('hospital');
    _municipalitiesFuture = widget.apiService.fetchOptions('municipio');
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.data.dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        widget.data.dataSelecionada = picked;
        widget.onDataChanged();
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.data.horaSelecionada ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        widget.data.horaSelecionada = picked;
        widget.onDataChanged();
      });
    }
  }

  Future<void> _pickDocument() async {
    final filePath = await widget.documentPicker.pickDocument();

    if (filePath != null) {
      setState(() {
        widget.data.documentoAnexado = filePath;
        widget.onDataChanged();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Documento anexado: $filePath'),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Formato inválido. Selecione PDF ou Word (.docx).'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo Hospital
          FutureBuilder<List<HospitalMunicipio>>(
            future: _hospitalsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Erro ao carregar hospitais: ${snapshot.error}');
              }
              final hospitals = snapshot.data ?? [];
              return DropdownButtonFormField<HospitalMunicipio>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hospital'), // Baseado na imagem
                value: widget.data.hospitalSelecionado,
                items: hospitals.map((h) {
                  return DropdownMenuItem(value: h, child: Text(h.nome));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    widget.data.hospitalSelecionado = value;
                    widget.onDataChanged();
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o hospital' : null,
              );
            },
          ),
          const SizedBox(height: 16),
          // Campo Município
          FutureBuilder<List<HospitalMunicipio>>(
            future: _municipalitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError) {
                return Text('Erro ao carregar municípios: ${snapshot.error}');
              }
              final municipalities = snapshot.data ?? [];
              return DropdownButtonFormField<HospitalMunicipio>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Município'), // Baseado na imagem
                value: widget.data.municipioSelecionado,
                items: municipalities.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m.nome));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    widget.data.municipioSelecionado = value;
                    widget.onDataChanged();
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o município' : null,
              );
            },
          ),
          const SizedBox(height: 16),
          // Campo Procedimento
          TextFormField(
            initialValue: widget.data.procedimento,
            decoration: const InputDecoration(labelText: 'Procedimento'), // Baseado na imagem
            onSaved: (value) => widget.data.procedimento = value,
            validator: (value) =>
                value!.isEmpty ? 'O procedimento é obrigatório' : null,
          ),
          const SizedBox(height: 16),
          // Campos Data e Horário
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data', // Baseado na imagem
                      hintText: 'Selecione a data',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.data.dataSelecionada == null
                              ? 'Data'
                              : '${widget.data.dataSelecionada!.day}/${widget.data.dataSelecionada!.month}/${widget.data.dataSelecionada!.year}',
                          style: DefaultTextStyle.of(context).style,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'horário', // Baseado na imagem
                      hintText: 'Selecione a hora',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.data.horaSelecionada == null
                              ? 'horário'
                              : widget.data.horaSelecionada!.format(context),
                          style: DefaultTextStyle.of(context).style,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Anexo de Documento
          const Text('Documento médico',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Anexe o documento da consulta',
              style: TextStyle(color: Colors.grey)), // Baseado na imagem
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDocument,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.data.documentoAnexado ??
                        'Clique aqui para anexar o documento', // Baseado na imagem
                    style: TextStyle(
                        color: widget.data.documentoAnexado != null
                            ? Colors.black
                            : Colors.grey.shade600),
                  ),
                  Icon(Icons.upload_file, color: Colors.blue.shade400),
                ],
              ),
            ),
          ),
          if (widget.data.documentoAnexado != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Anexado: ${widget.data.documentoAnexado}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
          const SizedBox(height: 24),
          // Campo Observação (Adicional)
          TextFormField(
            initialValue: widget.data.observacao,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação (Opcional)',
              hintText: 'Adicione qualquer informação relevante aqui...',
              border: OutlineInputBorder(),
            ),
            onSaved: (value) => widget.data.observacao = value,
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET PLACEHOLDER DE CONFIRMAÇÃO (VerificacaoConcluida)
// =========================================================================

// Crie este arquivo em 'satep/screen/VerificacaoConcluida.dart'
class VerificacaoConcluida extends StatelessWidget {
  const VerificacaoConcluida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendamento Concluído')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Agendamento enviado com sucesso!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Seu agendamento foi enviado para análise e você será notificado sobre a confirmação.',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Volta para a Home
              },
              child: const Text('Voltar para a Home'),
            ),
          ],
        ),
      ),
    );
  }
}