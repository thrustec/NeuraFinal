import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class HastaProfilScreen extends StatefulWidget {
  const HastaProfilScreen({super.key});

  @override
  State<HastaProfilScreen> createState() => _HastaProfilScreenState();
}

class _HastaProfilScreenState extends State<HastaProfilScreen> {
  static const Color kPrimary    = Color(0xFF2563EB);
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark   = Color(0xFF1E293B);
  static const Color kTextGrey   = Color(0xFF64748B);
  static const Color kInputFill  = Color(0xFFF1F5F9);

  bool _duzenleniyor     = false;
  bool _kaydediliyor     = false;
  bool _avatarYukleniyor = false; // ← YENİ: avatar yükleme state'i

  late TextEditingController _adCtrl;
  late TextEditingController _soyadCtrl;
  late TextEditingController _epostaCtrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _adCtrl     = TextEditingController(text: auth.user?.ad ?? '');
    _soyadCtrl  = TextEditingController(text: auth.user?.soyad ?? '');
    _epostaCtrl = TextEditingController(text: auth.user?.eposta ?? '');
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _epostaCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_duzenleniyor) {
        final auth = context.read<AuthProvider>();
        _adCtrl.text     = auth.user?.ad ?? '';
        _soyadCtrl.text  = auth.user?.soyad ?? '';
        _epostaCtrl.text = auth.user?.eposta ?? '';
      }
      _duzenleniyor = !_duzenleniyor;
    });
  }

  // ── FIX: Kaynak seçim modalı ─────────────────────────────
  Future<ImageSource?> _kaynakSec() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Fotoğraf Seç',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextDark)),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt_outlined, color: kPrimary)),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                  const Icon(Icons.photo_library_outlined, color: kPrimary)),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── FIX: Fotoğraf seç ve yükle ───────────────────────────
  Future<void> _fotografSec() async {
    final kaynak = await _kaynakSec();
    if (kaynak == null) return;

    final picker  = ImagePicker();
    final secilen = await picker.pickImage(
      source: kaynak,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (secilen == null) return;

    setState(() => _avatarYukleniyor = true);

    final bytes = await secilen.readAsBytes();
    final auth  = context.read<AuthProvider>();
    final basarili = await auth.updateAvatar(bytes);

    setState(() => _avatarYukleniyor = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            basarili ? 'Profil fotoğrafı güncellendi' : 'Fotoğraf yüklenemedi'),
        backgroundColor: basarili ? kPrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);

    final auth = context.read<AuthProvider>();

    final basarili = await auth.updateUser(
      ad:    _adCtrl.text.trim(),
      soyad: _soyadCtrl.text.trim(),
    );

    // E-posta değiştiyse güncelle
    if (_epostaCtrl.text.trim() != auth.user?.eposta) {
      final epostaBasarili =
      await auth.updateEposta(yeniEposta: _epostaCtrl.text.trim());
      if (mounted && epostaBasarili) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${_epostaCtrl.text.trim()} adresine doğrulama maili gönderildi. '
                  'Onayladıktan sonra e-postanız değişecek.'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }

    setState(() {
      _kaydediliyor = false;
      _duzenleniyor = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
        Text(basarili ? 'Profil güncellendi' : 'Güncelleme başarısız'),
        backgroundColor: basarili ? kPrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  void _sifreDegistir() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _SifreDegistirSheet(kPrimary: kPrimary, kInputFill: kInputFill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final avatarUrl = auth.user?.avatarUrl; // ← avatarUrl'i izle

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profilim',
            style: TextStyle(
                color: kTextDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (!_kaydediliyor)
            TextButton(
              onPressed: _toggle,
              child: Text(_duzenleniyor ? 'İptal' : 'Düzenle',
                  style: const TextStyle(
                      color: kPrimary, fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // ── FIX: Avatar — GestureDetector ile tıklanabilir ──
              GestureDetector(
                onTap: _fotografSec, // ← Artık her zaman tıklanabilir
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Yükleniyor mu?
                    _avatarYukleniyor
                        ? CircleAvatar(
                      radius: 52,
                      backgroundColor: kPrimary.withOpacity(0.15),
                      child: const CircularProgressIndicator(
                          color: kPrimary, strokeWidth: 2),
                    )
                    // Avatar URL var mı?
                        : avatarUrl != null && avatarUrl.isNotEmpty
                        ? CircleAvatar(
                      radius: 52,
                      backgroundImage: NetworkImage(avatarUrl),
                      backgroundColor: kPrimary.withOpacity(0.15),
                    )
                    // Varsayılan baş harf
                        : CircleAvatar(
                      radius: 52,
                      backgroundColor: kPrimary.withOpacity(0.15),
                      child: Text(
                          auth.user?.ad.isNotEmpty == true
                              ? auth.user!.ad[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: kPrimary)),
                    ),
                    // Kamera ikonu — her zaman görünür
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(auth.user?.fullName ?? '',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Hasta Hesabı',
                    style: TextStyle(
                        fontSize: 12,
                        color: kPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              const Text('Fotoğrafı değiştirmek için tıklayın',
                  style: TextStyle(fontSize: 12, color: kTextGrey)),
              const SizedBox(height: 24),

              // ── Kişisel Bilgiler ─────────────────────────────
              _bolum('Kişisel Bilgiler', [
                _satirIkili(
                  sol: _alan('AD', _adCtrl,
                      validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null),
                  sag: _alan('SOYAD', _soyadCtrl,
                      validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null),
                ),
                _alan('E-POSTA', _epostaCtrl,
                    klavye: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null),
              ]),
              const SizedBox(height: 14),

              // ── Şifre Değiştir ───────────────────────────────
              _aksiyon(
                ikon: Icons.lock_outline,
                baslik: 'Şifre Değiştir',
                aciklama: 'Hesap şifrenizi güncelleyin',
                onTap: _sifreDegistir,
              ),
              const SizedBox(height: 24),

              // ── Kaydet butonu ────────────────────────────────
              if (_duzenleniyor)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Yardımcı widget builder'lar ──────────────────────────

  Widget _bolum(String baslik, List<Widget> icerik) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kTextGrey,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...icerik,
      ],
    ),
  );

  Widget _satirIkili({required Widget sol, required Widget sag}) => Row(
    children: [
      Expanded(child: sol),
      const SizedBox(width: 12),
      Expanded(child: sag),
    ],
  );

  Widget _alan(
      String etiket,
      TextEditingController ctrl, {
        TextInputType klavye = TextInputType.text,
        String? Function(String?)? validator,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiket,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextGrey,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            TextFormField(
              controller: ctrl,
              enabled: _duzenleniyor,
              keyboardType: klavye,
              validator: validator,
              style:
              const TextStyle(fontSize: 14, color: kTextDark),
              decoration: InputDecoration(
                filled: true,
                fillColor:
                _duzenleniyor ? kInputFill : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0), width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: kPrimary, width: 1.5)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.red, width: 1)),
              ),
            ),
          ],
        ),
      );

  Widget _aksiyon({
    required IconData ikon,
    required String baslik,
    required String aciklama,
    required VoidCallback onTap,
  }) =>
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: ListTile(
          onTap: onTap,
          leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(ikon, color: kPrimary, size: 20)),
          title: Text(baslik,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextDark)),
          subtitle: Text(aciklama,
              style: const TextStyle(fontSize: 12, color: kTextGrey)),
          trailing: const Icon(Icons.chevron_right,
              color: kTextGrey, size: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      );
}

// ── Şifre Değiştir Bottom Sheet ─────────────────────────────
class _SifreDegistirSheet extends StatefulWidget {
  final Color kPrimary;
  final Color kInputFill;

  const _SifreDegistirSheet(
      {required this.kPrimary, required this.kInputFill});

  @override
  State<_SifreDegistirSheet> createState() => _SifreDegistirSheetState();
}

class _SifreDegistirSheetState extends State<_SifreDegistirSheet> {
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);

  final _mevcutCtrl = TextEditingController();
  final _yeniCtrl   = TextEditingController();
  final _tekrarCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool _yukleniyor  = false;

  @override
  void dispose() {
    _mevcutCtrl.dispose();
    _yeniCtrl.dispose();
    _tekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _yukleniyor = true);

    final auth    = context.read<AuthProvider>();
    final basarili = await auth.updateSifre(
      mevcutSifre: _mevcutCtrl.text.trim(),
      yeniSifre:   _yeniCtrl.text.trim(),
    );

    setState(() => _yukleniyor = false);

    if (!mounted) return;
    if (basarili) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Şifre güncellendi'),
        backgroundColor: widget.kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Mevcut şifre hatalı veya işlem başarısız'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Şifre Değiştir',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark)),
            const SizedBox(height: 16),
            _sifreAlani('Mevcut Şifre', _mevcutCtrl,
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
            _sifreAlani('Yeni Şifre', _yeniCtrl,
                validator: (v) =>
                v!.length < 6 ? 'En az 6 karakter' : null),
            _sifreAlani('Yeni Şifre (Tekrar)', _tekrarCtrl,
                validator: (v) => v != _yeniCtrl.text ? 'Şifreler uyuşmuyor' : null),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _kaydet,
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _yukleniyor
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Güncelle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sifreAlani(
      String etiket,
      TextEditingController ctrl, {
        String? Function(String?)? validator,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          obscureText: true,
          validator: validator,
          decoration: InputDecoration(
            labelText: etiket,
            labelStyle:
            const TextStyle(fontSize: 13, color: kTextGrey),
            filled: true,
            fillColor: widget.kInputFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.kPrimary, width: 1.5)),
          ),
        ),
      );
}