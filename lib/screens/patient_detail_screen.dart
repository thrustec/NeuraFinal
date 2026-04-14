import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/evaluation_model.dart';
import '../services/patient_service.dart';
import '../services/empatica_service.dart';
import 'empatica_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient hasta;
  const PatientDetailScreen({super.key, required this.hasta});

  @override
  State<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Patient _hasta;
  bool _duzenleniyor = false;
  bool _kaydediliyor = false;

  // Değerlendirme geçmişi
  List<Evaluation> _degerlendirmeler = [];
  bool _degerlendirmeYukleniyor = true;

  static const Color kPrimary = Color(0xFF2563EB);

  late TextEditingController _boyCtrl;
  late TextEditingController _kiloCtrl;
  late TextEditingController _klinisyenNotlariCtrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _hasta = widget.hasta;
    _controllerBaslat();
    _degerlendirmeleriYukle();
  }

  void _controllerBaslat() {
    _boyCtrl  = TextEditingController(
        text: _hasta.boy?.toStringAsFixed(1) ?? '');
    _kiloCtrl = TextEditingController(
        text: _hasta.kilo?.toStringAsFixed(1) ?? '');
    _klinisyenNotlariCtrl =
        TextEditingController(text: _hasta.klinisyenNotlari ?? '');
  }

  Future<void> _degerlendirmeleriYukle() async {
    try {
      final liste =
      await EmpaticaService.getDegerlendirmeler(_hasta.hastaId);
      setState(() {
        _degerlendirmeler = liste;
        _degerlendirmeYukleniyor = false;
      });
    } catch (_) {
      setState(() => _degerlendirmeYukleniyor = false);
    }
  }

  @override
  void dispose() {
    _boyCtrl.dispose();
    _kiloCtrl.dispose();
    _klinisyenNotlariCtrl.dispose();
    super.dispose();
  }

  void _duzenlemeToggle() {
    setState(() {
      if (_duzenleniyor) _controllerBaslat();
      _duzenleniyor = !_duzenleniyor;
    });
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);

    try {
      final data = {
        'boy':             double.tryParse(_boyCtrl.text),
        'kilo':            double.tryParse(_kiloCtrl.text),
        'klinisyenNotlari': _klinisyenNotlariCtrl.text.trim(),
      };

      final basarili =
      await PatientService.hastaGuncelle(_hasta.hastaId, data);

      if (basarili) {
        setState(() {
          _hasta = _hasta.copyWith(
            boy:             double.tryParse(_boyCtrl.text),
            kilo:            double.tryParse(_kiloCtrl.text),
            klinisyenNotlari: _klinisyenNotlariCtrl.text.trim(),
          );
          _duzenleniyor = false;
          _kaydediliyor = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Klinik bilgiler güncellendi'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _kaydediliyor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _yasHesapla(String? dogumTarihi) {
    if (dogumTarihi == null) return 'Bilinmiyor';
    try {
      final d = DateTime.parse(dogumTarihi);
      final now = DateTime.now();
      int yas = now.year - d.year;
      if (now.month < d.month ||
          (now.month == d.month && now.day < d.day)) yas--;
      return '$yas yaşında';
    } catch (_) {
      return dogumTarihi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      bottomNavigationBar: _altMenu(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Özet Kart ──────────────────────────────────
              _ozetKart(),
              const SizedBox(height: 14),

              // ── Hızlı Erişim Butonları ─────────────────────
              _hizliErisim(),
              const SizedBox(height: 14),

              // ── Kişisel Bilgiler (salt okunur) ─────────────
              _bolum(
                ikon: Icons.person_outline,
                baslik: 'Kişisel Bilgiler',
                altyazi: 'Bölüm 1 / 4',
                rozet: null,
                icerik: [
                  _satirIkili(
                    sol: _sabit('AD', _hasta.ad),
                    sag: _sabit('SOYAD', _hasta.soyad),
                  ),
                  _satirIkili(
                    sol: _sabit('CİNSİYET',
                        _hasta.cinsiyetAdi ?? '-'),
                    sag: _sabit('MEDENİ DURUM',
                        _hasta.medeniDurumAdi ?? '-'),
                  ),
                  _sabit('DOĞUM TARİHİ / YAŞ',
                      '${_hasta.dogumTarihi ?? '-'}  '
                          '(${_yasHesapla(_hasta.dogumTarihi)})'),
                  _sabit('ADRES / İL', _hasta.adres ?? '-'),
                  _sabit('TELEFON', _hasta.telefonNo ?? '-'),
                  _satirIkili(
                    sol: _sabit('EĞİTİM',
                        _hasta.egitimDurumAdi ?? '-'),
                    sag: _sabit('MESLEK',
                        _hasta.meslekAdi ?? '-'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Klinik Bilgiler (klinisyen düzenleyebilir) ─
              _bolum(
                ikon: Icons.medical_services_outlined,
                baslik: 'Klinik Bilgiler',
                altyazi: 'Bölüm 2 / 4',
                rozet: _duzenleniyor ? 'Düzenleniyor' : null,
                icerik: [
                  _sabit('TANI', _hasta.hastalikAdi ?? '-'),
                  _satirIkili(
                    sol: _duzenlenebilir('BOY (CM)', _boyCtrl,
                        klavyeTipi: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.isNotEmpty &&
                              double.tryParse(v) == null) {
                            return 'Geçersiz';
                          }
                          return null;
                        }),
                    sag: _duzenlenebilir('KİLO (KG)', _kiloCtrl,
                        klavyeTipi: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.isNotEmpty &&
                              double.tryParse(v) == null) {
                            return 'Geçersiz';
                          }
                          return null;
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Notlar (klinisyen düzenleyebilir) ──────────
              _bolum(
                ikon: Icons.notes_outlined,
                baslik: 'Notlar',
                altyazi: 'Bölüm 3 / 4',
                rozet: _duzenleniyor ? 'Düzenleniyor' : null,
                icerik: [
                  _sabit('HASTA NOTLARI',
                      _hasta.notlar ?? '-'),
                  _duzenlenebilir(
                    'KLİNİSYEN DEĞERLENDİRME NOTU',
                    _klinisyenNotlariCtrl,
                    maxSatir: 3,
                    ipucu: 'Değerlendirme notunuzu girin...',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Değerlendirme Geçmişi ──────────────────────
              _degerlendirmeGecmisi(),
              const SizedBox(height: 24),

              // ── Kaydet Butonu ──────────────────────────────
              if (_duzenleniyor)
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Kaydet ve Devam Et',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hızlı Erişim Butonları ──────────────────────────────────
  Widget _hizliErisim() {
    return Row(
      children: [
        Expanded(
          child: _hizliButon(
            ikon: Icons.monitor_heart_outlined,
            etiket: 'Empatica\nİzleme',
            renk: const Color(0xFF0F766E),
            arkaplan: const Color(0xFFF0FDFA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EmpaticaScreen(hasta: _hasta),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _hizliButon(
            ikon: Icons.assignment_outlined,
            etiket: 'Değerlendirme\nBaşlat',
            renk: kPrimary,
            arkaplan: const Color(0xFFEFF6FF),
            // Değerlendirme ekranı başka bir grup üyesinde
            // Bağlantı merge sırasında yapılacak
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _hizliButon(
            ikon: Icons.fitness_center_outlined,
            etiket: 'Egzersiz\nProgramı',
            renk: const Color(0xFF9333EA),
            arkaplan: const Color(0xFFFAF5FF),
            // Egzersiz ekranı başka bir grup üyesinde
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _hizliButon({
    required IconData ikon,
    required String etiket,
    required Color renk,
    required Color arkaplan,
    required VoidCallback onTap,
  }) {
    return Material(
      color: arkaplan,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: renk.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(ikon, color: renk, size: 26),
              const SizedBox(height: 6),
              Text(etiket,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: renk,
                    height: 1.3,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Değerlendirme Geçmişi Bölümü ───────────────────────────
  Widget _degerlendirmeGecmisi() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history,
                    color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Değerlendirme Geçmişi',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                    Text('Bölüm 4 / 4',
                        style: TextStyle(fontSize: 12,
                            color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              if (_degerlendirmeler.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      '${_degerlendirmeler.length} kayıt',
                      style: const TextStyle(fontSize: 11,
                          color: kPrimary,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          if (_degerlendirmeYukleniyor)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(
                  color: kPrimary)),
            )
          else if (_degerlendirmeler.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Henüz değerlendirme kaydı yok',
                    style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _degerlendirmeler.length > 3
                      ? 3
                      : _degerlendirmeler.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (_, i) =>
                      _degerlendirmeKarti(_degerlendirmeler[i]),
                ),
                  InkWell(
                    onTap: () {
                      // Merge sonrası arkadaşın ekranına bağlanacak
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Tümünü Gör',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              )),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 13, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _degerlendirmeKarti(Evaluation d) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(d.formatliTarih,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            const Spacer(),
            if (d.hastalikAdi != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(d.hastalikAdi!,
                    style: const TextStyle(fontSize: 11,
                        color: kPrimary,
                        fontWeight: FontWeight.w500)),
              ),
          ]),
          if (d.klinisyenNotlari != null &&
              d.klinisyenNotlari!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d.klinisyenNotlari!,
                style: const TextStyle(fontSize: 13,
                    color: Color(0xFF475569))),
          ],
          if (d.kullanilanIlaclar != null &&
              d.kullanilanIlaclar!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.medication_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(d.kullanilanIlaclar!,
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF94A3B8))),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // ─── Yardımcı Widget'lar ─────────────────────────────────────

  Widget _ozetKart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
              _hasta.ad.isNotEmpty ? _hasta.ad[0] : '?',
              style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold, color: kPrimary)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_hasta.tamAd,
                style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 3),
            Text(_hasta.eposta ?? 'E-posta yok',
                style: const TextStyle(fontSize: 13,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_hasta.hastalikAdi ?? 'Tanı Yok',
                  style: const TextStyle(fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        )),
        Text('#${_hasta.hastaId}',
            style: const TextStyle(fontSize: 12,
                color: Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _bolum({
    required IconData ikon,
    required String baslik,
    required String altyazi,
    required List<Widget> icerik,
    String? rozet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
                  Text(altyazi, style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              )),
              if (rozet != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(rozet, style: const TextStyle(
                      fontSize: 10, color: kPrimary,
                      fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: icerik),
          ),
        ],
      ),
    );
  }

  Widget _satirIkili({required Widget sol, required Widget sag}) {
    return Row(children: [
      Expanded(child: sol),
      const SizedBox(width: 12),
      Expanded(child: sag),
    ]);
  }

  Widget _sabit(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(deger, style: const TextStyle(
                fontSize: 14, color: Color(0xFF475569))),
          ),
        ],
      ),
    );
  }

  Widget _duzenlenebilir(
      String etiket,
      TextEditingController ctrl, {
        TextInputType? klavyeTipi,
        int maxSatir = 1,
        String? ipucu,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          if (!_duzenleniyor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                  ctrl.text.isEmpty ? '-' : ctrl.text,
                  style: const TextStyle(fontSize: 14,
                      color: Color(0xFF475569))),
            )
          else
            TextFormField(
              controller: ctrl,
              keyboardType: klavyeTipi,
              maxLines: maxSatir,
              validator: validator,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: ipucu,
                hintStyle: const TextStyle(
                    color: Color(0xFFCBD5E1), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: kPrimary, width: 1.5)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Colors.red, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Hasta Detayı',
          style: TextStyle(color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600, fontSize: 18)),
      centerTitle: false,
      actions: [
        if (!_kaydediliyor)
          TextButton(
            onPressed: _duzenlemeToggle,
            child: Text(_duzenleniyor ? 'İptal' : 'Düzenle',
                style: const TextStyle(color: kPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          Positioned(right: 10, top: 10,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle))),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(radius: 17,
              backgroundColor: kPrimary,
              child: const Text('AK', style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.bold))),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1)),
    );
  }

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
              final aktif = i == 1;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i]['icon'] as IconData,
                      color: aktif ? kPrimary : const Color(0xFF94A3B8),
                      size: 22),
                  const SizedBox(height: 3),
                  Text(items[i]['label'] as String,
                      style: TextStyle(fontSize: 10,
                          fontWeight: aktif
                              ? FontWeight.w600 : FontWeight.normal,
                          color: aktif
                              ? kPrimary : const Color(0xFF94A3B8))),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
