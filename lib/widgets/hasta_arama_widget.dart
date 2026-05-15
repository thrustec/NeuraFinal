import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/patient_service.dart';

class HastaAramaSonucu {
  final int hastaId;
  final String ad;
  final String soyad;
  final String? tani;

  HastaAramaSonucu({
    required this.hastaId,
    required this.ad,
    required this.soyad,
    this.tani,
  });

  String get tamAd => '$ad $soyad';
}

// Tanı modeli: dropdown için id+isim birlikte taşıyoruz
class _TaniItem {
  final int hastalikId;
  final String hastalikAdi;
  _TaniItem(this.hastalikId, this.hastalikAdi);
}

class HastaAramaWidget extends StatefulWidget {
  final String? klinisyenId;
  final Color primaryColor;
  final void Function(HastaAramaSonucu hasta) onHastaSecildi;

  const HastaAramaWidget({
    super.key,
    this.klinisyenId,
    this.primaryColor = const Color(0xFF0F766E),
    required this.onHastaSecildi,
  });

  @override
  State<HastaAramaWidget> createState() => _HastaAramaWidgetState();
}

class _HastaAramaWidgetState extends State<HastaAramaWidget> {
  static const Color kTextDark  = Color(0xFF1E293B);
  static const Color kTextGrey  = Color(0xFF64748B);
  static const Color kInputFill = Color(0xFFF1F5F9);

  Color get kPrimary => widget.primaryColor;

  final _idCtrl = TextEditingController();
  final _adCtrl = TextEditingController();

  List<HastaAramaSonucu> _sonuclar = [];

  // FIX 1: Tanı listesini id+isim olarak tut (text değil)
  List<_TaniItem> _tanilar         = [];
  _TaniItem? _seciliTani;

  bool _loading  = false;
  bool _searched = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _tanilarYukle();
    _idCtrl.addListener(_anlikAra);
    _adCtrl.addListener(_anlikAra);
  }

  @override
  void dispose() {
    _idCtrl.removeListener(_anlikAra);
    _adCtrl.removeListener(_anlikAra);
    _idCtrl.dispose();
    _adCtrl.dispose();
    super.dispose();
  }

  // FIX 1: hastaliklar tablosundan id+isim çek (text match değil, kesin ID filtresi için)
  Future<void> _tanilarYukle() async {
    try {
      final data = await Supabase.instance.client
          .schema('neura')
          .from('hastaliklar')
          .select('hastalikId, hastalikAdi')
          .order('hastalikAdi', ascending: true);

      final liste = (data as List).map((row) {
        return _TaniItem(
          row['hastalikId'] as int,
          row['hastalikAdi']?.toString() ?? '',
        );
      }).where((t) => t.hastalikAdi.isNotEmpty).toList();

      setState(() => _tanilar = liste);
    } catch (_) {}
  }

  void _anlikAra() {
    if (_idCtrl.text.isEmpty &&
        _adCtrl.text.isEmpty &&
        _seciliTani == null) {
      setState(() {
        _sonuclar = [];
        _searched = false;
      });
      return;
    }
    _ara();
  }

  Future<void> _ara() async {
    setState(() { _loading = true; _hata = null; });

    try {
      final klinisyenId = int.tryParse(widget.klinisyenId?.trim() ?? '');
      if (klinisyenId == null || klinisyenId <= 0) {
        setState(() {
          _sonuclar = [];
          _loading = false;
          _searched = true;
        });
        return;
      }
      var patients = await PatientService.getHastalar(
        klinisyenId: klinisyenId,
      );

      final idText = _idCtrl.text.trim();
      final nameText = _adCtrl.text.trim().toLowerCase();

      if (idText.isNotEmpty) {
        final id = int.tryParse(idText);
        patients = id == null
            ? []
            : patients.where((patient) => patient.hastaId == id).toList();
      }

      if (nameText.isNotEmpty) {
        patients = patients.where((patient) {
          return patient.tamAd.toLowerCase().contains(nameText) ||
              patient.ad.toLowerCase().contains(nameText) ||
              patient.soyad.toLowerCase().contains(nameText);
        }).toList();
      }

      if (_seciliTani != null) {
        final selectedDiagnosis = _seciliTani!.hastalikAdi.toLowerCase();
        patients = patients.where((patient) {
          return (patient.hastalikAdi ?? '').toLowerCase() == selectedDiagnosis;
        }).toList();
      }

      final liste = patients.take(20).map((patient) {
        return HastaAramaSonucu(
          hastaId: patient.hastaId,
          ad: patient.ad,
          soyad: patient.soyad,
          tani: patient.hastalikAdi,
        );
      }).toList();

      setState(() {
        _sonuclar = liste;
        _loading  = false;
        _searched = true;
      });
    } catch (e) {
      setState(() {
        _hata     = e.toString();
        _loading  = false;
        _searched = true;
      });
    }
  }

  void _temizle() {
    _idCtrl.clear();
    _adCtrl.clear();
    setState(() {
      _seciliTani = null;
      _sonuclar   = [];
      _searched   = false;
      _hata       = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX 3: Overflow — Column yerine hiç shrinkWrap yok;
    // parent'ın zaten scroll içinde olduğunu varsayıyoruz (SingleChildScrollView).
    // Widget tamamen Column'dur, içinde sabit yükseklik yoktur.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── Arama Bloğu ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // Başlık + Temizle
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.manage_search,
                        color: kPrimary, size: 18)),
                const SizedBox(width: 10),
                const Text('Hasta Ara',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextDark)),
                const Spacer(),
                if (_searched || _seciliTani != null)
                  TextButton(
                    onPressed: _temizle,
                    child: Text('Temizle',
                        style: TextStyle(color: kPrimary, fontSize: 13)),
                  ),
              ]),
              const SizedBox(height: 14),

              // ID + Ad Soyad yan yana
              Row(children: [
                Expanded(
                  flex: 1,
                  child: _aramaAlani(
                    ctrl: _idCtrl,
                    label: 'HASTA ID',
                    hint: 'ID giriniz',
                    ikon: Icons.tag,
                    klavye: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _aramaAlani(
                    ctrl: _adCtrl,
                    label: 'AD SOYAD',
                    hint: 'Hasta adı yazın...',
                    ikon: Icons.person_outline,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _ara,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'Ara',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // FIX 2: Tanı Dropdown — beyaz arka plan, açık tema
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TANI',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kTextGrey,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kInputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _seciliTani != null
                              ? kPrimary
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_TaniItem?>(
                        value: _seciliTani,
                        // FIX 2: Dropdown popup'ı beyaz yap
                        dropdownColor: Colors.white,
                        hint: Row(children: [
                          Icon(Icons.medical_information_outlined,
                              color: const Color(0xFF94A3B8), size: 16),
                          const SizedBox(width: 8),
                          const Text('Tanı seçin (opsiyonel)',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13)),
                        ]),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: _seciliTani != null
                                ? kPrimary
                                : const Color(0xFF94A3B8)),
                        style: const TextStyle(
                            fontSize: 14, color: kTextDark),
                        // FIX 2: Her item'ın arka planı da beyaz
                        items: [
                          DropdownMenuItem<_TaniItem?>(
                            value: null,
                            child: Text('Tümü',
                                style: TextStyle(
                                    color: kTextGrey, fontSize: 14)),
                          ),
                          ..._tanilar.map((t) => DropdownMenuItem<_TaniItem?>(
                            value: t,
                            child: Text(t.hastalikAdi,
                                style: const TextStyle(
                                    fontSize: 14, color: kTextDark)),
                          )),
                        ],
                        onChanged: (v) {
                          setState(() => _seciliTani = v);
                          _anlikAra();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Sonuçlar ────────────────────────────────────────
        if (_searched) ...[
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              if (_loading)
                SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: kPrimary, strokeWidth: 2))
              else
                Text(
                    _hata != null
                        ? 'Hata oluştu'
                        : '${_sonuclar.length} SONUÇ',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _hata != null ? Colors.red : kTextGrey,
                        letterSpacing: 0.5)),
            ]),
          ),

          if (_loading)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
            ))
          else if (_hata != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('Arama hatası. Lütfen tekrar deneyin.',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
            )
          else if (_sonuclar.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Icon(Icons.search_off, color: kTextGrey, size: 20),
                  const SizedBox(width: 10),
                  const Text('Eşleşen hasta bulunamadı.',
                      style: TextStyle(fontSize: 13, color: kTextGrey)),
                ]),
              )
            else
            // FIX 3: ListView yerine Column — parent zaten scroll içinde
              Column(
                mainAxisSize: MainAxisSize.min,
                children: _sonuclar.map((hasta) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => widget.onHastaSecildi(hasta),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0))),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: kPrimary.withValues(alpha: 0.1),
                              child: Text(
                                  hasta.ad.isNotEmpty
                                      ? hasta.ad[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hasta.tamAd,
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kTextDark)),
                                if (hasta.tani != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(hasta.tani!,
                                        style: const TextStyle(
                                            fontSize: 12, color: kTextGrey)),
                                  ),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('#${hasta.hastaId}',
                                  style: TextStyle(fontSize: 11,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFFCBD5E1), size: 18),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
        ],
      ],
    );
  }

  Widget _aramaAlani({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData ikon,
    TextInputType? klavye,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kTextGrey,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: klavye,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _ara(),
          style: const TextStyle(fontSize: 14, color: kTextDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(ikon, color: const Color(0xFF94A3B8), size: 17),
            filled: true,
            fillColor: kInputFill,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kPrimary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
