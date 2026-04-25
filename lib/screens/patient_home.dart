import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'comparison_screen.dart';
import 'patient_agenda_screen.dart';
import 'telerehab_patient_screen.dart';
import '../models/patient.dart' as sila;

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  // Hasta teması için belirlediğimiz modern Royal Mavi
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
          _buildWelcomeCard(auth.user?.fullName ?? 'Değerli Hastamız'),

          const SizedBox(height: 28),

          // ── 2. SIRADAKİ RANDEVUM (Aksiyon Kartı) ──────────────────
          _buildSectionHeader('Yaklaşan Planlarım'),
          const SizedBox(height: 12),
          _buildNextAppointmentCard(context, auth),

          const SizedBox(height: 24),

          // ── 3. GÜNÜN EGZERSİZİ (Aksiyon Kartı) ────────────────────
          _buildSectionHeader('Bugünkü Görevlerim'),
          const SizedBox(height: 12),
          _buildDailyExerciseCard(context),

          const SizedBox(height: 28),

          // ── 4. HIZLI İŞLEMLER (Yatay Kaydırılabilir Menü) ─────────
          _buildSectionHeader('Hızlı İşlemler'),
          const SizedBox(height: 12),
          _buildQuickActionsRow(context),
        ],
      ),
    );
  }

  // ─── YARDIMCI WIDGET'LAR VE MODÜLLER ──────────────────────────────────────

  Widget _buildWelcomeCard(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, Color(0xFF1D4ED8)], // Hafif bir mavi geçişi
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_heart, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Durum: Stabil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildNextAppointmentCard(BuildContext context, AuthProvider auth) {
    return InkWell(
      onTap: () {
        final u = auth.user;
        if (u != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PatientAgendaScreen(
              patient: sila.Patient(
                hastaId: int.tryParse(u.id) ?? 0,
                kullaniciId: int.tryParse(u.id) ?? 0,
                ad: u.ad, soyad: u.soyad,
                tani: '', durum: 'Aktif Hasta',
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
                color: const Color(0xFFFFF7ED), // Hafif turuncu arka plan
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month, color: Color(0xFFEA580C), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Klinik Değerlendirme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Yarın, 14:30 - Dr. Akhan', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyExerciseCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelerehabPatientScreen())),
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
                color: const Color(0xFFF0FDF4), // Hafif yeşil arka plan
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Günlük Telerehabilitasyon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Henüz tamamlanmadı (0/3)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _QuickActionTile(
            icon: Icons.assignment_outlined,
            label: 'Değerlendirmeler',
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparisonScreen())),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.monitor_heart_outlined,
            label: 'Sensör Verileri',
            color: Colors.teal,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.video_camera_front_outlined,
            label: 'Toplantılar',
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelerehabPatientScreen())),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu modül yakında eklenecek!'), duration: Duration(seconds: 2)),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
              ]),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}