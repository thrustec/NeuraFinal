import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<String> _tanilar            = [];
  String? _seciliTani;
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

  // Tani dropdown — v_hasta_listesi'ndeki sontani kolonundan cek
  Future<void> _tanilarYukle() async {
    try {
      final data = await Supabase.instance.client
          .schema('neura')
          .from('v_hasta_listesi')
          .select('sonTani')
          .not('sonTani', 'is', null);

      final taniSet = <String>{};
      for (final row in (data as List)) {
        final t = row['sonTani'];
        if (t != null) taniSet.add(t.toString());
      }

      setState(() {
        _tanilar = taniSet.toList()..sort();
      });
    } catch (_) {
      // Sessizce devam et
    }
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
      var sorgu = Supabase.instance.client
          .schema('neura')
          .from('v_hasta_listesi')
          .select('hastaId, ad, soyad, tamAd, sonTani, klinisyenId');

      // Klinisyene ozel filtre
      if (widget.klinisyenId != null) {
        sorgu = sorgu.eq('klinisyenId',
            int.tryParse(widget.klinisyenId!) ?? 0);
      }

      // ID filtresi
      if (_idCtrl.text.isNotEmpty) {
        final id = int.tryParse(_idCtrl.text.trim());
        if (id != null) sorgu = sorgu.eq('hastaId', id);
      }

      // Ad/soyad filtresi
      if (_adCtrl.text.isNotEmpty) {
        final q = _adCtrl.text.trim();
        sorgu = sorgu.or('ad.ilike.%$q%,soyad.ilike.%$q%');
      }

      // Tani filtresi — sonTani kolonu
      if (_seciliTani != null) {
        sorgu = sorgu.ilike('sonTani', '%$_seciliTani%');
      }

      final data = await sorgu
          .order('ad', ascending: true)
          .limit(20);

      final liste = (data as List).map((row) {
        return HastaAramaSonucu(
          hastaId: row['hastaId'] ?? 0,
          ad:      row['ad'] ?? '',
          soyad:   row['soyad'] ?? '',
          tani:    row['sonTani'],
        );
      }).toList();

      setState(() {
        _sonuclar = liste;
        _loading  = false;
        _searched = true;
      });
    } catch (e) {
      setState(() {
        _hata    = e.toString();
        _loading = false;
        _searched = true;
      });
    }
  }

  void _temizle() {
    setState(() {
      _idCtrl.clear();
      _adCtrl.clear();
      _seciliTani = null;
      _sonuclar   = [];
      _searched   = false;
      _hata       = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Arama Blogu ─────────────────────────────────────
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
            children: [

              // Baslik + Temizle
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
                        style: TextStyle(
                            color: kPrimary, fontSize: 13)),
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
                    hint: 'Hasta adi yazin...',
                    ikon: Icons.person_outline,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Tani Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: DropdownButton<String>(
                        value: _seciliTani,
                        hint: Row(children: [
                          Icon(Icons.medical_information_outlined,
                              color: const Color(0xFF94A3B8), size: 16),
                          const SizedBox(width: 8),
                          const Text('Tani secin (opsiyonel)',
                              style: TextStyle(
                                  color: Color(0xFFCBD5E1), fontSize: 13)),
                        ]),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: _seciliTani != null
                                ? kPrimary
                                : const Color(0xFF94A3B8)),
                        style: const TextStyle(
                            fontSize: 14, color: kTextDark),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tumu',
                                style: TextStyle(
                                    color: kTextGrey, fontSize: 14)),
                          ),
                          ..._tanilar.map((t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t,
                                style: const TextStyle(fontSize: 14)),
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

        // ── Sonuclar ────────────────────────────────────────
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
                        ? 'Hata olustu'
                        : '${_sonuclar.length} SONUC',
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kTextGrey,
                        letterSpacing: 0.8)),
            ]),
          ),

          if (_hata != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_hata!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12))),
              ]),
            )
          else if (!_loading && _sonuclar.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(child: Column(children: [
                Icon(Icons.person_search,
                    size: 40, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text('Sonuc bulunamadi',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 14)),
              ])),
            )
          else if (!_loading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sonuclar.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (_, i) {
                    final hasta = _sonuclar[i];
                    return InkWell(
                      onTap: () => widget.onHastaSecildi(hasta),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                            kPrimary.withValues(alpha: 0.1),
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
                                          fontSize: 12,
                                          color: kTextGrey)),
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
                    );
                  },
                ),
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
      children: [
        Text(label, style: const TextStyle(fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kTextGrey, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: klavye,
          style: const TextStyle(fontSize: 14, color: kTextDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: Icon(ikon,
                color: const Color(0xFF94A3B8), size: 16),
            filled: true,
            fillColor: kInputFill,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
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