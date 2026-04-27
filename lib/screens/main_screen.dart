import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart' as sila;
import 'clinician_home.dart';
import 'patient_home.dart';
import 'patient_list_screen.dart';
import 'patient_step_1_screen.dart';
import 'patient_agenda_screen.dart';
import 'exercise_video_library_screen.dart';
import 'comparison_screen.dart';
import 'clinician_agenda.dart';

class MainScreen extends StatefulWidget {
  final bool isClinician;

  const MainScreen({super.key, required this.isClinician});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final u = auth.user;

    final primaryColor = widget.isClinician
        ? const Color(0xFF0F766E)
        : const Color(0xFF2563EB);

    const Color kBackground = Color(0xFFF8F9FC);
    const Color kTextDark = Color(0xFF1E293B);
    const Color kTextGrey = Color(0xFF64748B);

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
      const ExerciseVideoLibraryScreen(),
      const Center(child: Text('Gelişim')),
    ];

    // Drawer başlığında gösterilecek isim
    final String drawerName = widget.isClinician
        ? (u?.displayName ?? 'Klinisyen')
        : (u?.fullName ?? 'Kullanıcı');

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextDark),
        title: Text(
          _getTitle(_selectedIndex, widget.isClinician),
          style: const TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: kTextDark),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.event_note_outlined, color: kTextDark),
            onPressed: () {
              if (widget.isClinician) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClinicianAgenda()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientAgendaScreen(
                      patient: sila.Patient(
                        hastaId: int.tryParse(u?.id ?? '0') ?? 0,
                        kullaniciId: int.tryParse(u?.id ?? '0') ?? 0,
                        ad: u?.ad ?? '',
                        soyad: u?.soyad ?? '',
                        tani: '',
                        durum: 'Aktif Hasta',
                        degerlendirmeler: [],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, bottom: 24, left: 20, right: 20),
              decoration: BoxDecoration(
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child:
                      Icon(Icons.person, size: 36, color: kTextGrey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    drawerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      widget.isClinician
                          ? 'Klinisyen Hesabı'
                          : 'Hasta Hesabı',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline,
                        color: kTextGrey),
                    title: const Text('Profilim',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    onTap: () {},
                  ),
                  ListTile(
                    leading:
                    const Icon(Icons.settings_outlined, color: kTextGrey),
                    title: const Text('Ayarlar',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    onTap: () {},
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        value: _isDarkMode,
                        onChanged: (bool value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                        secondary: Icon(
                          _isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode_outlined,
                          color: _isDarkMode
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFF59E0B),
                        ),
                        title: Text(
                          _isDarkMode ? 'Karanlık Tema' : 'Açık Tema',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kTextDark),
                        ),
                        activeColor: primaryColor,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  ListTile(
                    leading:
                    const Icon(Icons.help_outline, color: kTextGrey),
                    title: const Text('Yardım ve Destek',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            SafeArea(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout,
                      color: Colors.red, size: 20),
                ),
                title: const Text('Çıkış Yap',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          elevation: 0,
          items: widget.isClinician
              ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                activeIcon: Icon(Icons.people_alt),
                label: 'Hastalar'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_add_outlined),
                activeIcon: Icon(Icons.person_add),
                label: 'Kayıt'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Değerlendir'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Raporlar'),
          ]
              : const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa'),
            BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon: Icon(Icons.fitness_center),
                label: 'Egzersiz'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights),
                label: 'Gelişim'),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index, bool isClinician) {
    if (isClinician) {
      switch (index) {
        case 0:
          return 'Ana Sayfa';
        case 1:
          return 'Hastalar';
        case 2:
          return 'Hasta Kaydı';
        case 3:
          return 'Değerlendir';
        case 4:
          return 'Raporlar';
        default:
          return 'NeuraApp';
      }
    } else {
      switch (index) {
        case 0:
          return 'Ana Sayfa';
        case 1:
          return 'Egzersiz Kütüphanesi';
        case 2:
          return 'Gelişimim';
        default:
          return 'NeuraApp';
      }
    }
  }
}
