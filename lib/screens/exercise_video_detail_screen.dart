// lib/screens/exercise_video_detail_screen.dart
//
// Değişiklikler:
//  1. _videoOynatici() → gerçek video URL'si açılır (video_player paketi yerine
//     url_launcher kullanılır; native player yeterli bu akış için).
//  2. "Hastaya Ata" butonu → _hastaAtaModal() açar.
//  3. Modal: klinisyenin sorumlu hastalarını listeler, hasta seçilir, not girişi,
//     tarih seçimi, Kaydet.
//  Bağımlılıklar (pubspec.yaml'a ekle):
//    url_launcher: ^6.2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_video_model.dart';
import '../providers/auth_provider.dart';
import '../services/egzersiz_atama_service.dart';
import '../services/auth_service.dart';

class ExerciseVideoDetailScreen extends StatefulWidget {
  final EgzersizVideo video;
  const ExerciseVideoDetailScreen({super.key, required this.video});

  @override
  State<ExerciseVideoDetailScreen> createState() =>
      _ExerciseVideoDetailScreenState();
}

class _ExerciseVideoDetailScreenState
    extends State<ExerciseVideoDetailScreen> {
  static const Color kPrimary = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      bottomNavigationBar: _altAksiyon(context),
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
              _aciklamaKutu(v.aciklama!),
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

  // ── Video Oynatıcı ────────────────────────────────────────
  Widget _videoOynatici() {
    final v = widget.video;
    return GestureDetector(
      onTap: () async {
        if (v.videoUrl.isNotEmpty) {
          final uri = Uri.parse(v.videoUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video açılamadı')),
              );
            }
          }
        }
      },
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          image: v.thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(v.thumbnailUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(children: [
          // Renkli overlay (thumbnail yoksa)
          if (v.thumbnailUrl == null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          // Oynat ikonu
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF0F766E), size: 40),
            ),
          ),
          // Süre rozeti
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatSure(widget.video.sureSaniye),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // "Oynamak için tıkla" etiketi
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.open_in_new, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Oynatmak için tıkla',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatSure(int saniye) {
    final d = Duration(seconds: saniye);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Hızlı Bilgiler ───────────────────────────────────────
  Widget _hizliBilgiler() {
    final v = widget.video;
    return Row(children: [
      _bilgiChip(Icons.category_outlined, v.kategoriAdi ?? 'Genel'),
      const SizedBox(width: 8),
      _bilgiChip(Icons.timer_outlined, _formatSure(v.sureSaniye)),
    ]);
  }

  Widget _bilgiChip(IconData ikon, String metin) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          Text(metin,
              style: const TextStyle(
                  fontSize: 12,
                  color: kPrimary,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  // ── Açıklama Kutusu ──────────────────────────────────────
  Widget _aciklamaKutu(String aciklama) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(aciklama,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF475569), height: 1.6)),
      );

  // ── Detay Kartı ──────────────────────────────────────────
  Widget _detayKart() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          _detaySatir(Icons.category_outlined, 'Kategori',
              widget.video.kategoriAdi ?? 'Belirtilmedi'),
          const Divider(height: 20),
          _detaySatir(Icons.timer_outlined, 'Süre',
              _formatSure(widget.video.sureSaniye)),
        ]),
      );

  Widget _detaySatir(IconData ikon, String etiket, String deger) => Row(
        children: [
          Icon(ikon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(etiket,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Text(deger,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600)),
        ],
      );

  // ── Uyarı Kutusu ─────────────────────────────────────────
  Widget _uyariKutusu() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD97706), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ağrı veya rahatsızlık hissederseniz egzersizi durdurun.',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.5),
              ),
            ),
          ],
        ),
      );

  // ── Bölüm Başlık ─────────────────────────────────────────
  Widget _bolumBaslik(IconData ikon, String baslik) => Row(children: [
        Icon(ikon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(baslik,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8)),
      ]);

  // ── AppBar ───────────────────────────────────────────────
  AppBar _appBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Egzersiz Detayı',
            style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: false,
      );

  // ── Alt Butonlar ─────────────────────────────────────────
  Widget _altAksiyon(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isKlinisyen = auth.user?.rolAdi == 'Klinisyen';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          // Kaydet / Videoyu Aç butonu
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(widget.video.videoUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.play_circle_outline, size: 20),
              label: const Text('Videoyu Aç',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // "Hastaya Ata" sadece klinisyene göster
          if (isKlinisyen) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _hastaAtaModal(context),
                icon: const Icon(Icons.person_add_outlined, size: 20),
                label: const Text('Hastaya Ata',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Hastaya Ata Modal ────────────────────────────────────
  Future<void> _hastaAtaModal(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final kullaniciId = int.tryParse(auth.user?.id ?? '');
    if (kullaniciId == null) return;

    // klinisyenId'yi çek
    final klinisyenId =
        auth.user?.klinisyenId ??
        await AuthService.getKlinisyenIdByKullaniciId(kullaniciId);

    if (klinisyenId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klinisyen bilgisi bulunamadı.')),
        );
      }
      return;
    }

    // Hastalar yüklenirken loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
    );

    List<Map<String, dynamic>> hastalar = [];
    try {
      hastalar = await EgzersizAtamaService.getHastalarByKlinisyen(klinisyenId);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hastalar yüklenemedi: $e')),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context); // loading kapat

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AtamaModal(
        video: widget.video,
        hastalar: hastalar,
        klinisyenId: klinisyenId,
      ),
    );
  }
}

// ─── Atama Modal Widget ───────────────────────────────────────────────────────

class _AtamaModal extends StatefulWidget {
  final EgzersizVideo video;
  final List<Map<String, dynamic>> hastalar;
  final int klinisyenId;

  const _AtamaModal({
    required this.video,
    required this.hastalar,
    required this.klinisyenId,
  });

  @override
  State<_AtamaModal> createState() => _AtamaModalState();
}

class _AtamaModalState extends State<_AtamaModal> {
  static const Color kPrimary = Color(0xFF0F766E);

  int? _secilenHastaId;
  String? _secilenHastaAdi;
  final _notCtrl = TextEditingController();
  DateTime _atamaTarihi = DateTime.now();
  bool _kaydediliyor = false;

  @override
  void dispose() {
    _notCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Tutaç
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(children: [
              const Text('Hastaya Ata',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const Divider(height: 1),
          // İçerik
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                // Egzersiz özeti
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.fitness_center,
                        color: kPrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.video.baslik,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Hasta seç
                const Text('Hasta Seç',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),

                if (widget.hastalar.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Sorumlu olduğunuz aktif hasta bulunamadı.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                else
                  ...widget.hastalar.map((h) {
                    final k = h['kullanicilar'] as Map<String, dynamic>?;
                    final ad = '${k?['ad'] ?? ''} ${k?['soyad'] ?? ''}'.trim();
                    final hastaId = h['hastaId'] as int;
                    final secili = _secilenHastaId == hastaId;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _secilenHastaId = hastaId;
                        _secilenHastaAdi = ad;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: secili
                              ? kPrimary.withOpacity(0.08)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                secili ? kPrimary : const Color(0xFFE2E8F0),
                            width: secili ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: secili
                                ? kPrimary
                                : const Color(0xFFE2E8F0),
                            child: Text(
                              ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: secili
                                      ? Colors.white
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(ad,
                                style: TextStyle(
                                    fontWeight: secili
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: const Color(0xFF1E293B))),
                          ),
                          if (secili)
                            const Icon(Icons.check_circle,
                                color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Atama tarihi
                const Text('Atama Tarihi',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _atamaTarihi,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 30)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: kPrimary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _atamaTarihi = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: kPrimary),
                      const SizedBox(width: 10),
                      Text(
                        '${_atamaTarihi.day.toString().padLeft(2, '0')}/'
                        '${_atamaTarihi.month.toString().padLeft(2, '0')}/'
                        '${_atamaTarihi.year}',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // Notlar
                const Text('Not (isteğe bağlı)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextField(
                  controller: _notCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Hastaya özel not...',
                    hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_secilenHastaId == null || _kaydediliyor)
                        ? null
                        : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      disabledBackgroundColor:
                          const Color(0xFFCBD5E1),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Ata',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _kaydet() async {
    if (_secilenHastaId == null) return;
    setState(() => _kaydediliyor = true);
    try {
      await EgzersizAtamaService.videoAta(
        hastaId: _secilenHastaId!,
        egzersizVideoId: widget.video.egzersizVideoId,
        egzersizAdi: widget.video.baslik,
        klinisyenId: widget.klinisyenId,
        notlar: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
        atamaTarihi: _atamaTarihi,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.video.baslik} → $_secilenHastaAdi için atandı'),
            backgroundColor: const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _kaydediliyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }
}
