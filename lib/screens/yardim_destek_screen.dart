import 'package:flutter/material.dart';

class YardimDestekScreen extends StatefulWidget {
  const YardimDestekScreen({super.key});

  @override
  State<YardimDestekScreen> createState() => _YardimDestekScreenState();
}

class _YardimDestekScreenState extends State<YardimDestekScreen> {
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark   = Color(0xFF1E293B);
  static const Color kTextGrey   = Color(0xFF64748B);
  static const Color kPrimary    = Color(0xFF0F766E);

  final List<bool> _acik = List.filled(5, false);


  final List<Map<String, String>> _sss = [

    {
      'soru': 'E-posta adresimi nasıl güncellerim?',
      'cevap': 'Profilim sayfasında Düzenle butonuna basın. '
          'E-posta alanına yeni adresinizi girin ve Kaydet deyin. '
          'Yeni adresinize bir doğrulama maili gönderilecektir. '
          'Maili onayladıktan sonra e-postanız otomatik olarak güncellenecektir.',
    },
    {
      'soru': 'Şifremi unuttum, ne yapmalıyım?',
      'cevap': 'Giriş ekranındaki Şifremi Unuttum bağlantısına tıklayın. '
          'E-posta adresinize şifre sıfırlama bağlantısı gönderilecektir. '
          'Bağlantıya tıklayarak yeni şifrenizi belirleyebilirsiniz.',
    },
    {
      'soru': 'Uygulama ile ilgili bir sorun bildirmek istiyorum.',
      'cevap': 'Aşağıdaki Hata Bildir butonuna tıklayarak teknik sorunuzu '
          'bize iletebilirsiniz. Lütfen sorunu, hangi ekranda oluştuğunu '
          've cihaz bilgilerinizi belirtin.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kTextDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Yardım ve Destek',
            style: TextStyle(
                color: kTextDark,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Üst Banner ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [kPrimary, kPrimary.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Icon(Icons.support_agent,
                    color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Size Nasıl Yardımcı Olabiliriz?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      SizedBox(height: 4),
                      Text('SSS ve iletişim seçenekleri aşağıda',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── SSS ────────────────────────────────────────
            const Text('SIK SORULAN SORULAR',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kTextGrey,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: List.generate(_sss.length, (i) {
                  final isLast = i == _sss.length - 1;
                  return Column(children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _acik[i] = !_acik[i]),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(
                            child: Text(_sss[i]['soru']!,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _acik[i]
                                        ? kPrimary
                                        : kTextDark)),
                          ),
                          Icon(
                              _acik[i]
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color:
                              _acik[i] ? kPrimary : kTextGrey),
                        ]),
                      ),
                    ),
                    if (_acik[i])
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 16),
                        child: Text(_sss[i]['cevap']!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: kTextGrey,
                                height: 1.6)),
                      ),
                    if (!isLast)
                      const Divider(
                          height: 1,
                          color: Color(0xFFE2E8F0)),
                  ]);
                }),
              ),
            ),
            const SizedBox(height: 24),

            // ── İletişim ───────────────────────────────────
            const Text('İLETİŞİM',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kTextGrey,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                _iletisimItem(
                  ikon: Icons.email_outlined,
                  renk: const Color(0xFF2563EB),
                  baslik: 'E-posta',
                  aciklama: 'destek@neuraapp.com',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text(
                          'destek@neuraapp.com adresine mail gönderebilirsiniz'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF2563EB),
                    ));
                  },
                ),
                const Divider(
                    height: 1, color: Color(0xFFE2E8F0)),
                _iletisimItem(
                  ikon: Icons.bug_report_outlined,
                  renk: const Color(0xFFDC2626),
                  baslik: 'Hata Bildir',
                  aciklama: 'Teknik sorun bildirin',
                  onTap: () => _hataBildirSheet(context),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hata Bildir Bottom Sheet ──────────────────────────────
  void _hataBildirSheet(BuildContext context) {
    final _sorunCtrl = TextEditingController();
    final _ekranCtrl = TextEditingController();
    bool _gonderiliyor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.bug_report_outlined,
                        color: Color(0xFFDC2626), size: 20)),
                const SizedBox(width: 12),
                const Text('Hata Bildir',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDark)),
              ]),
              const SizedBox(height: 6),
              const Text(
                  'Karşılaştığınız sorunu detaylı açıklayın, en kısa sürede dönüş yapacağız.',
                  style: TextStyle(fontSize: 13, color: kTextGrey)),
              const SizedBox(height: 20),

              // Hangi ekranda
              const Text('HANGİ EKRANDA OLUŞTU?',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kTextGrey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _ekranCtrl,
                style: const TextStyle(
                    fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText: 'Örn: Hasta Listesi, Empatica...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Sorun açıklaması
              const Text('SORUN AÇIKLAMASI',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kTextGrey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _sorunCtrl,
                maxLines: 4,
                style: const TextStyle(
                    fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText:
                  'Sorunu adım adım açıklayın...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _gonderiliyor
                      ? null
                      : () async {
                    if (_sorunCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(const SnackBar(
                        content: Text(
                            'Lütfen sorunu açıklayın'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    setSheetState(
                            () => _gonderiliyor = true);
                    // Simüle gönderim (API bağlanınca gerçek istek atılacak)
                    await Future.delayed(
                        const Duration(milliseconds: 1200));
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text(
                            '✅ Hata bildirimi gönderildi, teşekkürler!'),
                        backgroundColor: kPrimary,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                  ),
                  child: _gonderiliyor
                      ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2))
                      : const Text('Gönder',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iletisimItem({
    required IconData ikon,
    required Color renk,
    required String baslik,
    required String aciklama,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: renk.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(ikon, color: renk, size: 20),
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
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFCBD5E1)),
        ]),
      ),
    );
  }
}