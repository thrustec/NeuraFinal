// lib/screens/patient_home.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient_model.dart';
import 'patient_agenda_screen.dart';
import 'telerehab_patient_screen.dart';
import 'notifications_screen.dart';
import 'hasta_egzersiz_screen.dart';
import 'empatica_screen.dart';
import '../models/patient.dart' as sila;

const String _kSbUrl = 'https://griteunvazwekosffmjo.supabase.co/rest/v1';
const String _kSbKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
    'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
    'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _sbHeaders() => {
  'apikey': _kSbKey,
  'Authorization': 'Bearer $_kSbKey',
  'Accept-Profile': 'neura',
};

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HOŞGELDİN KARTI ────────────────────────────────────
          _buildWelcomeCard(
            auth.user?.fullName ?? 'Değerli Hastamız',
            auth.user?.avatarUrl,
          ),

          const SizedBox(height: 28),

          // ── 2. YAKLAŞAN PLANLARIM ──────────────────────────────────
          _buildSectionHeader('Yaklaşan Planlarım'),
          const SizedBox(height: 12),
          _buildNextAppointmentCard(context, auth),

          const SizedBox(height: 24),

          // ── 3. BUGÜNKÜ GÖREVLERİM ─────────────────────────────────
          _buildSectionHeader('Bugünkü Görevlerim'),
          const SizedBox(height: 12),
          _buildDailyExerciseCard(context),

          const SizedBox(height: 28),

          // ── 4. HIZLI İŞLEMLER (Grid) ──────────────────────────────
          _buildSectionHeader('Hızlı İşlemler'),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(context, auth),
        ],
      ),
    );
  }

  // ── HOŞGELDİN KARTI ───────────────────────────────────────────────────────

  Widget _buildWelcomeCard(String userName, String? avatarUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol: metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoşgeldin 👋',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_heart,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Hasta',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sağ: avatar
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            )
                : CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                userName.isNotEmpty
                    ? userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BÖLÜM BAŞLIĞI ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  // ── YAKLAŞAN RANDEVU KARTI ────────────────────────────────────────────────

  Widget _buildNextAppointmentCard(
      BuildContext context, AuthProvider auth) {
    return InkWell(
      onTap: () {
        final u = auth.user;
        if (u != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientAgendaScreen(
                  patient: sila.Patient(
                    hastaId: int.tryParse(u.id) ?? 0,
                    kullaniciId: int.tryParse(u.id) ?? 0,
                    ad: u.ad,
                    soyad: u.soyad,
                    tani: '',
                    durum: 'Aktif Hasta',
                    degerlendirmeler: [],
                  ),
                ),
              ));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month_outlined,
                  color: _primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Klinik Değerlendirme',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Yarın, 14:30 - Dr. Akhan',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
      ),
    );
  }

  // ── GÜNLÜK GÖREV KARTI ────────────────────────────────────────────────────

  Widget _buildDailyExerciseCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_calls_outlined,
                color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Günlük Telerehabilisasyon',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text('Henüz tamamlanmadı (0/3)',
                    style: TextStyle(
                        color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TelerehabPatientScreen())),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: _primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── HIZLI İŞLEMLER — 3 KOLONLU GRİD ──────────────────────────────────────

  Widget _buildQuickActionsGrid(BuildContext context, AuthProvider auth) {
    final items = [
      _QuickActionItem(
        icon: Icons.video_camera_front_outlined,
        label: 'Toplantılar',
        color: Colors.purple,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TelerehabPatientScreen())),
      ),
      _QuickActionItem(
        icon: Icons.monitor_heart_outlined,
        label: 'Empatica',
        color: const Color(0xFF0F766E),
        onTap: () => _navigateToEmpatica(context, auth),
      ),
      _QuickActionItem(
        icon: Icons.notifications_outlined,
        label: 'Bildirimler',
        color: const Color(0xFFF59E0B),
        onTap: () {
          final userId = int.tryParse(auth.user?.id ?? '');
          if (userId == null) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      NotificationsScreen(kullaniciId: userId)));
        },
      ),
      _QuickActionItem(
        icon: Icons.event_note_outlined,
        label: 'Ajanda',
        color: const Color(0xFF2563EB),
        onTap: () {
          final u = auth.user;
          if (u == null) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PatientAgendaScreen(
                    patient: sila.Patient(
                      hastaId: int.tryParse(u.id) ?? 0,
                      kullaniciId: int.tryParse(u.id) ?? 0,
                      ad: u.ad,
                      soyad: u.soyad,
                      tani: '',
                      durum: 'Aktif Hasta',
                      degerlendirmeler: [],
                    ),
                  )));
        },
      ),
      _QuickActionItem(
        icon: Icons.fitness_center_outlined,
        label: 'Egzersiz',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const HastaEgzersizScreen())),
      ),
    ];

    const int crossAxisCount = 3;
    final int rowCount = (items.length / crossAxisCount).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        final start = rowIndex * crossAxisCount;
        final end = (start + crossAxisCount).clamp(0, items.length);
        final rowItems = items.sublist(start, end);

        return Padding(
          padding: EdgeInsets.only(
              bottom: rowIndex < rowCount - 1 ? 12 : 0),
          child: Row(
            children: [
              for (int i = 0; i < rowItems.length; i++) ...[
                Expanded(child: _buildGridTile(rowItems[i])),
                if (i < rowItems.length - 1) const SizedBox(width: 12),
              ],
              // Son satırda eksik hücreleri boş Expanded ile doldur
              for (int i = rowItems.length; i < crossAxisCount; i++) ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGridTile(_QuickActionItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: item.color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPATİCA NAVİGASYON ───────────────────────────────────────────────────

  Future<void> _navigateToEmpatica(
      BuildContext context, AuthProvider auth) async {
    final kullaniciId = int.tryParse(auth.user?.id ?? '');
    if (kullaniciId == null) return;

    try {
      final res = await http.get(
        Uri.parse(
            '$_kSbUrl/hastalar?kullaniciId=eq.$kullaniciId&select=hastaId&limit=1'),
        headers: _sbHeaders(),
      );

      if (res.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hasta bilgisi alınamadı.')));
        }
        return;
      }

      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hasta kaydı bulunamadı.')));
        }
        return;
      }

      final hastaId =
      (list.first as Map<String, dynamic>)['hastaId'] as int;
      final hasta = Patient(
        hastaId: hastaId,
        kullaniciId: kullaniciId,
        ad: auth.user?.ad ?? '',
        soyad: auth.user?.soyad ?? '',
      );

      if (context.mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EmpaticaScreen(hasta: hasta)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}

// ── Veri modeli ───────────────────────────────────────────────────────────────

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}