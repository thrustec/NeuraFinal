import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _hastalar = [];
  List<Patient> _filtrelenmis = [];
  bool _yukleniyor = true;
  String? _hata;
  final TextEditingController _aramaCtrl = TextEditingController();

  static const Color kPrimary = Color(0xFF2563EB);

  @override
  void initState() {  // sayfa yüklenirken verileri oto çekmek için Flutter'in yaşam döngüsü metodu
    super.initState();
    _hastalariYukle(); // ekran açılınca otomatik çalışır
  }

  @override
  void dispose() { // sayfa kapatıldığında arkada boşuna RAM tüketmesin diye dispose metodu ile bellekten temizlenir
    _aramaCtrl.dispose();
    super.dispose();
  }

  //veri yüklenirken yükleniyor animasyonu çıkması için
  Future<void> _hastalariYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final hastalar = await PatientService.getHastalar();
      setState(() {
        _hastalar = hastalar;
        _filtrelenmis = hastalar;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  // kullanıcı arama yaptığında her harfte veritabanına sorgu atmak yerine sadece _filtrelenmis güncelleniyor
  void _aramaYap(String sorgu) { // kullanıcı yazdıkça _filtrelenmis listesi güncelleniyor
    setState(() {
      if (sorgu.isEmpty) {
        _filtrelenmis = _hastalar;
      } else {
        final q = sorgu.toLowerCase();
        _filtrelenmis = _hastalar
            .where((h) =>
        h.tamAd.toLowerCase().contains(q) || //hem isim hem hasta ID
            h.hastaId.toString().contains(q))
            .toList();
      }
    });
  }

  void _detayaGit(Patient hasta) async {
    final guncellendi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PatientDetailScreen(hasta: hasta)),
    );
    if (guncellendi == true) _hastalariYukle(); // güncellendiyse listeyi yenile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _appBar(),
      bottomNavigationBar: _altMenu(),
      body: Column(
        children: [
          // ── Başlık + Arama ───────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_alt_outlined,
                        color: kPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Hasta Listesi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: _aramaCtrl,
                  onChanged: _aramaYap,
                  decoration: InputDecoration(
                    hintText: 'İsim veya hasta ID ile ara...',
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
                          _aramaYap('');
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
          ),
          const SizedBox(height: 1),
          Expanded(child: _govde()),
        ],
      ),
    );
  }

  Widget _govde() {
    if (_yukleniyor) {
      return const Center(
          child: CircularProgressIndicator(color: kPrimary));
    }

    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Bağlantı Hatası',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_hata!,
                  textAlign: TextAlign.center,
                  style:
                  const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hastalariYukle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
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

    if (_filtrelenmis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _aramaCtrl.text.isEmpty
                  ? 'Henüz hasta kaydı yok'
                  : '"${_aramaCtrl.text}" için sonuç bulunamadı',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _hastalariYukle,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('${_filtrelenmis.length} HASTA',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
          ),
          ..._filtrelenmis.map((hasta) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HastaKarti(
                hasta: hasta, onTap: () => _detayaGit(hasta)),
          )),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
        onPressed: () {},
      ),
      title: const Text('Hastalar',
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
          Positioned(
              right: 10,
              top: 10,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle))),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
              radius: 17,
              backgroundColor: kPrimary,
              child: const Text('AK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
          Container(color: const Color(0xFFE2E8F0), height: 1)),
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
      decoration: const BoxDecoration(
          color: Colors.white,
          border:
          Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
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
                      color: aktif
                          ? kPrimary
                          : const Color(0xFF94A3B8),
                      size: 22),
                  const SizedBox(height: 3),
                  Text(items[i]['label'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: aktif
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: aktif
                              ? kPrimary
                              : const Color(0xFF94A3B8))),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Hasta Kartı ──────────────────────────────────────────────
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
    } catch (_) {
      return '?';
    }
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
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                hasta.ad.isNotEmpty
                    ? hasta.ad[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasta.tamAd,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Etiket(
                        label: hasta.hastalikAdi ?? 'Tanı Yok'),
                    const SizedBox(width: 6),
                    _Etiket(
                      label: '${_yas(hasta.dogumTarihi)} yaş',
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
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8))),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('#${hasta.hastaId}',
                    style: const TextStyle(
                        fontSize: 11,
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

class _Etiket extends StatelessWidget {
  final String label;
  final Color renk;
  final Color arkaplan;
  const _Etiket({
    required this.label,
    this.renk = const Color(0xFF1D4ED8),
    this.arkaplan = const Color(0xFFEFF6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: arkaplan,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: renk)),
    );
  }
}