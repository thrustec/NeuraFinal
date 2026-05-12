import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

// NeuraApp Design System — Klinisyen Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class RegisterClinicianScreen extends StatefulWidget {
  const RegisterClinicianScreen({super.key});

  @override
  State<RegisterClinicianScreen> createState() =>
      _RegisterClinicianScreenState();
}

class _RegisterClinicianScreenState extends State<RegisterClinicianScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  String? _selectedTitle; // Unvan dropdown

  static const List<String> _titleOptions = [
    'Dr.',
    'Uzm. Dr.',
    'Prof. Dr.',
    'Doç. Dr.',
    'Fzt.',
    'Uzm. Fzt.',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty) {
      _showValidationError('Lütfen zorunlu alanları doldurun');
      return;
    }

    if (!_isValidEmail(email)) {
      _showValidationError(
          'Geçerli bir e-posta adresi girin\nÖrnek: ornek@mail.com');
      return;
    }

    if (!_isValidPassword(password)) {
      _showValidationError(
          'Şifre en az 8 karakter olmalı ve\nbüyük harf, küçük harf ile\nrakam veya özel karakter içermelidir');
      return;
    }

    if (password != passwordConfirm) {
      _showValidationError('Şifreler uyuşmuyor');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final nameParts = fullName.split(' ');
    final ad = nameParts.first;
    final soyad =
    nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await auth.register(
      ad: ad,
      soyad: soyad,
      eposta: email,
      sifre: password,
      rolAdi: 'Klinisyen',
      unvan: _selectedTitle,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/clinician-home');
    } else {
      _showErrorDialog(auth.errorMessage ?? 'BAĞLANTI_HATASI');
    }
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Geçersiz Bilgi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTextDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String errorType) {
    String title;
    String message;

    if (errorType == 'EMAIL_KAYITLI') {
      title = 'E-posta Kayıtlı';
      message = 'Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapın.';
    } else {
      title = 'Bağlantı Hatası';
      message =
      'Şu anda internete bağlı değilsiniz. Lütfen bağlantınızı kontrol edin.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Provider.of<AuthProvider>(context, listen: false)
                      .clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTextDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: kPrimary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kInputFill,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: kPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Hesap',
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: kPrimary, size: 30),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Klinisyen Kaydı',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Mesleki bilgilerinizi girerek kayıt olun',
                  style: TextStyle(fontSize: 13, color: kTextGrey),
                ),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unvan
                    _label('Unvan'),
                    DropdownButtonFormField<String>(
                      value: _selectedTitle,
                      decoration: _inputDecoration(
                        hint: 'Unvan seçin (opsiyonel)',
                        prefixIcon: Icons.workspace_premium_outlined,
                      ),
                      items: _titleOptions
                          .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTitle = v),
                    ),

                    const SizedBox(height: 16),

                    // Tam Ad
                    _label('Tam Adınız'),
                    TextField(
                      controller: _fullNameController,
                      style:
                      const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Ad Soyad',
                        prefixIcon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Email
                    _label('E-posta Adresi'),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style:
                      const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'ornek@email.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Şifre
                    _label('Şifre'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, top: 0),
                      child: Text(
                        'En az 8 karakter, büyük/küçük harf ve rakam içermeli',
                        style: TextStyle(fontSize: 11, color: kTextGrey),
                      ),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style:
                      const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kTextGrey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Şifre Tekrar
                    _label('Şifre Tekrar'),
                    TextField(
                      controller: _passwordConfirmController,
                      obscureText: _obscurePasswordConfirm,
                      style:
                      const TextStyle(color: kTextDark, fontSize: 14),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasswordConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kTextGrey,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                          _obscurePasswordConfirm =
                          !_obscurePasswordConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              RichText(
                text: TextSpan(
                  text: 'Devam ederek şunları kabul ediyorsunuz: ',
                  style: const TextStyle(
                      color: kTextGrey, fontSize: 12, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'Kullanım Koşulları',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _politikaGoster(
                          context,
                          baslik: 'Kullanım Koşulları',
                          icerik: _kullanimKosullariIcerigi,
                        ),
                    ),
                    const TextSpan(text: ' ve '),
                    TextSpan(
                      text: 'Gizlilik Politikası',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _politikaGoster(
                          context,
                          baslik: 'Gizlilik Politikası',
                          icerik: _gizlilikIcerigi,
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Zaten hesabın var mı? ',
                      style: TextStyle(color: kTextGrey, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _politikaGoster(BuildContext context,
      {required String baslik, required String icerik}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        fontSize: 14, color: kTextGrey, height: 1.7)),
              ),
            ),
          ],
        ),
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
