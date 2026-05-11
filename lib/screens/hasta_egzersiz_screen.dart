// lib/screens/hasta_egzersiz_screen.dart
//
// Hasta rolüyle giriş yapan kullanıcı bu ekranda yalnızca
// kendisine atanmış egzersizleri görür.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/egzersiz_atama_service.dart';
import '../services/exercise_video_service.dart';

const String _sbUrl = 'https://griteunvazwekosffmjo.supabase.co/rest/v1';
const String _sbKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
    'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
    'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _sbHeaders() => {
      'apikey': _sbKey,
      'Authorization': 'Bearer $_sbKey',
      'Accept-Profile': 'neura',
    };

class HastaEgzersizScreen extends StatefulWidget {
  const HastaEgzersizScreen({super.key});

  @override
  State<HastaEgzersizScreen> createState() => _HastaEgzersizScreenState();
}

class _HastaEgzersizScreenState extends State<HastaEgzersizScreen> {
  static const Color kPrimary = Color(0xFF0F766E);

  List<EgzersizAtama> _atamalar = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');
      if (kullaniciId == null) throw Exception('Kullanici bilgisi yok.');

      final res = await http.get(
        Uri.parse('$_sbUrl/hastalar?kullaniciId=eq.$kullaniciId&select=hastaId&limit=1'),
        headers: _sbHeaders(),
      );
      if (res.statusCode != 200) throw Exception('Hasta kaydi bulunamadi.');
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) throw Exception('Hasta kaydi bulunamadi.');
      final hastaId = (list.first as Map<String, dynamic>)['hastaId'] as int;

      final atamalar = await EgzersizAtamaService.getAtamalarForHasta(hastaId);

      if (mounted) setState(() { _atamalar = atamalar; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  Future<void> _tamamlandiIsaretle(EgzersizAtama atama) async {
    try {
      await EgzersizAtamaService.tamamlandiIsaretle(atama.egzersizAtamaId);
      setState(() {
        final idx = _atamalar.indexWhere((a) => a.egzersizAtamaId == atama.egzersizAtamaId);
        if (idx != -1) {
          _atamalar[idx] = EgzersizAtama(
            egzersizAtamaId: atama.egzersizAtamaId,
            hastaId: atama.hastaId,
            egzersizVideoId: atama.egzersizVideoId,
            klinisyenId: atama.klinisyenId,
            egzersizAdi: atama.egzersizAdi,
            notlar: atama.notlar,
            atamaTarihi: atama.atamaTarihi,
            tamamlandiMi: true,
          );
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guncelleme basarisiz: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(children: [_ustPanel(), Expanded(child: _govde())]),
    );
  }

  Widget _ustPanel() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    color: Colors.white,
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.fitness_center, color: kPrimary, size: 22),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Egzersizlerim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        SizedBox(height: 2),
        Text('Klinisyeninizin atadigi egzersizler', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ])),
      IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF64748B)), onPressed: _yukle),
    ]),
  );

  Widget _govde() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
    if (_hata != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_hata!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _yukle, style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white))),
        ]),
      ));
    }
    if (_atamalar.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.fitness_center_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text('Henüz egzersiz atanmadi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          SizedBox(height: 4),
          Text('Klinisyeniniz size egzersiz atadığında burada görünecek.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        ]),
      ));
    }

    final bekleyen = _atamalar.where((a) => !a.tamamlandiMi).toList();
    final tamamlanan = _atamalar.where((a) => a.tamamlandiMi).toList();

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (bekleyen.isNotEmpty) ...[
            _bolumBaslik('YAPILACAK (${bekleyen.length})'),
            const SizedBox(height: 8),
            ...bekleyen.map((a) => _AtamaKarti(atama: a, onTamamla: () => _tamamlandiIsaretle(a))),
          ],
          if (tamamlanan.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bolumBaslik('TAMAMLANAN (${tamamlanan.length})'),
            const SizedBox(height: 8),
            ...tamamlanan.map((a) => _AtamaKarti(atama: a, onTamamla: null)),
          ],
        ],
      ),
    );
  }

  Widget _bolumBaslik(String baslik) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(baslik, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
  );
}

// ─── Atama Kartı ─────────────────────────────────────────────────────────────

class _AtamaKarti extends StatelessWidget {
  final EgzersizAtama atama;
  final VoidCallback? onTamamla;
  static const Color kPrimary = Color(0xFF0F766E);
  const _AtamaKarti({required this.atama, this.onTamamla});

  @override
  Widget build(BuildContext context) {
    final done = atama.tamamlandiMi;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: done ? const Color(0xFFDCFCE7) : kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(done ? Icons.check_circle : Icons.fitness_center_outlined,
                  color: done ? const Color(0xFF16A34A) : kPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(atama.egzersizAdi,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: done ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                decoration: done ? TextDecoration.lineThrough : null))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${atama.atamaTarihi.day.toString().padLeft(2, '0')}/'
                '${atama.atamaTarihi.month.toString().padLeft(2, '0')}/'
                '${atama.atamaTarihi.year}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ),
          ]),

          if (atama.notlar != null && atama.notlar!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.notes, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(child: Text(atama.notlar!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4))),
              ]),
            ),
          ],

          if (!done) ...[
            const SizedBox(height: 12),
            Row(children: [
              if (atama.egzersizVideoId != null) ...[
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _videoAc(context),
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Videoyu Izle', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
                const SizedBox(width: 8),
              ],
              Expanded(child: ElevatedButton.icon(
                onPressed: onTamamla,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Tamamlandi', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _videoAc(BuildContext context) async {
    try {
      final videos = await ExerciseVideoService.getVideolar();
      final video = videos.firstWhere(
        (v) => v.egzersizVideoId == atama.egzersizVideoId,
        orElse: () => throw Exception('Video bulunamadi'),
      );
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video acilamadi')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
