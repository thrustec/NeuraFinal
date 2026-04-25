import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart' as sila;
import 'clinician_home.dart';
import 'patient_home.dart';
import 'patient_list_screen.dart';
import 'patient_step_1_screen.dart';
import 'patient_agenda_screen.dart';
import 'telerehab_patient_screen.dart';
import 'comparison_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isClinician;

  const MainScreen({super.key, required this.isClinician});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final u = auth.user;

    final primaryColor = widget.isClinician
        ? const Color(0xFF0F766E)
        : const Color(0xFF2563EB);

    final List<Widget> pages = widget.isClinician
        ? [
      const ClinicianHome(),
      const PatientListScreen(),
      const PatientStep1Screen(),
      const ComparisonScreen(),
      const Center(child: Text('Raporlar')),
    ]
        : [
      const PatientHome(),
      u != null
          ? PatientAgendaScreen(
        patient: sila.Patient(
          hastaId: int.tryParse(u.id) ?? 0,
          kullaniciId: int.tryParse(u.id) ?? 0,
          ad: u.ad,
          soyad: u.soyad,
          tani: '',
          durum: 'Aktif Hasta',
          degerlendirmeler: [],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
      const TelerehabPatientScreen(),
      const ComparisonScreen(),
      const Center(child: Text('Gelişim')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          _getTitle(_selectedIndex, widget.isClinician),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor,
              child: Text(
                u?.ad.isNotEmpty == true ? u!.ad[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    u?.fullName ?? 'Kullanıcı',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.isClinician ? 'Klinisyen' : 'Hasta',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Yardım ve Destek'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: widget.isClinician
            ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Hastalar'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), label: 'Kayıt'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Değerlendir'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Raporlar'),
        ]
            : const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Ajanda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Egzersiz'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Değerlendir'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Gelişim'),
        ],
      ),
    );
  }

  String _getTitle(int index, bool isClinician) {
    if (isClinician) {
      switch (index) {
        case 0: return 'Ana Sayfa';
        case 1: return 'Hastalar';
        case 2: return 'Hasta Kaydı';
        case 3: return 'Değerlendir';
        case 4: return 'Raporlar';
        default: return 'NeuraApp';
      }
    } else {
      switch (index) {
        case 0: return 'Ana Sayfa';
        case 1: return 'Ajandam';
        case 2: return 'Telerehabilitasyon';
        case 3: return 'Karşılaştırma';
        case 4: return 'Gelişimim';
        default: return 'NeuraApp';
      }
    }
  }
}