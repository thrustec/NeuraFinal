// lib/screens/hasta_egzersiz_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_video_model.dart';
import '../providers/auth_provider.dart';
import '../services/egzersiz_atama_service.dart';

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

// ─── Video detayı çekici ─────────────────────────────────────────────────────

Future<EgzersizVideo?> _videoDetayGetir(int egzersizVideoId) async {
  final select = Uri.encodeComponent('*,egzersizKategorileri(kategoriAdi)');
  final url =
      '$_sbUrl/egzersizVideolari?select=$select&egzersizVideoId=eq.$egzersizVideoId&limit=1';

  final res = await http.get(Uri.parse(url), headers: _sbHeaders());

  if (res.statusCode != 200) return null;

  final list = jsonDecode(res.body) as List;
  if (list.isEmpty) return null;

  return EgzersizVideo.fromJson(list.first as Map<String, dynamic>);
}

// ─── Ana Ekran ────────────────────────────────────────────────────────────────

class HastaEgzersizScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const HastaEgzersizScreen({
    super.key,
    this.onBack,
  });

  @override
  State<HastaEgzersizScreen> createState() => _HastaEgzersizScreenState();
}

class _HastaEgzersizScreenState extends State<HastaEgzersizScreen> {
  static const Color kPrimary = Color(0xFF2563EB);

  List<EgzersizAtama> _atamalar = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  void _geriDon() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');

      if (kullaniciId == null) {
        throw Exception('Kullanıcı bilgisi yok.');
      }

      final res = await http.get(
        Uri.parse(
          '$_sbUrl/hastalar?kullaniciId=eq.$kullaniciId&select=hastaId&limit=1',
        ),
        headers: _sbHeaders(),
      );

      if (res.statusCode != 200) {
        throw Exception('Atanmış egzersiz bulunamadı.');
      }

      final list = jsonDecode(res.body) as List;

      if (list.isEmpty) {
        throw Exception('Atanmış egzersiz bulunamadı.');
      }

      final hastaId = (list.first as Map<String, dynamic>)['hastaId'] as int;

      final atamalar =
      await EgzersizAtamaService.getAtamalarForHasta(hastaId);

      if (!mounted) return;

      setState(() {
        _atamalar = atamalar;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  Future<void> _tekrarTamamla(EgzersizAtama atama) async {
    try {
      final guncel = await EgzersizAtamaService.tekrarTamamla(atama);

      final idx = _atamalar.indexWhere(
            (a) => a.egzersizAtamaId == atama.egzersizAtamaId,
      );

      if (idx != -1 && mounted) {
        setState(() => _atamalar[idx] = guncel);
      }

      if (mounted && guncel.tamamlandiMi) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('${atama.egzersizAdi} tamamlandı! Harika iş çıkardın 🎉'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız: $e')),
        );
      }
    }
  }

  void _detayAc(EgzersizAtama atama) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EgzersizDetaySheet(
        atama: atama,
        onTamamla: atama.tamamlandiMi
            ? null
            : () {
          Navigator.pop(context);
          _tekrarTamamla(atama);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          _ustPanel(),
          Expanded(child: _govde()),
        ],
      ),
    );
  }

  Widget _ustPanel() => Container(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
    color: Colors.white,
    child: Row(
      children: [
        IconButton(
          onPressed: _geriDon,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: kPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Egzersizlerim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Klinisyeninizin atadığı egzersizleri buradan görebilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
          onPressed: _yukle,
        ),
      ],
    ),
  );

  Widget _govde() {
    if (_yukleniyor) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
      );
    }

    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _hata!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _yukle,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: const Text(
                  'Tekrar Dene',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_atamalar.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 56,
                color: Color(0xFFCBD5E1),
              ),
              SizedBox(height: 12),
              Text(
                'Henüz egzersiz atanmadı',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Klinisyeniniz size egzersiz atadığında burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
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
            ...bekleyen.map(
                  (a) => _AtamaKarti(
                atama: a,
                onTap: () => _detayAc(a),
                onTamamla: () => _tekrarTamamla(a),
              ),
            ),
          ],
          if (tamamlanan.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bolumBaslik('TAMAMLANAN (${tamamlanan.length})'),
            const SizedBox(height: 8),
            ...tamamlanan.map(
                  (a) => _AtamaKarti(
                atama: a,
                onTap: () => _detayAc(a),
                onTamamla: null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bolumBaslik(String baslik) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      baslik,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Atama Kartı ─────────────────────────────────────────────────────────────

class _AtamaKarti extends StatelessWidget {
  final EgzersizAtama atama;
  final VoidCallback onTap;
  final VoidCallback? onTamamla;

  static const Color kPrimary = Color(0xFF2563EB);

  const _AtamaKarti({
    required this.atama,
    required this.onTap,
    this.onTamamla,
  });

  @override
  Widget build(BuildContext context) {
    final done = atama.tamamlandiMi;
    final kalan = atama.kalanTekrar;
    final toplam = atama.tekrarSayisi;
    final ilerleme =
    toplam > 0 ? (atama.tamamlananTekrar / toplam).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFDCFCE7)
                          : kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      done
                          ? Icons.check_circle
                          : Icons.fitness_center_outlined,
                      color: done ? const Color(0xFF16A34A) : kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      atama.egzersizAdi,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF1E293B),
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),

              if (!done && toplam > 1) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ilerleme,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: kPrimary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$kalan tekrar kaldı',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ],

              if (done && toplam > 1) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tüm $toplam tekrar tamamlandı',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${atama.atamaTarihi.day.toString().padLeft(2, '0')}/'
                        '${atama.atamaTarihi.month.toString().padLeft(2, '0')}/'
                        '${atama.atamaTarihi.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  if (atama.notlar != null && atama.notlar!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.notes,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        atama.notlar!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (!done && onTamamla != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTamamla,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      kalan == 1
                          ? 'Tamamlandı (Son Tekrar)'
                          : 'Videoyu Tamamladım  ($kalan tekrar kaldı)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Egzersiz Detay Bottom Sheet ─────────────────────────────────────────────

class _EgzersizDetaySheet extends StatefulWidget {
  final EgzersizAtama atama;
  final VoidCallback? onTamamla;

  const _EgzersizDetaySheet({
    required this.atama,
    this.onTamamla,
  });

  @override
  State<_EgzersizDetaySheet> createState() => _EgzersizDetaySheetState();
}

class _EgzersizDetaySheetState extends State<_EgzersizDetaySheet> {
  static const Color kPrimary = Color(0xFF2563EB);

  EgzersizVideo? _video;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    if (widget.atama.egzersizVideoId == null) {
      setState(() {
        _yukleniyor = false;
      });
      return;
    }

    try {
      final video = await _videoDetayGetir(widget.atama.egzersizVideoId!);

      if (!mounted) return;

      setState(() {
        _video = video;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  Future<void> _oynat() async {
    final url = _video?.videoUrl;

    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atama = widget.atama;
    final done = atama.tamamlandiMi;
    final kalan = atama.kalanTekrar;
    final toplam = atama.tekrarSayisi;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFDCFCE7)
                          : kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      done
                          ? Icons.check_circle
                          : Icons.fitness_center_outlined,
                      color: done ? const Color(0xFF16A34A) : kPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      atama.egzersizAdi,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 20, color: Color(0xFFE2E8F0)),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (_video?.thumbnailUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            _video!.thumbnailUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbnailPlaceholder(tapable: true),
                          ),
                          GestureDetector(
                            onTap: _oynat,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (!_yukleniyor && _video != null) ...[
                    GestureDetector(
                      onTap: _oynat,
                      child: _thumbnailPlaceholder(tapable: true),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_yukleniyor)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: kPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else if (_hata != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Video bilgisi yüklenemedi.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else if (_video != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (_video!.kategoriAdi != null)
                            _InfoChip(
                              icon: Icons.category_outlined,
                              label: _video!.kisaKategori,
                            ),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: _video!.formatliSure,
                          ),
                          _InfoChip(
                            icon: Icons.repeat_rounded,
                            label:
                            done ? 'Tamamlandı' : '$kalan / $toplam tekrar',
                            color:
                            done ? const Color(0xFF16A34A) : kPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_video!.aciklama != null &&
                          _video!.aciklama!.isNotEmpty) ...[
                        const Text(
                          'Açıklama',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            _video!.aciklama!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.55,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                  if (atama.notlar != null && atama.notlar!.isNotEmpty) ...[
                    const Text(
                      'Klinisyen Notu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              atama.notlar!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF92400E),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Atama tarihi: '
                            '${atama.atamaTarihi.day.toString().padLeft(2, '0')}/'
                            '${atama.atamaTarihi.month.toString().padLeft(2, '0')}/'
                            '${atama.atamaTarihi.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (_video != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _oynat,
                        icon: const Icon(
                          Icons.play_circle_outline,
                          size: 20,
                        ),
                        label: const Text(
                          'Videoyu Oynat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(
                            color: kPrimary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  if (!done && widget.onTamamla != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onTamamla,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 20,
                        ),
                        label: Text(
                          kalan == 1
                              ? 'Tamamlandı (Son Tekrar)'
                              : 'Videoyu Tamamladım  ($kalan tekrar kaldı)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder({bool tapable = false}) => Container(
    height: 160,
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: kPrimary.withOpacity(0.5),
          ),
          if (tapable) ...[
            const SizedBox(height: 8),
            Text(
              'Videoyu oynatmak için dokunun',
              style: TextStyle(
                fontSize: 13,
                color: kPrimary.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ─── Bilgi Chip'i ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}