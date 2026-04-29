import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  bool _duzenleniyor = false;
  bool _kaydediliyor = false;

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

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);

    final auth = context.read<AuthProvider>();

    // Ad, soyad güncelle
    final basarili = await auth.updateUser(
      ad:    _adCtrl.text.trim(),
      soyad: _soyadCtrl.text.trim(),
    );

    // E-posta değiştiyse doğrulama maili gönder
    if (_epostaCtrl.text.trim() != auth.user?.eposta) {
      final epostaBasarili = await auth.updateEposta(
        yeniEposta: _epostaCtrl.text.trim(),
      );
      if (mounted && epostaBasarili) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${_epostaCtrl.text.trim()} adresine doğrulama maili gönderildi. '
                  'Onayladıktan sonra e-postanız değişecek.'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      }
    }

    setState(() {
      _kaydediliyor = false;
      _duzenleniyor = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(basarili
            ? 'Profil güncellendi'
            : 'Güncelleme başarısız'),
        backgroundColor: basarili ? kPrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  void _sifreDegistir() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SifreDegistirSheet(
          kPrimary: kPrimary, kInputFill: kInputFill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
        title: const Text('Profilim',
            style: TextStyle(
                color: kTextDark,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          if (!_kaydediliyor)
            TextButton(
              onPressed: _toggle,
              child: Text(_duzenleniyor ? 'İptal' : 'Düzenle',
                  style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // ── Avatar ──────────────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: kPrimary.withOpacity(0.12),
                    child: Text(
                        auth.user?.ad.isNotEmpty == true
                            ? auth.user!.ad[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: kPrimary)),
                  ),
                  if (_duzenleniyor)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(auth.user?.fullName ?? '',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Hasta Hesabı',
                    style: TextStyle(
                        fontSize: 12,
                        color: kPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),

              // ── Kişisel Bilgiler ─────────────────────────────
              _bolum('Kişisel Bilgiler', [
                _satirIkili(
                  sol: _alan('AD', _adCtrl,
                      validator: (v) =>
                      v!.isEmpty ? 'Zorunlu alan' : null),
                  sag: _alan('SOYAD', _soyadCtrl,
                      validator: (v) =>
                      v!.isEmpty ? 'Zorunlu alan' : null),
                ),
                _alan('E-POSTA', _epostaCtrl,
                    klavye: TextInputType.emailAddress,
                    validator: (v) =>
                    v!.isEmpty ? 'Zorunlu alan' : null),
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

              // ── Kaydet ───────────────────────────────────────
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
                          borderRadius:
                          BorderRadius.circular(14)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                        : const Text('Kaydet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Yardımcı Widget'lar ─────────────────────────────────

  Widget _bolum(String baslik, List<Widget> icerik) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextDark)),
          const SizedBox(height: 14),
          ...icerik,
        ],
      ),
    );
  }

  Widget _satirIkili(
      {required Widget sol, required Widget sag}) {
    return Row(children: [
      Expanded(child: sol),
      const SizedBox(width: 12),
      Expanded(child: sag),
    ]);
  }

  Widget _alan(String etiket, TextEditingController ctrl,
      {TextInputType? klavye,
        String? Function(String?)? validator}) {
    return Padding(
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
          if (!_duzenleniyor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: kInputFill,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                  ctrl.text.isEmpty ? '-' : ctrl.text,
                  style: const TextStyle(
                      fontSize: 15, color: kTextDark)),
            )
          else
            TextFormField(
              controller: ctrl,
              keyboardType: klavye,
              validator: validator,
              style: const TextStyle(
                  fontSize: 15, color: kTextDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: kInputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: kPrimary, width: 1.5)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _aksiyon({
    required IconData ikon,
    required String baslik,
    required String aciklama,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(ikon, color: kPrimary, size: 20),
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
            const Icon(Icons.chevron_right,
                color: Color(0xFFCBD5E1)),
          ]),
        ),
      ),
    );
  }
}

// ── Şifre Değiştir Bottom Sheet ──────────────────────────────
class _SifreDegistirSheet extends StatefulWidget {
  final Color kPrimary;
  final Color kInputFill;
  const _SifreDegistirSheet(
      {required this.kPrimary, required this.kInputFill});

  @override
  State<_SifreDegistirSheet> createState() =>
      _SifreDegistirSheetState();
}

class _SifreDegistirSheetState
    extends State<_SifreDegistirSheet> {
  final _mevcutCtrl = TextEditingController();
  final _yeniCtrl   = TextEditingController();
  final _tekrarCtrl = TextEditingController();
  bool _g1 = true, _g2 = true, _g3 = true;
  bool _yukleniyor = false;

  @override
  void dispose() {
    _mevcutCtrl.dispose();
    _yeniCtrl.dispose();
    _tekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guncelle() async {
    if (_yeniCtrl.text != _tekrarCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şifreler eşleşmiyor'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_yeniCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şifre en az 6 karakter olmalı'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _yukleniyor = true);

    final auth = context.read<AuthProvider>();
    final basarili = await auth.updateSifre(
      mevcutSifre: _mevcutCtrl.text,
      yeniSifre:   _yeniCtrl.text,
    );

    setState(() => _yukleniyor = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(basarili
            ? 'Şifre başarıyla güncellendi'
            : 'Mevcut şifre hatalı'),
        backgroundColor:
        basarili ? widget.kPrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Şifre Değiştir',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          _sifreAlan('Mevcut Şifre', _mevcutCtrl, _g1,
                  () => setState(() => _g1 = !_g1)),
          _sifreAlan('Yeni Şifre', _yeniCtrl, _g2,
                  () => setState(() => _g2 = !_g2)),
          _sifreAlan('Yeni Şifre Tekrar', _tekrarCtrl, _g3,
                  () => setState(() => _g3 = !_g3)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _yukleniyor ? null : _guncelle,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _yukleniyor
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Güncelle',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sifreAlan(String label, TextEditingController ctrl,
      bool gizli, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: gizli,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: widget.kInputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: widget.kPrimary, width: 1.5)),
          suffixIcon: IconButton(
              icon: Icon(
                  gizli
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8)),
              onPressed: toggle),
        ),
      ),
    );
  }
}