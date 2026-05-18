// lib/screens/main_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart' as sila;
import '../models/patient_model.dart';
import 'clinician_home.dart';
import 'patient_home.dart';
import 'patient_list_screen.dart';
import 'patient_step_1_screen.dart';
import 'patient_agenda_screen.dart';
import 'exercise_video_library_screen.dart';
import 'comparison_screen.dart';
import 'clinician_agenda.dart';
import 'klinisyen_profil_screen.dart';
import 'hasta_profil_screen.dart';
import 'ayarlar_screen.dart';
import 'yardim_destek_screen.dart';
import 'reports_screen.dart';
import 'hasta_egzersiz_screen.dart';
import 'notifications_screen.dart';
import 'empatica_screen.dart';
import '../services/notification_service.dart';

// ── Hasta Empatica Sayfası (alt bar index 2) ─────────────────────────────────
// kullaniciId → hastaId çekip kendi EmpaticaScreen'ini açar.
class _HastaEmpaticaPage extends StatefulWidget {
  const _HastaEmpaticaPage();

  @override
  State<_HastaEmpaticaPage> createState() => _HastaEmpaticaPageState();
}

class _HastaEmpaticaPageState extends State<_HastaEmpaticaPage> {
  static const String _sbUrl =
      'https://griteunvazwekosffmjo.supabase.co/rest/v1';
  static const String _sbKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
      'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
      'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  static const Color _kPrimary = Color(0xFF2563EB);

  bool _yukleniyor = true;
  String? _hata;
  Patient? _hasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _yukle());
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');
      if (kullaniciId == null) throw Exception('Kullanici bilgisi yok.');

      final res = await http.get(
        Uri.parse(
            '$_sbUrl/hastalar?kullaniciId=eq.$kullaniciId&select=hastaId&limit=1'),
        headers: {
          'apikey': _sbKey,
          'Authorization': 'Bearer $_sbKey',
          'Accept-Profile': 'neura',
        },
      );

      if (res.statusCode != 200) throw Exception('Hasta bilgisi alınamadı.');
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) throw Exception('Hasta kaydı bulunamadı.');

      final hastaId =
      (list.first as Map<String, dynamic>)['hastaId'] as int;

      setState(() {
        _hasta = Patient(
          hastaId: hastaId,
          kullaniciId: kullaniciId,
          ad: auth.user?.ad ?? '',
          soyad: auth.user?.soyad ?? '',
        );
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Center(
          child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_hata != null || _hasta == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_hata ?? 'Bilinmeyen hata',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _yukle,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    // EmpaticaScreen zaten kendi Scaffold'ını içeriyor,
    // ana Scaffold'a gömülü olduğu için appBar çakışmasını önlemek için
    // EmpaticaScreen'i doğrudan döndürüyoruz.
    return EmpaticaScreen(hasta: _hasta!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  final bool isClinician;
  const MainScreen({super.key, required this.isClinician});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadNotifications();
    });
  }

  Future<void> _loadUnreadNotifications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = int.tryParse(auth.user?.id ?? '');

    if (userId == null) return;

    final count = await NotificationService.getUnreadCount(userId);

    if (!mounted) return;

    setState(() {
      _unreadNotificationCount = count;
    });
  }

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
      PatientListScreen(
        klinisyenId: u?.klinisyenId,
      ),
      const PatientStep1Screen(),
      const ComparisonScreen(),
      const ReportsScreen(),
    ]
        : [
      const PatientHome(),
      const HastaEgzersizScreen(),
      // ── DEĞİŞİKLİK: "Gelişim" yerine hasta Empatica sayfası ──
      const _HastaEmpaticaPage(),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextDark),
        title: Text(
          _getTitle(_selectedIndex, widget.isClinician),
          style: const TextStyle(
              color: kTextDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: kTextDark),
                onPressed: () async {
                  final userId = int.tryParse(u?.id ?? '');
                  if (userId == null) return;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(kullaniciId: userId),
                    ),
                  );

                  _loadUnreadNotifications();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : _unreadNotificationCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.event_note_outlined, color: kTextDark),
            onPressed: () async { // ── async yaptık ──
              if (widget.isClinician) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClinicianAgenda()));
              } else {
                // ── YENİ: Gerçek hastaId'yi asenkron çekiyoruz ──
                final kullaniciId = int.tryParse(u?.id ?? '0') ?? 0;
                int realHastaId = 0;

                try {
                  final res = await http.get(
                    Uri.parse('https://griteunvazwekosffmjo.supabase.co/rest/v1/hastalar?kullaniciId=eq.$kullaniciId&select=hastaId&limit=1'),
                    headers: {
                      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU',
                      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU',
                      'Accept-Profile': 'neura',
                    },
                  );

                  if (res.statusCode == 200) {
                    final list = jsonDecode(res.body) as List;
                    if (list.isNotEmpty) {
                      realHastaId = (list.first as Map<String, dynamic>)['hastaId'] as int;
                    }
                  }
                } catch (e) {
                  debugPrint('Ajanda için hastaId çekilemedi: $e');
                }

                if (!context.mounted) return;

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PatientAgendaScreen(
                          patient: sila.Patient(
                            hastaId: realHastaId, // Artık veritabanından gelen 30 gidiyor!
                            kullaniciId: kullaniciId,
                            ad: u?.ad ?? '',
                            soyad: u?.soyad ?? '',
                            tani: '',
                            durum: 'Aktif Hasta',
                            degerlendirmeler: [],
                          ),
                        )));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── DRAWER ──────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Profil başlığı
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
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: u?.ad.isNotEmpty == true
                          ? Text(u!.ad[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor))
                          : const Icon(Icons.person,
                          size: 36, color: kTextGrey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    u?.fullName ?? 'Kullanıcı',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
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

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Profilim ──────────────────────────────
                  ListTile(
                    leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.person_outline,
                            color: primaryColor, size: 20)),
                    title: const Text('Profilim',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFCBD5E1)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => widget.isClinician
                                  ? const KlinisyenProfilScreen()
                                  : const HastaProfilScreen()));
                    },
                  ),

                  // ── Ayarlar ───────────────────────────────
                  ListTile(
                    leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: kTextGrey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.settings_outlined,
                            color: kTextGrey, size: 20)),
                    title: const Text('Ayarlar',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFCBD5E1)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AyarlarScreen()));
                    },
                  ),

                  const SizedBox(height: 4),

                  // ── Yardım ve Destek ──────────────────────
                  ListTile(
                    leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: kTextGrey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.help_outline,
                            color: kTextGrey, size: 20)),
                    title: const Text('Yardım ve Destek',
                        style: TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFCBD5E1)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const YardimDestekScreen()));
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── Çıkış Yap ────────────────────────────────────
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
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
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

      // ── BOTTOM NAV ───────────────────────────────────────────
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
          onTap: (i) => setState(() => _selectedIndex = i),
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
                icon: Icon(Icons.compare_arrows_outlined),
                activeIcon: Icon(Icons.compare_arrows),
                label: 'Karşılaştır'),
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
            // ── DEĞİŞİKLİK: Gelişim → Empatica ──────────
            BottomNavigationBarItem(
                icon: Icon(Icons.monitor_heart_outlined),
                activeIcon: Icon(Icons.monitor_heart),
                label: 'Empatica'),
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
          return 'Egzersizlerim';
        case 2:
        // ── DEĞİŞİKLİK: başlık da güncellendi ──
          return 'Empatica';
        default:
          return 'NeuraApp';
      }
    }
  }
}