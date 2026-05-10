import 'package:flutter/material.dart';
import '../models/exercise_video_model.dart';
import '../services/exercise_video_service.dart';
import 'exercise_video_detail_screen.dart';

class ExerciseVideoLibraryScreen extends StatefulWidget {
  const ExerciseVideoLibraryScreen({super.key});

  @override
  State<ExerciseVideoLibraryScreen> createState() =>
      _ExerciseVideoLibraryScreenState();
}

class _ExerciseVideoLibraryScreenState
    extends State<ExerciseVideoLibraryScreen> {
  List<EgzersizVideo> _videolar = [];
  List<EgzersizKategori> _kategoriler = [];
  bool _yukleniyor = true;
  String? _hata;

  final TextEditingController _aramaCtrl = TextEditingController();
  int? _secilenKategoriId;

  static const Color kPrimary = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _baslangicYukle();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _baslangicYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final kategoriler = await ExerciseVideoService.getKategoriler();
      final videolar = await ExerciseVideoService.getVideolar();
      setState(() {
        _kategoriler = kategoriler;
        _videolar = videolar;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  Future<void> _videolariYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final videolar = await ExerciseVideoService.getVideolar(
        kategoriId: _secilenKategoriId,
        aramaMetni: _aramaCtrl.text.isEmpty ? null : _aramaCtrl.text,
      );
      setState(() { _videolar = videolar; _yukleniyor = false; });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  void _aramaYap(String _) => _videolariYukle();

  void _filtreleriSifirla() {
    setState(() {
      _secilenKategoriId = null;
      _aramaCtrl.clear();
    });
    _videolariYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      // AppBar ve BottomNavigationBar silindi, MainScreen bunları zaten veriyor.
      body: Column(
        children: [
          _ustPanel(),
          const SizedBox(height: 1),
          _kategoriChipBar(),
          Expanded(child: _govde()),
        ],
      ),
    );
  }

  Widget _ustPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_outline, color: kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Egzersiz Kütüphanesi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Nörolojik rehabilitasyon egzersizleri',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _aramaCtrl,
            onChanged: _aramaYap,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Egzersiz ara...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _aramaCtrl.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                  onPressed: () {
                    _aramaCtrl.clear();
                    _videolariYukle();
                  })
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriChipBar() {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _kategoriler.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            final secili = _secilenKategoriId == null;
            return _chipWidget(
              etiket: 'Tümü',
              ikon: null,
              secili: secili,
              onTap: () {
                setState(() => _secilenKategoriId = null);
                _videolariYukle();
              },
            );
          }
          final kat = _kategoriler[i - 1];
          final secili = _secilenKategoriId == kat.egzersizKategoriId;
          return _chipWidget(
            etiket: kat.kisaAd,
            ikon: _kategoriIkon(kat.kisaAd),
            secili: secili,
            onTap: () {
              setState(() => _secilenKategoriId = kat.egzersizKategoriId);
              _videolariYukle();
            },
          );
        },
      ),
    );
  }

  Widget _chipWidget({
    required String etiket,
    IconData? ikon,
    required bool secili,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: secili ? kPrimary : const Color(0xFFE2E8F0),
          ),
          boxShadow: secili
              ? [BoxShadow(color: kPrimary.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 14, color: secili ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
            ],
            Text(etiket,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: secili ? Colors.white : const Color(0xFF64748B),
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }

  IconData _kategoriIkon(String kisaAd) {
    switch (kisaAd) {
      case 'Denge':     return Icons.accessibility_new;
      case 'Guc':       return Icons.fitness_center;
      case 'Esneklik':  return Icons.self_improvement;
      case 'Solunum':   return Icons.air;
      case 'Kognitif':  return Icons.psychology;
      default:          return Icons.sports_gymnastics;
    }
  }

  Widget _govde() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_hata != null) return _hataEkrani();
    if (_videolar.isEmpty) return _bosEkran();

    return RefreshIndicator(
      onRefresh: _videolariYukle,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text('${_videolar.length} EGZERSİZ BULUNDU',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8)),
                const Spacer(),
                if (_secilenKategoriId != null)
                  GestureDetector(
                    onTap: _filtreleriSifirla,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off, size: 12, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Filtreyi Temizle', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ..._videolar.map((video) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _VideoKarti(
              video: video,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExerciseVideoDetailScreen(video: video)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _hataEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Videolar yüklenemedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(_hata!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _baslangicYukle,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tekrar Dene', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosEkran() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            _secilenKategoriId != null || _aramaCtrl.text.isNotEmpty
                ? 'Kriterlere uygun video bulunamadı'
                : 'Henüz egzersiz videosu yok',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (_secilenKategoriId != null || _aramaCtrl.text.isNotEmpty)
            ActionChip(
              onPressed: _filtreleriSifirla,
              backgroundColor: kPrimary.withOpacity(0.1),
              label: const Text('Filtreleri Temizle', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _VideoKarti extends StatelessWidget {
  final EgzersizVideo video;
  final VoidCallback onTap;
  const _VideoKarti({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _kategoriArkaplan(video.kisaKategori),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _kategoriIkon(video.kisaKategori),
                        size: 56,
                        color: _kategoriRenk(video.kisaKategori).withOpacity(0.15),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: _kategoriRenk(video.kisaKategori), size: 30),
                      ),
                    ),
                    Positioned(
                      right: 12, bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(video.formatliSure, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    if (video.aciklama != null)
                      Text(video.aciklama!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _etiket(video.kisaKategori, _kategoriRenk(video.kisaKategori), _kategoriArkaplan(video.kisaKategori)),
                        _etiket(video.formatliSure, const Color(0xFF475569), const Color(0xFFF1F5F9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiket(String text, Color renk, Color arkaplan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: arkaplan, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: renk)),
    );
  }

  Color _kategoriRenk(String kisaAd) {
    switch (kisaAd) {
      case 'Denge':     return const Color(0xFF0891B2);
      case 'Guc':       return const Color(0xFFDC2626);
      case 'Esneklik':  return const Color(0xFF9333EA);
      case 'Solunum':   return const Color(0xFF0F766E);
      case 'Kognitif':  return const Color(0xFF2563EB);
      default:          return const Color(0xFF64748B);
    }
  }

  Color _kategoriArkaplan(String kisaAd) {
    switch (kisaAd) {
      case 'Denge':     return const Color(0xFFECFEFF);
      case 'Guc':       return const Color(0xFFFFF1F2);
      case 'Esneklik':  return const Color(0xFFFAF5FF);
      case 'Solunum':   return const Color(0xFFF0FDFA);
      case 'Kognitif':  return const Color(0xFFEFF6FF);
      default:          return const Color(0xFFF8FAFC);
    }
  }

  IconData _kategoriIkon(String kisaAd) {
    switch (kisaAd) {
      case 'Denge':     return Icons.accessibility_new;
      case 'Guc':       return Icons.fitness_center;
      case 'Esneklik':  return Icons.self_improvement;
      case 'Solunum':   return Icons.air;
      case 'Kognitif':  return Icons.psychology;
      default:          return Icons.sports_gymnastics;
    }
  }
}