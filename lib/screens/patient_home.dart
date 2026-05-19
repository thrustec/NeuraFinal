import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart' as sila;
import '../models/patient_model.dart' as patient_model;
import 'telerehab_patient_screen.dart';
import 'hasta_egzersiz_screen.dart';
import 'patient_agenda_screen.dart';
import 'notifications_screen.dart';
import 'empatica_screen.dart';
import '../services/supabase_service.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  bool _isLoadingTodayMeetings = true;
  List<Map<String, dynamic>> _todayMeetings = [];

  bool _isLoadingTodayExercises = true;
  List<Map<String, dynamic>> _todayExercises = [];

  @override
  void initState() {
    super.initState();
    _loadTodayMeetings();
    _loadTodayExercises();
  }

  Future<int?> _getCurrentPatientId() async {
    final auth = context.read<AuthProvider>();
    final kullaniciId = int.tryParse(auth.user?.id ?? '');

    if (kullaniciId == null) {
      return null;
    }

    final patientResponse = await SupabaseService.client
        .schema('neura')
        .from('hastalar')
        .select('hastaId')
        .eq('kullaniciId', kullaniciId)
        .maybeSingle();

    if (patientResponse == null) {
      return null;
    }

    return patientResponse['hastaId'] as int?;
  }

  Future<void> _loadTodayMeetings() async {
    try {
      final hastaId = await _getCurrentPatientId();

      if (hastaId == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingTodayMeetings = false;
          _todayMeetings = [];
        });
        return;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final meetingsResponse = await SupabaseService.client
          .schema('neura')
          .from('toplantilar')
          .select(
        'toplantiId, hastaId, baslik, baslangicZamani, bitisZamani, durum',
      )
          .eq('hastaId', hastaId)
          .gte('baslangicZamani', todayStart.toIso8601String())
          .lt('baslangicZamani', tomorrowStart.toIso8601String())
          .neq('durum', 'İptal Edildi')
          .order('baslangicZamani', ascending: true);

      if (!mounted) return;

      setState(() {
        _todayMeetings =
        List<Map<String, dynamic>>.from(meetingsResponse);
        _isLoadingTodayMeetings = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTodayMeetings = false;
        _todayMeetings = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bugünkü toplantılar yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loadTodayExercises() async {
    try {
      final hastaId = await _getCurrentPatientId();

      if (hastaId == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingTodayExercises = false;
          _todayExercises = [];
        });
        return;
      }

      final now = DateTime.now();
      final todayText =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final exercisesResponse = await SupabaseService.client
          .schema('neura')
          .from('egzersizAtalari')
          .select(
        'egzersizAtamaId, hastaId, egzersizAdi, atamaTarihi, tamamlandiMi',
      )
          .eq('hastaId', hastaId)
          .eq('atamaTarihi', todayText)
          .order('egzersizAtamaId', ascending: true);

      if (!mounted) return;

      setState(() {
        _todayExercises =
        List<Map<String, dynamic>>.from(exercisesResponse);
        _isLoadingTodayExercises = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTodayExercises = false;
        _todayExercises = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bugünkü egzersizler yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openPatientAgenda() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final hastaId = await _getCurrentPatientId();

    if (!mounted) return;

    if (user == null || hastaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajanda bilgileri açılırken hata oluştu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAgendaScreen(
          patient: sila.Patient(
            hastaId: hastaId,
            kullaniciId: int.tryParse(user.id) ?? 0,
            ad: user.ad,
            soyad: user.soyad,
            tani: '',
            durum: 'Aktif Hasta',
            degerlendirmeler: const [],
          ),
        ),
      ),
    );
  }

  Future<void> _openEmpatica(AuthProvider auth) async {
    final user = auth.user;
    final kullaniciId = int.tryParse(user?.id ?? '');

    if (!mounted) return;

    if (user == null || kullaniciId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi alınamadı.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final patientResponse = await SupabaseService.client
          .schema('neura')
          .from('hastalar')
          .select(
        'hastaId, hastaliklar(hastalikAdi)',
      )
          .eq('kullaniciId', kullaniciId)
          .maybeSingle();

      if (!mounted) return;

      if (patientResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasta bilgisi bulunamadı.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final int hastaId = patientResponse['hastaId'] as int;

      final hastalikData = patientResponse['hastaliklar'];
      final String? hastalikAdi = hastalikData is Map<String, dynamic>
          ? hastalikData['hastalikAdi']?.toString()
          : null;

      final hasta = patient_model.Patient(
        hastaId: hastaId,
        kullaniciId: kullaniciId,
        ad: user.ad,
        soyad: user.soyad,
        hastalikAdi: hastalikAdi,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmpaticaScreen(hasta: hasta),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Empatica bilgileri açılırken hata oluştu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(
            auth.user?.fullName ?? 'Değerli Hastamız',
            auth.user?.avatarUrl,
          ),

          const SizedBox(height: 28),

          _buildSectionHeader('Günün Toplantıları'),
          const SizedBox(height: 12),
          _buildTodayMeetingsCard(context),

          const SizedBox(height: 24),

          _buildSectionHeader('Günün Görevleri'),
          const SizedBox(height: 12),
          _buildDailyExerciseCard(context),

          const SizedBox(height: 28),

          _buildSectionHeader('Hızlı İşlemler'),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(context, auth),
        ],
      ),
    );
  }

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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monitor_heart,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Hasta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
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

  Widget _buildTodayMeetingsCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TelerehabPatientScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.video_camera_front_outlined,
                color: Color(0xFFEA580C),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoadingTodayMeetings
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Toplantılar yükleniyor...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              )
                  : _todayMeetings.isEmpty
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telerehab Toplantıları',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mevcut toplantı yok',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Telerehab Toplantıları',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._todayMeetings.map((meeting) {
                    final startTime = DateTime.tryParse(
                      meeting['baslangicZamani']?.toString() ?? '',
                    );

                    final String hourText = startTime == null
                        ? '--:--'
                        : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $hourText',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFCBD5E1),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyExerciseCard(BuildContext context) {
    final int totalExercises = _todayExercises.length;
    final int completedExercises = _todayExercises
        .where((exercise) => exercise['tamamlandiMi'] == true)
        .length;

    final String exerciseNames = _todayExercises
        .map((exercise) => exercise['egzersizAdi']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HastaEgzersizScreen(),
        ),
      ),
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFF16A34A),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoadingTodayExercises
                  ? const Text(
                'Egzersizler yükleniyor...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              )
                  : _todayExercises.isEmpty
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Egzersizlerim',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bugün için atanmış egzersiz yok',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Egzersizlerim',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exerciseNames,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '($completedExercises/$totalExercises) tamamlandı',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context,
      AuthProvider auth,
      ) {
    final items = [
      _QuickActionItem(
        icon: Icons.video_camera_front_outlined,
        label: 'Toplantılar',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TelerehabPatientScreen(),
          ),
        ),
      ),
      _QuickActionItem(
        icon: Icons.monitor_heart_outlined,
        label: 'Empatica',
        color: const Color(0xFF0F766E),
        onTap: () => _openEmpatica(auth),
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
              builder: (_) => NotificationsScreen(kullaniciId: userId),
            ),
          );
        },
      ),
      _QuickActionItem(
        icon: Icons.event_note_outlined,
        label: 'Ajanda',
        color: const Color(0xFF2563EB),
        onTap: _openPatientAgenda,
      ),
      _QuickActionItem(
        icon: Icons.fitness_center_outlined,
        label: 'Egzersiz',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HastaEgzersizScreen(),
          ),
        ),
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
            bottom: rowIndex < rowCount - 1 ? 12 : 0,
          ),
          child: Row(
            children: [
              for (int i = 0; i < rowItems.length; i++) ...[
                Expanded(child: _buildGridTile(rowItems[i])),
                if (i < rowItems.length - 1) const SizedBox(width: 12),
              ],
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
                    offset: const Offset(0, 4),
                  ),
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
}

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