import 'package:flutter/material.dart';
import '../models/exercise_video_model.dart';

class ExerciseVideoDetailScreen extends StatefulWidget {
  final EgzersizVideo video;
  const ExerciseVideoDetailScreen({super.key, required this.video});

  @override
  State<ExerciseVideoDetailScreen> createState() =>
      _ExerciseVideoDetailScreenState();
}

class _ExerciseVideoDetailScreenState
    extends State<ExerciseVideoDetailScreen> {
  bool _videoOynatiliyor = false;

  // NeuraApp Klinisyen Teması
  static const Color kPrimary = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      bottomNavigationBar: _altAksiyon(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _videoOynatici(),
            const SizedBox(height: 20),

            Text(v.baslik,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 12),

            _hizliBilgiler(),
            const SizedBox(height: 20),

            if (v.aciklama != null) ...[
              _bolumBaslik(Icons.description_outlined, 'AÇIKLAMA'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                    ]
                ),
                child: Text(v.aciklama!,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.6)),
              ),
              const SizedBox(height: 20),
            ],

            _bolumBaslik(Icons.info_outline, 'DETAYLAR'),
            const SizedBox(height: 8),
            _detayKart(),
            const SizedBox(height: 20),

            _uyariKutusu(),
          ],
        ),
      ),
    );
  }

  // ── Video Oynatıcı Alanı ──────────────────────────────────
  Widget _videoOynatici() {
    final v = widget.video;
    return GestureDetector(
      onTap: () {
        setState(() => _videoOynatiliyor = !_videoOynatiliyor);
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
            color: _kategoriArkaplan(v.kisaKategori),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kategoriRenk(v.kisaKategori).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                _kategoriIkon(v.kisaKategori),
                size: 80,
                color: _kategoriRenk(v.kisaKategori).withOpacity(0.15),
              ),
            ),
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _videoOynatiliyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: _kategoriRenk(v.kisaKategori),
                  size: 38,
                ),
              ),
            ),
            Positioned(
              right: 12, bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(v.formatliSure,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hızlı Bilgiler ───────────────────────────────────────
  Widget _hizliBilgiler() {
    final v = widget.video;
    return Row(
      children: [
        _hizliBilgiChip(
          ikon: _kategoriIkon(v.kisaKategori),
          etiket: v.kisaKategori,
          renk: _kategoriRenk(v.kisaKategori),
          arkaplan: _kategoriArkaplan(v.kisaKategori),
        ),
        const SizedBox(width: 8),
        _hizliBilgiChip(
          ikon: Icons.timer_outlined,
          etiket: v.formatliSure,
          renk: const Color(0xFF475569),
          arkaplan: const Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _hizliBilgiChip({
    required IconData ikon,
    required String etiket,
    required Color renk,
    required Color arkaplan,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: arkaplan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: renk),
          const SizedBox(width: 6),
          Text(etiket,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: renk)),
        ],
      ),
    );
  }

  // ── Detay Kartı ───────────────────────────────────────────
  Widget _detayKart() {
    final v = widget.video;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ]
      ),
      child: Column(
        children: [
          _detaySatir('Kategori', v.kategoriAdi ?? v.kisaKategori, Icons.category_outlined),
          _ayirici(),
          _detaySatir('Süre', v.formatliSure, Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _detaySatir(String etiket, String deger, IconData ikon, {Color? degerRengi}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(etiket, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(deger,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: degerRengi ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _ayirici() => const Divider(height: 1, color: Color(0xFFE2E8F0));

  // ── Uyarı Kutusu ──────────────────────────────────────────
  Widget _uyariKutusu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFD97706)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Önemli Uyarı',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E))),
                SizedBox(height: 4),
                Text(
                  'Egzersizlere başlamadan önce klinisyeninize '
                      'danışın. Ağrı veya rahatsızlık hissederseniz '
                      'egzersizi durdurun.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bolumBaslik(IconData ikon, String baslik) {
    return Row(
      children: [
        Icon(ikon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(baslik,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8)),
      ],
    );
  }

  // ── Alt Aksiyon Butonları ─────────────────────────────────
  Widget _altAksiyon() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -4))
          ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border, size: 20),
                label: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: const BorderSide(color: kPrimary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, size: 20),
                label: const Text('Hastaya Ata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Egzersiz Detayı',
          style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(radius: 16,
              backgroundColor: kPrimary,
              child: const Text('AK',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1)),
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────
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