import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AyarlarScreen extends StatefulWidget {
  const AyarlarScreen({super.key});

  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark   = Color(0xFF1E293B);
  static const Color kTextGrey   = Color(0xFF64748B);
  static const Color kPrimary    = Color(0xFF0F766E);

  bool _genelBildirim        = true;
  bool _degerlendirmeBildirim = true;
  bool _ajandaBildirim        = true;
  String _seciliDil           = 'Türkçe';
  bool _yukleniyor            = true;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  // SharedPreferences'tan ayarları oku
  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _genelBildirim        = prefs.getBool('bildirim_genel')        ?? true;
      _degerlendirmeBildirim = prefs.getBool('bildirim_degerlendirme') ?? true;
      _ajandaBildirim       = prefs.getBool('bildirim_ajanda')       ?? true;
      _seciliDil            = prefs.getString('dil')                 ?? 'Türkçe';
      _yukleniyor           = false;
    });
  }

  // Her toggle değişince SharedPreferences'a kaydet
  Future<void> _kaydet(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _dilKaydet(String dil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dil', dil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kTextDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ayarlar',
            style: TextStyle(
                color: kTextDark,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: _yukleniyor
          ? const Center(
          child: CircularProgressIndicator(
              color: kPrimary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Bildirimler ─────────────────────────────
            _baslik('Bildirimler'),
            const SizedBox(height: 10),
            _kart([
              _toggle(
                ikon: Icons.notifications_outlined,
                baslik: 'Genel Bildirimler',
                aciklama: 'Tüm bildirimleri aç/kapat',
                deger: _genelBildirim,
                onChanged: (v) {
                  setState(() => _genelBildirim = v);
                  _kaydet('bildirim_genel', v);
                },
              ),
              _ayrac(),
              _toggle(
                ikon: Icons.assignment_outlined,
                baslik: 'Değerlendirme Bildirimleri',
                aciklama: 'Yeni değerlendirme hatırlatmaları',
                deger: _degerlendirmeBildirim,
                onChanged: (v) {
                  setState(() => _degerlendirmeBildirim = v);
                  _kaydet('bildirim_degerlendirme', v);
                },
              ),
              _ayrac(),
              _toggle(
                ikon: Icons.event_outlined,
                baslik: 'Ajanda Bildirimleri',
                aciklama: 'Randevu ve etkinlik hatırlatmaları',
                deger: _ajandaBildirim,
                onChanged: (v) {
                  setState(() => _ajandaBildirim = v);
                  _kaydet('bildirim_ajanda', v);
                },
              ),
            ]),
            const SizedBox(height: 20),

            // ── Dil ────────────────────────────────────
            _baslik('Dil'),
            const SizedBox(height: 10),
            _kart([
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2563EB)
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(8)),
                      child: const Icon(Icons.language,
                          color: Color(0xFF2563EB),
                          size: 18)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text('Uygulama Dili',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kTextDark)),
                        Text(
                          'Çoklu dil desteği yakında',
                          style: TextStyle(
                              fontSize: 12,
                              color: kTextGrey),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _seciliDil,
                    underline: const SizedBox(),
                    style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    items: ['Türkçe', 'English']
                        .map((d) => DropdownMenuItem(
                        value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _seciliDil = v);
                        _dilKaydet(v);
                        // Tam lokalizasyon desteği
                        // sonraki sürümde eklenecek
                        if (v == 'English') {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'English support coming soon!'),
                            behavior:
                            SnackBarBehavior.floating,
                            backgroundColor:
                            Color(0xFF2563EB),
                          ));
                          setState(
                                  () => _seciliDil = 'Türkçe');
                          _dilKaydet('Türkçe');
                        }
                      }
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ]),
            const SizedBox(height: 20),

            // ── Uygulama ───────────────────────────────
            _baslik('Uygulama'),
            const SizedBox(height: 10),
            _kart([
              _satirItem(
                ikon: Icons.info_outline,
                baslik: 'Versiyon',
                sonuc: '1.0.0',
              ),
              _ayrac(),
              _satirItem(
                ikon: Icons.shield_outlined,
                baslik: 'Gizlilik Politikası',
                onTap: () => _politikaGoster(
                  context,
                  baslik: 'Gizlilik Politikası',
                  icerik: _gizlilikIcerigi,
                ),
              ),
              _ayrac(),
              _satirItem(
                ikon: Icons.description_outlined,
                baslik: 'Kullanım Koşulları',
                onTap: () => _politikaGoster(
                  context,
                  baslik: 'Kullanım Koşulları',
                  icerik: _kullanimKosullariIcerigi,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Policy bottom sheet ───────────────────────────────────
  void _politikaGoster(BuildContext context,
      {required String baslik, required String icerik}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              child: Text(baslik,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Text(icerik,
                    style: const TextStyle(
                        fontSize: 14,
                        color: kTextGrey,
                        height: 1.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Yardımcı Widget'lar ─────────────────────────────────

  Widget _baslik(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kTextGrey,
            letterSpacing: 0.8));
  }

  Widget _kart(List<Widget> icerik) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: icerik),
    );
  }

  Widget _ayrac() => const Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: Color(0xFFE2E8F0));

  Widget _toggle({
    required IconData ikon,
    required String baslik,
    required String aciklama,
    required bool deger,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(ikon, color: kPrimary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextDark)),
                Text(aciklama,
                    style: const TextStyle(
                        fontSize: 12, color: kTextGrey)),
              ],
            )),
        Switch(
            value: deger,
            onChanged: onChanged,
            activeColor: kPrimary),
      ]),
    );
  }

  Widget _satirItem({
    required IconData ikon,
    required String baslik,
    String? sonuc,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kTextGrey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(ikon, color: kTextGrey, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(baslik,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextDark))),
          if (sonuc != null)
            Text(sonuc,
                style: const TextStyle(
                    fontSize: 14, color: kTextGrey)),
          if (onTap != null)
            const Icon(Icons.chevron_right,
                color: Color(0xFFCBD5E1), size: 20),
        ]),
      ),
    );
  }
}

// ── Gizlilik Politikası İçeriği ──────────────────────────────
const String _gizlilikIcerigi = '''
Son Güncelleme: Nisan 2026

NeuraApp olarak kullanıcılarımızın gizliliğini en yüksek önceliğimiz olarak kabul ediyoruz. Bu Gizlilik Politikası, uygulamamızı kullandığınızda hangi verileri topladığımızı, bu verileri nasıl kullandığımızı ve koruduğumuzu açıklamaktadır.

1. TOPLANAN VERİLER

Kişisel Bilgiler
Kayıt sırasında ad, soyad ve e-posta adresinizi topluyoruz. Klinisyenler için ek olarak uzmanlık unvanı bilgisi alınmaktadır.

Sağlık Verileri
Hastalar için doğum tarihi, cinsiyet, boy, kilo ve tanı bilgileri gibi sağlık verileri toplanmaktadır. Bu veriler yalnızca yetkili klinisyenler tarafından görüntülenebilir.

Biyosensör Verileri
Empatica cihazından alınan kalp atış hızı, EDA, vücut sıcaklığı, kan oksijeni ve ivme ölçüm verileri sistemimizde saklanmaktadır.

2. VERİLERİN KULLANIMI

Toplanan veriler yalnızca şu amaçlarla kullanılmaktadır:
• Hasta takibi ve klinik değerlendirme süreçlerinin yürütülmesi
• Klinisyen-hasta iletişiminin sağlanması
• Nörolojik hastalıkların seyrine yönelik analiz yapılması
• Uygulama güvenliği ve teknik destek

3. VERİ GÜVENLİĞİ

Tüm veriler Supabase altyapısı üzerinde şifreli biçimde saklanmakta ve aktarılmaktadır. Yetkisiz erişimi önlemek amacıyla rol tabanlı erişim kontrolü uygulanmaktadır. Hasta verileri yalnızca sorumlu klinisyen tarafından görüntülenebilir.

4. VERİ PAYLAŞIMI

Verileriniz herhangi bir üçüncü tarafla ticari amaçla paylaşılmamaktadır. Yasal yükümlülükler kapsamında yetkili makamlarla paylaşım söz konusu olabilir.

5. HAKLARINIZ

Kişisel verilerinize erişme, düzeltme veya silme talebinde bulunmak için destek@neuraapp.com adresine ulaşabilirsiniz.

6. İLETİŞİM

Bu politikayla ilgili sorularınız için:
E-posta: destek@neuraapp.com
''';

// ── Kullanım Koşulları İçeriği ───────────────────────────────
const String _kullanimKosullariIcerigi = '''
Son Güncelleme: Nisan 2026

NeuraApp'ı kullanmadan önce lütfen bu Kullanım Koşullarını dikkatlice okuyunuz. Uygulamayı kullanarak bu koşulları kabul etmiş sayılırsınız.

1. UYGULAMANIN AMACI

NeuraApp, nörolojik hastalıkların takibi ve klinik değerlendirmesi amacıyla geliştirilmiş bir sağlık yönetim platformudur. Uygulama yalnızca yetkili sağlık profesyonelleri ve hastaları tarafından kullanılabilir.

2. KULLANICI YÜKÜMLÜLÜKLERİ

• Hesap bilgilerinizi üçüncü şahıslarla paylaşmayınız.
• Sisteme yalnızca doğru ve güncel bilgi giriniz.
• Uygulamayı yalnızca tanımlanan sağlık hizmetleri kapsamında kullanınız.
• Yetkisiz erişim girişimlerinde bulunmayınız.

3. KLİNİSYEN SORUMLULUKLARI

Klinisyen hesabıyla giriş yapan kullanıcılar, girdikleri tüm klinik verilerden ve verdikleri klinik kararlardan bizzat sorumludur. NeuraApp, klinik karar desteği sunmakla birlikte tıbbi teşhis aracı değildir.

4. HİZMET KISITLAMALARI

NeuraApp aşağıdaki amaçlarla kullanılamaz:
• Ticari yeniden satış veya lisanslama
• Kötü niyetli veri toplama
• Sisteme zarar verecek her türlü eylem

5. FİKRİ MÜLKİYET

Uygulama içindeki tüm içerik, tasarım ve yazılım bileşenleri NeuraApp'e aittir. İzinsiz kopyalanamaz, dağıtılamaz veya değiştirilemez.

6. SORUMLULUK SINIRI

NeuraApp, teknik arızalar, veri kayıpları veya kullanıcı hatalarından kaynaklanan zararlardan sorumlu tutulamaz. Uygulama "olduğu gibi" sunulmaktadır.

7. KOŞULLARDA DEĞİŞİKLİK

Kullanım Koşulları önceden haber vermeksizin güncellenebilir. Güncel koşullar her zaman uygulama içinden erişilebilir olacaktır.

8. İLETİŞİM

Sorularınız için: destek@neuraapp.com
''';