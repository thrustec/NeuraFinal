import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/biyo_sensor_model.dart';
import '../services/empatica_service.dart';

class EmpaticaScreen extends StatefulWidget {
  final Patient hasta;
  const EmpaticaScreen({super.key, required this.hasta});

  @override
  State<EmpaticaScreen> createState() => _EmpaticaScreenState();
}

class _EmpaticaScreenState extends State<EmpaticaScreen> {
  List<BiyoSensorVeri> _veriler = [];
  bool _yukleniyor = true;
  String? _hata;

  BiyoSensorVeri? get _sonVeri =>
      _veriler.isNotEmpty ? _veriler.first : null;

  static const Color kPrimary = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final veriler = await EmpaticaService.getBiyoSensorVerileri(
          widget.hasta.hastaId);
      setState(() {
        _veriler = veriler.reversed.toList();
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(
          color: kPrimary))
          : _hata != null
          ? _hataEkrani()
          : _veriler.isEmpty
          ? _bosEkran()
          : _icerik(),
    );
  }

  Widget _icerik() {
    return RefreshIndicator(
      onRefresh: _verileriYukle,
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hastaOzet(),
            const SizedBox(height: 14),
            const Text('SON ÖLÇÜM',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            if (_sonVeri != null) _sonOlcumGrid(_sonVeri!),
            const SizedBox(height: 14),
            const Text('ÖLÇÜM GEÇMİŞİ',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ..._veriler.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _olcumKarti(v),
            )),
          ],
        ),
      ),
    );
  }

  Widget _hastaOzet() {
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
          backgroundColor: kPrimary.withOpacity(0.1),
          child: Text(
              widget.hasta.ad.isNotEmpty
                  ? widget.hasta.ad[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.bold, color: kPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hasta.tamAd,
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(widget.hasta.hastalikAdi ?? 'Tanı Yok',
                style: const TextStyle(fontSize: 13,
                    color: Color(0xFF64748B))),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    )),
                const SizedBox(width: 4),
                const Text('Empatica',
                    style: TextStyle(fontSize: 11,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 4),
            Text('${_veriler.length} ölçüm',
                style: const TextStyle(fontSize: 11,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      ]),
    );
  }

  Widget _sonOlcumGrid(BiyoSensorVeri v) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _metrikKart(
          ikon: Icons.favorite_outline,
          etiket: 'Kalp Hızı',
          deger: v.kalpAtisHizi != null
              ? '${v.kalpAtisHizi!.toStringAsFixed(0)}'
              : '-',
          birim: 'BPM',
          renk: Colors.red,
          arkaplan: const Color(0xFFFFF1F2),
        ),
        _metrikKart(
          ikon: Icons.bolt_outlined,
          etiket: 'EDA',
          deger: v.eda != null
              ? v.eda!.toStringAsFixed(1)
              : '-',
          birim: 'µS',
          renk: const Color(0xFFD97706),
          arkaplan: const Color(0xFFFFFBEB),
        ),
        _metrikKart(
          ikon: Icons.thermostat_outlined,
          etiket: 'Sıcaklık',
          deger: v.sicaklik != null
              ? v.sicaklik!.toStringAsFixed(1)
              : '-',
          birim: '°C',
          renk: const Color(0xFF0891B2),
          arkaplan: const Color(0xFFECFEFF),
        ),
        _metrikKart(
          ikon: Icons.water_drop_outlined,
          etiket: 'Kan O₂',
          deger: v.kanOksijeni != null
              ? '${v.kanOksijeni!.toStringAsFixed(1)}'
              : '-',
          birim: 'SpO₂%',
          renk: const Color(0xFF7C3AED),
          arkaplan: const Color(0xFFF5F3FF),
        ),
        _metrikKart(
          ikon: Icons.vibration_outlined,
          etiket: 'İvme',
          deger: v.ivmeZ != null
              ? v.ivmeZ!.toStringAsFixed(1)
              : '-',
          birim: 'm/s²',
          renk: const Color(0xFF0F766E),
          arkaplan: const Color(0xFFF0FDFA),
        ),
        _metrikKart(
          ikon: Icons.nightlight_outlined,
          etiket: 'Uyku',
          deger: v.uykuEvresi ?? '-',
          birim: '',
          renk: const Color(0xFF475569),
          arkaplan: const Color(0xFFF8FAFC),
        ),
      ],
    );
  }

  Widget _metrikKart({
    required IconData ikon,
    required String etiket,
    required String deger,
    required String birim,
    required Color renk,
    required Color arkaplan,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: arkaplan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, color: renk, size: 20),
          const SizedBox(height: 4),
          Text(deger,
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: renk)),
          if (birim.isNotEmpty)
            Text(birim,
                style: TextStyle(fontSize: 9,
                    color: renk.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(etiket,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9,
                  color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _olcumKarti(BiyoSensorVeri v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time,
                size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(v.formatliZaman,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            if (v.uykuEvresi != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: Text(v.uykuEvresi!,
                    style: const TextStyle(fontSize: 11,
                        color: Color(0xFF475569))),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _satirMetrik(Icons.favorite_outline,
                Colors.red, 'Kalp',
                v.kalpAtisHizi != null
                    ? '${v.kalpAtisHizi!.toStringAsFixed(0)} BPM'
                    : '-'),
            const SizedBox(width: 16),
            _satirMetrik(Icons.thermostat_outlined,
                const Color(0xFF0891B2), 'Sıcaklık',
                v.sicaklik != null
                    ? '${v.sicaklik!.toStringAsFixed(1)} °C'
                    : '-'),
            const SizedBox(width: 16),
            _satirMetrik(Icons.water_drop_outlined,
                const Color(0xFF7C3AED), 'SpO₂',
                v.kanOksijeni != null
                    ? '${v.kanOksijeni!.toStringAsFixed(1)}%'
                    : '-'),
          ]),
          if (v.eda != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              _satirMetrik(Icons.bolt_outlined,
                  const Color(0xFFD97706), 'EDA',
                  '${v.eda!.toStringAsFixed(1)} µS'),
              if (v.ivmeZ != null) ...[
                const SizedBox(width: 16),
                _satirMetrik(Icons.vibration_outlined,
                    const Color(0xFF0F766E), 'İvme',
                    '${v.ivmeZ!.toStringAsFixed(1)} m/s²'),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  Widget _satirMetrik(IconData ikon, Color renk,
      String etiket, String deger) {
    return Row(children: [
      Icon(ikon, size: 13, color: renk),
      const SizedBox(width: 3),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket,
              style: const TextStyle(fontSize: 9,
                  color: Color(0xFF94A3B8))),
          Text(deger,
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
        ],
      ),
    ]);
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
            const Text('Veri yüklenemedi',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_hata!, textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verileriYukle,
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
          Icon(Icons.monitor_heart_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Henüz sensör verisi yok',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          const Text('Empatica cihazı bağlandığında\nveriler burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8))),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Empatica İzleme',
              style: TextStyle(color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600, fontSize: 18)),
          Text(widget.hasta.tamAd,
              style: const TextStyle(color: Color(0xFF94A3B8),
                  fontSize: 12, fontWeight: FontWeight.normal)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh,
              color: Color(0xFF1E293B)),
          onPressed: _verileriYukle,
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
                      color: Colors.red,
                      shape: BoxShape.circle))),
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
          child: Container(
              color: const Color(0xFFE2E8F0), height: 1)),
    );
  }
}