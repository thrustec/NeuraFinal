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

  // Seçili kategori (null = Tümü)
  int? _secilenKategoriId;

  static const Color kPrimary = Color(0xFF2563EB);

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
        aramaMetni:
        _aramaCtrl.text.isEmpty ? null : _aramaCtrl.text,
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
      appBar: _appBar(),
      bottomNavigationBar: _altMenu(),
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

  // ── Üst Panel: Başlık + Arama ─────────────────────────────
  Widget _ustPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: Color(0xFF9333EA), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Egzersiz Video Kütüphanesi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  Text('Nörolojik rehabilitasyon egzersizleri',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _aramaCtrl,
            onChanged: _aramaYap,
            decoration: InputDecoration(
              hintText: 'Egzersiz ara...',
              hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _aramaCtrl.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF94A3B8), size: 18),
                  onPressed: () {
                    _aramaCtrl.clear();
                    _videolariYukle();
                  })
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: kPrimary, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kategori Chip Bar ─────────────────────────────────────
  Widget _kategoriChipBar() {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        itemCount: _kategoriler.length + 1, // +1 for "Tümü"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            // "Tümü" chip
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
              setState(() =>
              _secilenKategoriId = kat.egzersizKategoriId);
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
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: secili ? kPrimary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: secili ? kPrimary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 14,
                  color: secili
                      ? Colors.white
                      : const Color(0xFF64748B)),
              const SizedBox(width: 4),
            ],
            Text(etiket,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secili
                      ? Colors.white
                      : const Color(0xFF64748B),
                )),
          ],
        ),
      ),
    );
  }

  IconData _kategoriIkon(String kisaAd) {
    switch (kisaAd) {
      case 'Denge':
        return Icons.accessibility_new;
      case 'Guc':
        return Icons.fitness_center;
      case 'Esneklik':
        return Icons.self_improvement;
      case 'Solunum':
        return Icons.air;
      case 'Kognitif':
        return Icons.psychology;
      default:
        return Icons.sports_gymnastics;
    }
  }

  // ── Gövde ─────────────────────────────────────────────────
  Widget _govde() {
    if (_yukleniyor) {
      return const Center(
          child: CircularProgressIndicator(color: kPrimary));
    }
    if (_hata != null) return _hataEkrani();
    if (_videolar.isEmpty) return _bosEkran();

    return RefreshIndicator(
      onRefresh: _videolariYukle,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text('${_videolar.length} EGZERSİZ',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8)),
                const Spacer(),
                if (_secilenKategoriId != null)
                  GestureDetector(
                    onTap: _filtreleriSifirla,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off,
                              size: 12, color: kPrimary),
                          SizedBox(width: 3),
                          Text('Filtreleri Kaldır',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ..._videolar.map((video) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _VideoKarti(
              video: video,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ExerciseVideoDetailScreen(video: video),
                ),
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
            const Icon(Icons.error_outline,
                size: 56, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Videolar yüklenemedi',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_hata!, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _baslangicYukle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tekrar Dene'),
              ),
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
          Icon(Icons.videocam_off_outlined,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _secilenKategoriId != null || _aramaCtrl.text.isNotEmpty
                ? 'Kriterlere uygun video bulunamadı'
                : 'Henüz egzersiz videosu yok',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          if (_secilenKategoriId != null)
            TextButton(
              onPressed: _filtreleriSifirla,
              child: const Text('Filtreleri Temizle'),
            ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Egzersiz Videoları',
          style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 18)),
      centerTitle: false,
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          Positioned(right: 10, top: 10,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle))),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(radius: 17,
              backgroundColor: kPrimary,
              child: const Text('AK',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              color: const Color(0xFFE2E8F0), height: 1)),
    );
  }

  // ── Alt Menü ──────────────────────────────────────────────
  Widget _altMenu() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Ana Sayfa'},
      {'icon': Icons.people_alt_outlined, 'label': 'Hastalar'},
      {'icon': Icons.person_add_outlined, 'label': 'Kayıt'},
      {'icon': Icons.assignment_outlined, 'label': 'Değerlendir'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Raporlar'},
    ];
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i]['icon'] as IconData,
                      color: const Color(0xFF94A3B8), size: 22),
                  const SizedBox(height: 3),
                  Text(items[i]['label'] as String,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8))),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Video Kartı ─────────────────────────────────────────────
class _VideoKarti extends StatelessWidget {
  final EgzersizVideo video;
  final VoidCallback onTap;
  const _VideoKarti({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail / Placeholder ────────────────
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _kategoriArkaplan(video.kisaKategori),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _kategoriIkon(video.kisaKategori),
                        size: 48,
                        color: _kategoriRenk(video.kisaKategori)
                            .withOpacity(0.3),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.play_arrow,
                            color: _kategoriRenk(video.kisaKategori),
                            size: 28),
                      ),
                    ),
                    Positioned(
                      right: 8, bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(video.formatliSure,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bilgiler ──────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    if (video.aciklama != null)
                      Text(video.aciklama!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _etiket(
                          video.kisaKategori,
                          _kategoriRenk(video.kisaKategori),
                          _kategoriArkaplan(video.kisaKategori),
                        ),
                        _etiket(
                          video.formatliSure,
                          const Color(0xFF475569),
                          const Color(0xFFF1F5F9),
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: arkaplan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: renk)),
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
