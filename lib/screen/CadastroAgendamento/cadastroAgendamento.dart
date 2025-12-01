// lib/screen/CadastroAgendamento/cadastroAgendamento.dart 

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:satep/screen/Navbar/home.dart'; 

// =========================================================================
// CONFIGURAÇÃO DA API E MODELOS
// =========================================================================

// Endereços do backend
const String BASE_URL = 'https://backend-satep-6viy.onrender.com'; 
const String ADDRESS_ENDPOINT = '/paciente/enderecos';
const String OPTIONS_ENDPOINT = '/hospitais'; 
const String APPOINTMENT_ENDPOINT = '/agendamento/novo'; 
const String ME_ENDPOINT = '/paciente/me'; 

// --- Modelos de Dados (Endereco, PacienteMeData, HospitalMunicipio) ---

class Endereco {
  final String logradouro;
  final String numero;
  final String bairro;

  Endereco({
    required this.logradouro,
    required this.numero,
    required this.bairro,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      // Tentando capturar diferentes nomes de campo (para endereços e me_endpoint)
      logradouro: json['nm_endereco'] as String? ?? json['logradouro'] as String,
      numero: json['nr_endereco'].toString(), 
      bairro: json['nm_bairro'] as String? ?? json['bairro'] as String,
    );
  }

  @override
  String toString() => '$logradouro, $numero - $bairro';
}

class PacienteMeData {
  final String nome;
  final String sobrenome;
  final Endereco enderecoPrincipal; 

  PacienteMeData({
    required this.nome,
    required this.sobrenome,
    required this.enderecoPrincipal,
  });
  
  factory PacienteMeData.fromPacienteJson(Map<String, dynamic> json) {
    final endereco = Endereco(
      logradouro: json['nm_endereco'] ?? '',
      numero: json['nr_endereco']?.toString() ?? '',
      bairro: json['nm_bairro'] ?? '',
    );
    
    String nomeCompleto = json['nome'] as String? ?? 'Paciente';
    List<String> partes = nomeCompleto.split(' ');
    String nome = partes.isNotEmpty ? partes.first : nomeCompleto;
    String sobrenome = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    
    return PacienteMeData(
      nome: nome,
      sobrenome: sobrenome,
      enderecoPrincipal: endereco,
    );
  }
}

class HospitalMunicipio {
  final String id;
  final String nomeHospital;
  final String nomeMunicipio;

  HospitalMunicipio({
    required this.id,
    required this.nomeHospital,
    required this.nomeMunicipio,
  });

  factory HospitalMunicipio.fromJson(Map<String, dynamic> json) {
    return HospitalMunicipio(
      id: json['id']?.toString() ?? '-1',
      nomeHospital: json['nome'] ?? 'Hospital Indisponível',
      nomeMunicipio: json['municipio'] ?? 'Município não informado',
    );
  }

  @override
  String toString() => "$nomeHospital - $nomeMunicipio";
}


class AppointmentData {
  String? nome;
  String? sobrenome;
  bool comAcompanhante = false;
  Endereco? enderecoSelecionado;
  
  HospitalMunicipio? hospitalSelecionado;
  HospitalMunicipio? municipioSelecionado;
  String? procedimento;
  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  String? documentoAnexado; 
  String? observacao;

  // Mapeamento para snake_case (padrão FastAPI/Python)
  Map<String, dynamic> toJson() => {
        'hospital_id': int.tryParse(hospitalSelecionado?.id ?? '') ?? 0, 
        'data_agendamento': dataSelecionada != null 
            ? DateFormat('yyyy-MM-dd').format(dataSelecionada!) 
            : null,
        'hora_agendamento': horaSelecionada != null 
            ? '${horaSelecionada!.hour.toString().padLeft(2, '0')}:${horaSelecionada!.minute.toString().padLeft(2, '0')}:00' 
            : null,
        
        'nm_endereco': enderecoSelecionado?.logradouro,
        'nr_endereco': enderecoSelecionado?.numero,
        'nm_bairro': enderecoSelecionado?.bairro,
        'nm_cidade': municipioSelecionado?.nomeMunicipio, // Mapeado para nm_cidade
        
        'ds_agendamento': observacao,
        
        'procedimento': procedimento,
      };
}

// --- Serviços de Requisições HTTP ---

class ApiService {
  final String authToken; // Token passado na inicialização

  ApiService({required this.authToken});

  // GERA O HEADER COM O TOKEN PARA TODAS AS REQUISIÇÕES
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken', 
  };
  
  // Requisição: /paciente/me
  Future<PacienteMeData?> fetchPatientMe() async {
    final uri = Uri.parse('$BASE_URL$ME_ENDPOINT');
    
    if (authToken.isEmpty) {
        // Simulação se token estiver vazio (apenas para fallback de teste)
        return PacienteMeData.fromPacienteJson({
            'nome': 'João Silva', 
            'nm_endereco': 'Av. Principal',
            'nr_endereco': 100,
            'nm_bairro': 'Centro',
        });
    }

    try {
      final response = await http.get(uri, headers: _headers); // Usa _headers
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(utf8Body);
        return PacienteMeData.fromPacienteJson(data);
      } else {
        print('Falha ao carregar dados do paciente: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de rede ao buscar /paciente/me: $e');
      return null;
    }
  }

  // Requisição: /paciente/enderecos
  Future<List<Endereco>> fetchUserAddresses() async {
    final uri = Uri.parse('$BASE_URL$ADDRESS_ENDPOINT');
    
    if (authToken.isEmpty) {
        return [
            Endereco(logradouro: 'Av. Nossa Sra. de Fátima', numero: '204', bairro: 'Balneario A'),
            Endereco(logradouro: 'Av. Monteiro Lobato', numero: '12092', bairro: 'Balneário B'),
        ];
    }
    
    try {
      final response = await http.get(uri, headers: _headers); // Usa _headers
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(utf8Body);
        return data.map((item) => Endereco.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return []; 
    }
  }

  Future<List<HospitalMunicipio>> fetchOptions() async {
  final uri = Uri.parse('$BASE_URL$OPTIONS_ENDPOINT');
  print('🛰️ Buscando hospitais em: $uri');
  print('🔑 Token enviado: $authToken');
  print('📦 Headers: $_headers');

  if (authToken.isEmpty) {
    print('⚠️ Token vazio — retornando lista simulada.');
    return [
      HospitalMunicipio(id: '1', nomeHospital: 'Hospital Central', nomeMunicipio: 'Mongaguá'),
      HospitalMunicipio(id: '2', nomeHospital: 'Clínica São Judas', nomeMunicipio: 'Itanhaém'),
    ];
  }

  try {
    final response = await http.get(uri, headers: _headers);
    print('Resposta (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
       final utf8Body = utf8.decode(response.bodyBytes);
       final List<dynamic> data = jsonDecode(utf8Body);
       return data.map((item) => HospitalMunicipio.fromJson(item)).toList();
    } else {
      print('Falha ao carregar hospitais: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Erro ao buscar hospitais: $e');
    return [];
  }
}

  // Requisição: /agendamento/novo
  Future<bool> sendAppointmentData(AppointmentData data) async {
    final uri = Uri.parse('$BASE_URL$APPOINTMENT_ENDPOINT');
    
    final payload = data.toJson();
    print("Enviando Agendamento: ${jsonEncode(payload)}");
    
    if (authToken.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        return true; 
    }

    try {
      final response = await http.post(
        uri,
        headers: _headers, // Usa _headers
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Agendamento criado com sucesso! Status: ${response.statusCode}');
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

// --- Simulação de File Picker (Implementação Faltante) ---

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
  final String authToken; // <--- RECEBE O TOKEN

  const NewAppointmentScreen({super.key, required this.authToken});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final AppointmentData _appointmentData = AppointmentData();
  // Inicialização da API Service com o token recebido
  late ApiService _apiService; // <--- Inicializada no initState
  final DocumentPicker _documentPicker = DocumentPicker(); 
  int _currentStep = 1;
  bool _isSubmitting = false;

  final GlobalKey<FormState> _patientFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _travelFormKey = GlobalKey<FormState>();
  
  late Future<PacienteMeData?> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    // INICIALIZAÇÃO DA API SERVICE COM O TOKEN
    _apiService = ApiService(authToken: widget.authToken); 
    _patientDataFuture = _apiService.fetchPatientMe();
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
      Navigator.of(context).pop();
    }
  }

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

        final success = await _apiService.sendAppointmentData(_appointmentData);

        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agendamento enviado para análise!'),
            backgroundColor: Colors.green));

            Navigator.of(context).pushReplacement(
            MaterialPageRoute(
            builder: (context) => VerificacaoConcluida(authToken: widget.authToken),
            ),
          );
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
            child: FutureBuilder<PacienteMeData?>(
              future: _patientDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                   return Center(child: Text('Erro ao carregar dados do paciente: ${snapshot.error}'));
                }
                
                if (snapshot.data != null) {
                    _appointmentData.nome = snapshot.data!.nome;
                    _appointmentData.sobrenome = snapshot.data!.sobrenome;
                    
                    if (_appointmentData.enderecoSelecionado == null) {
                        _appointmentData.enderecoSelecionado = snapshot.data!.enderecoPrincipal;
                    }
                }

                return SingleChildScrollView(
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
                );
              },
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
// COMPONENTES DE PASSO (StepIndicator)
// =========================================================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
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
          // Nome
          TextFormField(
            initialValue: widget.data.nome,
            decoration: const InputDecoration(labelText: 'Nome'), 
            validator: (value) =>
                value!.isEmpty ? 'O nome é obrigatório' : null,
            onSaved: (value) => widget.data.nome = value,
          ),
          const SizedBox(height: 16),
          // Sobrenome
          TextFormField(
            initialValue: widget.data.sobrenome,
            decoration: const InputDecoration(labelText: 'Sobrenome'), 
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
              const Text('Com acompanhante'), 
            ],
          ),
          const SizedBox(height: 24),
          const Text('Endereço',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Nos informe o seu endereço',
              style: TextStyle(color: Colors.grey)), 
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

                List<Endereco> addresses = snapshot.data ?? [];
                if (widget.data.enderecoSelecionado != null && 
                    !addresses.any((e) => e.toString() == widget.data.enderecoSelecionado.toString())) {
                    
                    addresses.insert(0, widget.data.enderecoSelecionado!);
                }


                return _buildAddressOptions(addresses, context);
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
  late Future<List<HospitalMunicipio>> _hospitaisFuture;

  @override
  void initState() {
    super.initState();
    _hospitaisFuture = widget.apiService.fetchOptions(); // apenas uma chamada
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.data.dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
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
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
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
            future: _hospitaisFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  (snapshot.data == null || snapshot.data!.isEmpty)) {
                return const Text(
                  'Erro ao carregar hospitais. Verifique sua autenticação (Token).',
                  style: TextStyle(color: Colors.red),
                );
              }

              final hospitais = snapshot.data ?? [];

              return DropdownButtonFormField<HospitalMunicipio>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hospital'),
                value: widget.data.hospitalSelecionado,
                items: hospitais.map((h) {
                  return DropdownMenuItem(
                    value: h,
                    child: Text('${h.nomeHospital} - ${h.nomeMunicipio}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    widget.data.hospitalSelecionado = value;
                    widget.data.municipioSelecionado = value; // já vem junto
                    widget.onDataChanged();
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o hospital' : null,
              );
            },
          ),
          const SizedBox(height: 16),

          // Campo Procedimento
          TextFormField(
            initialValue: widget.data.procedimento,
            decoration: const InputDecoration(labelText: 'Procedimento'),
            onSaved: (value) => widget.data.procedimento = value,
            validator: (value) =>
                value!.isEmpty ? 'O procedimento é obrigatório' : null,
          ),
          const SizedBox(height: 16),

          // Campos de Data e Horário
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data *',
                      hintText: 'Selecione a data',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.data.dataSelecionada == null
                              ? 'Data'
                              : DateFormat('dd/MM/yyyy')
                                  .format(widget.data.dataSelecionada!),
                          style: DefaultTextStyle.of(context).style,
                        ),
                        const Icon(Icons.calendar_today, size: 20),
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
                      labelText: 'Horário *',
                      hintText: 'Selecione a hora',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.data.horaSelecionada == null
                              ? 'Horário'
                              : widget.data.horaSelecionada!.format(context),
                          style: DefaultTextStyle.of(context).style,
                        ),
                        const Icon(Icons.access_time, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Anexo de Documento
          const Text('Informações adicionais',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          // Campo Observação
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

class VerificacaoConcluida extends StatelessWidget {
  final String authToken;

  const VerificacaoConcluida({super.key, required this.authToken});

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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(authToken: authToken),
                  ),
                );
              },
              child: const Text('Voltar para a Home'),
            ),
          ],
        ),
      ),
    );
  }
}