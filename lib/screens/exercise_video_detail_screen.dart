// lib/screens/exercise_video_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_video_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/egzersiz_atama_service.dart';

const Color kPrimary = Color(0xFF0F766E);

// ─── Ana Ekran ────────────────────────────────────────────────────────────────

class ExerciseVideoDetailScreen extends StatefulWidget {
  final EgzersizVideo video;
  const ExerciseVideoDetailScreen({super.key, required this.video});

  @override
  State<ExerciseVideoDetailScreen> createState() =>
      _ExerciseVideoDetailScreenState();
}

class _ExerciseVideoDetailScreenState
    extends State<ExerciseVideoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.video.thumbnailUrl != null
            ? Image.network(
          widget.video.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
        )
            : _thumbnailPlaceholder(),
      ),
      title: Text(
        widget.video.baslik,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _thumbnailPlaceholder() => Container(
    color: kPrimary.withOpacity(0.15),
    child: const Center(
      child: Icon(Icons.fitness_center, size: 64, color: kPrimary),
    ),
  );

  // ── Gövde ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + kategori chip
          Row(children: [
            Expanded(
              child: Text(
                widget.video.baslik,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
            if (widget.video.kategoriAdi != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.video.kisaKategori,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary),
                ),
              ),
          ]),
          const SizedBox(height: 12),

          // Süre bilgisi
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              widget.video.formatliSure,
              style:
              const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ]),

          if (widget.video.aciklama != null &&
              widget.video.aciklama!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            const Text(
              'Açıklama',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 6),
            Text(
              widget.video.aciklama!,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.55),
            ),
          ],
        ],
      ),
    );
  }

  // ── Alt Bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(widget.video.videoUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  // ── Hastaya Ata Modal Açıcı ───────────────────────────────────────────────
  Future<void> _hastaAtaModal(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final kullaniciId = int.tryParse(auth.user?.id ?? '');
    if (kullaniciId == null) return;

    final klinisyenId = auth.user?.klinisyenId ??
        await AuthService.getKlinisyenIdByKullaniciId(kullaniciId);

    if (klinisyenId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klinisyen bilgisi bulunamadı.')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    List<Map<String, dynamic>> hastalar = [];
    try {
      hastalar =
      await EgzersizAtamaService.getHastalarByKlinisyen(klinisyenId);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hastalar yüklenemedi: $e')),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);
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

// ─── Atama Modal ─────────────────────────────────────────────────────────────

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
  int? _secilenHastaId;
  String? _secilenHastaAdi;
  final _notCtrl = TextEditingController();
  DateTime _atamaTarihi = DateTime.now();
  int _tekrarSayisi = 3;
  bool _kaydediliyor = false;

  static const List<int> _tekrarSecenekleri = [1, 2, 3, 5, 7, 10, 14, 21, 30];

  @override
  void dispose() {
    _notCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined,
                    color: kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hastaya Ata',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      Text(
                        widget.video.baslik,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
              ),
            ]),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          // İçerik
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // ── Hasta Listesi ─────────────────────────────────
                const Text('Hasta Seçin',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),
                if (widget.hastalar.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sorumlu hastanız bulunamadı.',
                        style: TextStyle(color: Color(0xFF64748B))),
                  )
                else
                  ...widget.hastalar.map((h) {
                    final k =
                    h['kullanicilar'] as Map<String, dynamic>?;
                    final ad =
                    '${k?['ad'] ?? ''} ${k?['soyad'] ?? ''}'.trim();
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
                            color: secili
                                ? kPrimary
                                : const Color(0xFFE2E8F0),
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

                // ── Tekrar Sayısı Seçici ──────────────────────────
                const Text('Tekrar Sayısı',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 4),
                const Text(
                  'Hasta bu videoyu kaç kez tekrarlamalı?',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 10),
                // Büyük sayı gösterimi + +/- butonları
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Azalt
                      _TekrarBtn(
                        icon: Icons.remove,
                        onTap: _tekrarSayisi > 1
                            ? () => setState(() => _tekrarSayisi--)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      // Sayı
                      Column(
                        children: [
                          Text(
                            '$_tekrarSayisi',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'tekrar',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Artır
                      _TekrarBtn(
                        icon: Icons.add,
                        onTap: _tekrarSayisi < 99
                            ? () => setState(() => _tekrarSayisi++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Hızlı seçim chipleri
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tekrarSecenekleri.map((sayi) {
                    final secili = _tekrarSayisi == sayi;
                    return GestureDetector(
                      onTap: () => setState(() => _tekrarSayisi = sayi),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: secili
                              ? kPrimary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: secili
                                ? kPrimary
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          '$sayi×',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: secili
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Atama Tarihi ──────────────────────────────────
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
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: kPrimary),
                      const SizedBox(width: 10),
                      Text(
                        '${_atamaTarihi.day.toString().padLeft(2, '0')}/'
                            '${_atamaTarihi.month.toString().padLeft(2, '0')}/'
                            '${_atamaTarihi.year}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151)),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFCBD5E1)),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Not alanı ─────────────────────────────────────
                const Text('Not (İsteğe Bağlı)',
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

                // ── Kaydet Butonu ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                    (_secilenHastaId == null || _kaydediliyor)
                        ? null
                        : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Text(
                      _secilenHastaAdi != null
                          ? '$_secilenHastaAdi\'a Ata  ($_tekrarSayisi tekrar)'
                          : 'Hasta Seçin',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
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
        notlar: _notCtrl.text.trim(),
        atamaTarihi: _atamaTarihi,
        tekrarSayisi: _tekrarSayisi,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${widget.video.baslik} → $_secilenHastaAdi\'a atandı ($_tekrarSayisi tekrar)'),
          backgroundColor: kPrimary,
        ));
      }
    } catch (e) {
      setState(() => _kaydediliyor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}

// ─── Tekrar +/- Buton ────────────────────────────────────────────────────────

class _TekrarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TekrarBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? kPrimary : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : const Color(0xFFCBD5E1),
          size: 22,
        ),
      ),
    );
  }
}