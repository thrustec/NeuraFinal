import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/biyo_sensor_model.dart';
import '../services/empatica_service.dart';
import 'package:intl/intl.dart';

class EmpaticaScreen extends StatefulWidget {
  final Patient hasta;
  const EmpaticaScreen({super.key, required this.hasta});

  @override
  State<EmpaticaScreen> createState() => _EmpaticaScreenState();
}

class _EmpaticaScreenState extends State<EmpaticaScreen> {
  List<BiyoSensorVeri> _tumVeriler = [];
  List<BiyoSensorVeri> _filtrelenmisVeriler = [];
  bool _yukleniyor = true;
  String? _hata;
  DateTime? _seciliTarih;

  static const Color kPrimary = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final veriler = await EmpaticaService.getBiyoSensorVerileri(widget.hasta.hastaId);
      setState(() {
        _tumVeriler = veriler.reversed.toList();
        _filtrelenmisVeriler = _tumVeriler;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  Map<String, double> _ortalamaHesapla() {
    if (_filtrelenmisVeriler.isEmpty) return {};
    double tK = 0, tE = 0, tS = 0, tO = 0, tI = 0;
    int cK = 0, cE = 0, cS = 0, cO = 0, cI = 0;

    for (var v in _filtrelenmisVeriler) {
      if (v.kalpAtisHizi != null) { tK += v.kalpAtisHizi!; cK++; }
      if (v.eda != null) { tE += v.eda!; cE++; }
      if (v.sicaklik != null) { tS += v.sicaklik!; cS++; }
      if (v.kanOksijeni != null) { tO += v.kanOksijeni!; cO++; }
      if (v.ivmeZ != null) { tI += v.ivmeZ!; cI++; }
    }
    return {
      'kalp': cK > 0 ? tK / cK : 0,
      'eda': cE > 0 ? tE / cE : 0,
      'sicaklik': cS > 0 ? tS / cS : 0,
      'oksijen': cO > 0 ? tO / cO : 0,
      'ivme': cI > 0 ? tI / cI : 0,
    };
  }

  void _tarihFiltrele(DateTime tarih) {
    setState(() {
      _seciliTarih = tarih;
      _filtrelenmisVeriler = _tumVeriler.where((v) {
        final d = DateTime.parse(v.olcumZamani);
        return d.year == tarih.year && d.month == tarih.month && d.day == tarih.day;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _hata != null
          ? _hataEkrani()
          : _icerik(),
    );
  }

  Widget _icerik() {
    final ort = _ortalamaHesapla();

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hasta Özet (Kutucuklu Tasarım) ──
            _hastaOzetKutusu(),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_seciliTarih == null ? 'GENEL ORTALAMA' : 'GÜNLÜK ORTALAMA',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                _filtreButonu(),
              ],
            ),
            const SizedBox(height: 12),

            // 2x3 Grid (Ortalamalar)
            _metrikGrid(ort),

            const SizedBox(height: 28),
            const Text('ÖLÇÜM GEÇMİŞİ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            const SizedBox(height: 12),
            _filtrelenmisVeriler.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Veri bulunamadı.')))
                : Column(
              children: _filtrelenmisVeriler.map((v) => _olcumKarti(v)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hastaOzetKutusu() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(widget.hasta.ad[0].toUpperCase(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hasta.tamAd,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(widget.hasta.hastalikAdi ?? 'Tanı Yok',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0F766E), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Empatica', style: TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 4),
            Text('${_filtrelenmisVeriler.length} ölçüm', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        if (_seciliTarih != null)
          IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () => setState(() { _seciliTarih = null; _filtrelenmisVeriler = _tumVeriler; })),
      ]),
    );
  }

  Widget _metrikGrid(Map<String, double> ort) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _metrikKart(Icons.favorite_outline, 'Kalp Hızı', '${ort['kalp']?.toStringAsFixed(0) ?? '-'}', 'BPM', Colors.red, const Color(0xFFFFF1F2)),
        _metrikKart(Icons.bolt_outlined, 'EDA', '${ort['eda']?.toStringAsFixed(1) ?? '-'}', 'µS', Colors.orange, const Color(0xFFFFFBEB)),
        _metrikKart(Icons.thermostat_outlined, 'Sıcaklık', '${ort['sicaklik']?.toStringAsFixed(1) ?? '-'}', '°C', Colors.cyan, const Color(0xFFECFEFF)),
        _metrikKart(Icons.water_drop_outlined, 'Kan O₂', '${ort['oksijen']?.toStringAsFixed(1) ?? '-'}', 'SpO₂%', Colors.deepPurple, const Color(0xFFF5F3FF)),
        _metrikKart(Icons.vibration_outlined, 'İvme', '${ort['ivme']?.toStringAsFixed(1) ?? '-'}', 'm/s²', kPrimary, const Color(0xFFF0FDFA)),
        _metrikKart(Icons.nightlight_outlined, 'Uyku', _filtrelenmisVeriler.isNotEmpty ? (_filtrelenmisVeriler.first.uykuEvresi ?? '-') : '-', '', Colors.blueGrey, const Color(0xFFF8FAFC)),
      ],
    );
  }

  Widget _metrikKart(IconData ikon, String etiket, String deger, String birim, Color renk, Color arkaplan) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: arkaplan, borderRadius: BorderRadius.circular(12), border: Border.all(color: renk.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, color: renk, size: 20),
          const SizedBox(height: 6),
          Text(deger, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: renk)),
          if (birim.isNotEmpty) Text(birim, style: TextStyle(fontSize: 9, color: renk.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(etiket, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _olcumKarti(BiyoSensorVeri v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time, size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(v.formatliZaman, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kucukMetrik('Kalp', '${v.kalpAtisHizi?.toStringAsFixed(0) ?? '-'}', Colors.red),
              _kucukMetrik('EDA', '${v.eda?.toStringAsFixed(1) ?? '-'}', Colors.orange),
              _kucukMetrik('Sıcaklık', '${v.sicaklik?.toStringAsFixed(1) ?? '-'}', Colors.cyan),
              _kucukMetrik('SpO₂', '${v.kanOksijeni?.toStringAsFixed(1) ?? '-'}', Colors.deepPurple),
              _kucukMetrik('İvme', '${v.ivmeZ?.toStringAsFixed(1) ?? '-'}', kPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kucukMetrik(String etiket, String deger, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        Text(deger, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: renk)),
      ],
    );
  }

  Widget _filtreButonu() {
    return ActionChip(
      onPressed: () async {
        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
        if (date != null) _tarihFiltrele(date);
      },
      avatar: Icon(Icons.calendar_month, size: 14, color: _seciliTarih == null ? kPrimary : Colors.white),
      label: Text(_seciliTarih == null ? 'Filtrele' : DateFormat('dd.MM.yyyy').format(_seciliTarih!),
          style: TextStyle(fontSize: 11, color: _seciliTarih == null ? kPrimary : Colors.white)),
      backgroundColor: _seciliTarih == null ? kPrimary.withOpacity(0.1) : kPrimary,
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18), onPressed: () => Navigator.pop(context)),
      title: const Text('Empatica Analiz', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _hataEkrani() => Center(child: Text('Hata: $_hata'));
}