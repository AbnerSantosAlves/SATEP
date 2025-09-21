import 'package:flutter/material.dart';
import 'package:satep/screen/CadastroAgendamento/tela1.dart';
import 'package:satep/screen/Navbar/configuracaoHome.dart';
import 'package:satep/screen/Navbar/historicoAgendamento.dart';
import 'package:satep/screen/infoAgendamento.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    _HomePageContent(),
    Historicoagendamento(),
    Configuracaohome(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NovoAgendamentoScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Histórico"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        
        


        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Olá, pessoa!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.notifications_outlined, size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Caso queira se familiarizar com os nossos serviços,\n"
                    "preparamos um vídeo explicativo.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Veja agora"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Busque seus agendamentos aqui",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip("Agendados", true),
                  _buildFilterChip("Em análise", false),
                  _buildFilterChip("Recusados", false),
                  _buildFilterChip("Confirmados", false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildAppointmentCard(
                    context,
                    "Hospital das Clínicas",
                    "Agendamento para 25/07",
                    "Exame de Sangue",
                    "Agendado",
                    Icons.local_hospital,
                  ),
                  _buildAppointmentCard(
                    context,
                    "Hospital das Clínicas",
                    "Agendamento para 29/07",
                    "Dermatologista",
                    "Agendado",
                    Icons.health_and_safety,
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


Widget _buildFilterChip(String label, bool selected) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
    ),
  );
}

Widget _buildAppointmentCard(
    BuildContext context,
    String title,
    String subtitle,
    String detail,
    String status,
    IconData icon) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: Icon(icon, size: 40, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const Infoagendamento(),
        );
      },
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Text(detail),
          Text(
            status,
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}