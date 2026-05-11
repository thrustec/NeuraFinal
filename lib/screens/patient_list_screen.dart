import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import 'patient_detail_screen.dart';
import '../widgets/hasta_arama_widget.dart';

class PatientListScreen extends StatefulWidget {
  // Arkadaşının eklediği klinisyenId parametresi — korundu
  final int? klinisyenId;

  const PatientListScreen({super.key, this.klinisyenId});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _hastalar = [];
  List<Patient> _filtrelenmis = [];
  bool _yukleniyor = true;
  String? _hata;

  static const Color kPrimary = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _hastalariYukle();
  }

  Future<void> _hastalariYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      // Arkadaşının klinisyenId filtresi korundu
      final hastalar = await PatientService.getHastalar(
        klinisyenId: widget.klinisyenId,
      );
      setState(() {
        _hastalar = hastalar;
        _filtrelenmis = hastalar;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  void _detayaGit(Patient hasta) async {
    final guncellendi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PatientDetailScreen(hasta: hasta)),
    );
    if (guncellendi == true) _hastalariYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hasta Listesi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B))),
        centerTitle: false,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: RefreshIndicator(
        onRefresh: _hastalariYukle,
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── Filtreli Arama Widget'i ─────────────────
              HastaAramaWidget(
                klinisyenId: widget.klinisyenId?.toString(),
                onHastaSecildi: (hasta) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(
                        hasta: Patient(
                          hastaId:     hasta.hastaId,
                          kullaniciId: 0,
                          ad:          hasta.ad,
                          soyad:       hasta.soyad,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Tam Liste ─────────────────────────────────
              if (_yukleniyor)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(
                        color: kPrimary)))
              else if (_hata != null)
                _hataEkrani()
              else if (_filtrelenmis.isEmpty)
                  _bosEkran()
                else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '${_filtrelenmis.length} HASTA',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8)),
                      ),
                    ),
                    ..._filtrelenmis.map((hasta) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HastaKarti(
                          hasta: hasta,
                          onTap: () => _detayaGit(hasta)),
                    )),
                  ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _hataEkrani() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Baglanti Hatasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_hata!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hastalariYukle,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosEkran() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.person_search, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Henuz hasta kaydi yok',
              style: TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ── Hasta Karti ───────────────────────────────────────────────
class _HastaKarti extends StatelessWidget {
  final Patient hasta;
  final VoidCallback onTap;
  const _HastaKarti({required this.hasta, required this.onTap});

  String _yas(String? dogumTarihi) {
    if (dogumTarihi == null) return '?';
    try {
      final d = DateTime.parse(dogumTarihi);
      final now = DateTime.now();
      int yas = now.year - d.year;
      if (now.month < d.month ||
          (now.month == d.month && now.day < d.day)) yas--;
      return '$yas';
    } catch (_) { return '?'; }
  }

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
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF0FDFA),
              child: Text(
                hasta.ad.isNotEmpty
                    ? hasta.ad[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasta.tamAd,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Etiket(label: hasta.hastalikAdi ?? 'Tani Yok'),
                    const SizedBox(width: 6),
                    _Etiket(
                      label: '${_yas(hasta.dogumTarihi)} yas',
                      renk: const Color(0xFF0F766E),
                      arkaplan: const Color(0xFFF0FDFA),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 3),
                    Text(hasta.adres ?? 'Adres yok',
                        style: const TextStyle(fontSize: 12,
                            color: Color(0xFF94A3B8))),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('#${hasta.hastaId}',
                    style: const TextStyle(fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Etiket ───────────────────────────────────────────────────
class _Etiket extends StatelessWidget {
  final String label;
  final Color renk;
  final Color arkaplan;
  const _Etiket({
    required this.label,
    this.renk = const Color(0xFF0F766E),
    this.arkaplan = const Color(0xFFF0FDFA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: arkaplan,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w500, color: renk)),
    );
  }
}