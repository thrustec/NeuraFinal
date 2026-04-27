import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/evaluation_provider.dart';
import '../services/evaluation_service.dart';
import '../core/theme.dart';
import 'clinician_agenda.dart';
import 'patient_list_screen.dart';
import 'exercise_video_library_screen.dart';
import 'comparison_screen.dart';
import 'patient_step_1_screen.dart';
import 'telerehab_clinician_screen.dart';
import 'clinical_evaluation/evaluation_list_screen.dart';

class ClinicianHome extends StatelessWidget {
  const ClinicianHome({super.key});

  static const Color _green = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: NeuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'N',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
              TextSpan(
                text: 'eura',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeuraTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: NeuraTheme.textDark),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoşgeldin 👋',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user?.fullName ?? 'Klinisyen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Klinisyen',
                        style:
                        TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Menü',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeuraTheme.textDark,
                ),
              ),

              const SizedBox(height: 16),

              // Menü Grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MenuCard(
                    icon: Icons.home_outlined,
                    label: 'Anasayfa',
                    color: _green,
                    onTap: () {},
                  ),
                  _MenuCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Ajanda',
                    color: const Color(0xFF2260FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClinicianAgenda()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.person_add_outlined,
                    label: 'Hasta Kaydı',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientStep1Screen())),
                  ),
                  _MenuCard(
                    icon: Icons.folder_outlined,
                    label: 'Hasta Bilgileri',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientListScreen())),
                  ),
                  _MenuCard(
                    icon: Icons.show_chart_outlined,
                    label: 'İzlem Bilgileri',
                    color: Colors.teal,
                    onTap: () => _showComingSoon(context),
                  ),
                  _MenuCard(
                    icon: Icons.fitness_center_outlined,
                    label: 'Egzersiz Kütüphanesi',
                    color: Colors.red,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseVideoLibraryScreen())),
                  ),
                  _MenuCard(
                    icon: Icons.favorite_outline,
                    label: 'Rehabilitasyon',
                    color: Colors.pink,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelerehabClinicianScreen())),
                  ),
                  _MenuCard(
                    icon: Icons.assignment_outlined,
                    label: 'Değerlendirme',
                    color: Colors.indigo,
                    onTap: () async {
                      final email = auth.user?.eposta ?? '';
                      final clinicianId = await EvaluationService().getClinicianIdByEmail(email);

                      if (!context.mounted) return;

                      if (clinicianId == null || clinicianId == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Klinisyen ID bulunamadı. Lütfen geçerli bir klinisyen hesabıyla giriş yapın.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => EvaluationProvider(doctorId: clinicianId),
                            child: const EvaluationListScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.compare_arrows_outlined,
                    label: 'Karşılaştırma',
                    color: Colors.blueGrey,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComparisonScreen(),
                      ),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.bar_chart_outlined,
                    label: 'Raporlar',
                    color: Colors.brown,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu sayfa yakında eklenecek!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}