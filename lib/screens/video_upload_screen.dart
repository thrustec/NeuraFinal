import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/exercise_video_model.dart';
import '../providers/auth_provider.dart';
import '../services/exercise_video_service.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState  extends State<VideoUploadScreen> {
  static const Color kPrimary = Color(0xFF0F766E);

  final _baslikCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final _sureSaniyeCtrl = TextEditingController();

  File? _videoFile;
  File? _thumbnailFile;
  List<EgzersizKategori> _kategoriler = [];
  int? _secilenKategoriId;

  bool _yukleniyor = false;
  double _ilerleme = 0;
  String _ilerlemeMetni = '';

  @override
  void initState() {
    super.initState();
    _kategorileriYukle();
  }

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _aciklamaCtrl.dispose();
    _sureSaniyeCtrl.dispose();
    super.dispose();
  }

  Future<void> _kategorileriYukle() async {
    try {
      final list = await ExerciseVideoService.getKategoriler();
      setState(() => _kategoriler = list);
    } catch (_) {}
  }

  Future<void> _videoDosyasiSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _thumbnailSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _thumbnailFile = File(picked.path));
  }

  Future<void> _yukle() async {
    if (_videoFile == null) {
      _snack('Lütfen bir video dosyası seçin', isError: true);
      return;
    }
    if (_baslikCtrl.text.trim().isEmpty) {
      _snack('Lütfen video başlığı girin', isError: true);
      return;
    }
    if (_secilenKategoriId == null) {
      _snack('Lütfen bir kategori seçin', isError: true);
      return;
    }
    final sure = int.tryParse(_sureSaniyeCtrl.text.trim());
    if (sure == null || sure <= 0) {
      _snack('Lütfen geçerli bir süre girin (saniye)', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final yukleyenId = int.tryParse(authProvider.user?.id ?? '1') ?? 1;

    setState(() {
      _yukleniyor = true;
      _ilerleme = 0.1;
      _ilerlemeMetni = 'Video yükleniyor...';
    });

    try {
      setState(() { _ilerleme = 0.3; _ilerlemeMetni = 'Video Storage\'a aktarılıyor...'; });

      final videoUrl = await ExerciseVideoService.uploadDosya(
        dosya: _videoFile!,
        bucket: 'videos',
        klasor: 'egzersiz',
      );

      setState(() { _ilerleme = 0.6; _ilerlemeMetni = 'Thumbnail yükleniyor...'; });

      String? thumbnailUrl;
      if (_thumbnailFile != null) {
        thumbnailUrl = await ExerciseVideoService.uploadDosya(
          dosya: _thumbnailFile!,
          bucket: 'thumbnails',
          klasor: 'egzersiz',
        );
      }

      setState(() { _ilerleme = 0.8; _ilerlemeMetni = 'Veritabanına kaydediliyor...'; });

      await ExerciseVideoService.videoKaydet(
        baslik: _baslikCtrl.text.trim(),
        aciklama: _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim(),
        kategoriId: _secilenKategoriId!,
        yukleyenId: yukleyenId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        sureSaniye: sure,
      );

      setState(() { _ilerleme = 1.0; _ilerlemeMetni = 'Tamamlandı!'; });

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pop(context, true);
        _snack('Video başarıyla yüklendi');
      }
    } catch (e) {
      setState(() { _yukleniyor = false; _ilerleme = 0; });
      _snack('Hata: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: _yukleniyor ? null : () => Navigator.pop(context),
        ),
        title: const Text('Yeni Video Yükle',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _yukleniyor ? null : _yukle,
              style: TextButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Yükle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _yukleniyor ? _yukleniyorEkrani() : _form(),
    );
  }

  Widget _yukleniyorEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: kPrimary, size: 40),
            ),
            const SizedBox(height: 24),
            Text(_ilerlemeMetni,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _ilerleme,
                minHeight: 8,
                backgroundColor: kPrimary.withOpacity(0.15),
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text('${(_ilerleme * 100).toInt()}%',
                style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _videoSecAlan(),
          const SizedBox(height: 16),
          _thumbnailSecAlan(),
          const SizedBox(height: 24),
          _bolumBaslik('VİDEO BİLGİLERİ'),
          const SizedBox(height: 12),
          _inputAlan(
            controller: _baslikCtrl,
            etiket: 'Video Başlığı *',
            ipucu: 'Örn: Denge Antrenmanı - Seviye 1',
            ikon: Icons.title,
          ),
          const SizedBox(height: 12),
          _kategoriSecici(),
          const SizedBox(height: 12),
          _inputAlan(
            controller: _sureSaniyeCtrl,
            etiket: 'Süre (saniye) *',
            ipucu: 'Örn: 120',
            ikon: Icons.timer_outlined,
            klavye: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _inputAlan(
            controller: _aciklamaCtrl,
            etiket: 'Açıklama (opsiyonel)',
            ipucu: 'Video hakkında kısa açıklama...',
            ikon: Icons.notes,
            satirSayisi: 3,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _videoSecAlan() {
    return GestureDetector(
      onTap: _videoDosyasiSec,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: _videoFile != null ? kPrimary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _videoFile != null ? kPrimary : const Color(0xFFE2E8F0),
            width: _videoFile != null ? 1.5 : 1,
            style: _videoFile != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: _videoFile != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.videocam, color: kPrimary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _videoFile!.path.split('/').last,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_videoFile!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Text('Değiştirmek için tıkla',
                      style: TextStyle(fontSize: 11, color: kPrimary.withOpacity(0.7))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.video_library_outlined, color: Color(0xFF94A3B8), size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('Video Dosyası Seç *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  const Text('MP4, MOV veya AVI formatında',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Galeriden Seç',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimary)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _thumbnailSecAlan() {
    return GestureDetector(
      onTap: _thumbnailSec,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _thumbnailFile != null ? kPrimary.withOpacity(0.1) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: _thumbnailFile != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Image.file(_thumbnailFile!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _thumbnailFile != null ? 'Thumbnail Seçildi' : 'Thumbnail Ekle (opsiyonel)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _thumbnailFile != null ? kPrimary : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _thumbnailFile != null
                        ? _thumbnailFile!.path.split('/').last
                        : 'Kapak resmi için görsel seçin',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                _thumbnailFile != null ? Icons.check_circle : Icons.add_photo_alternate_outlined,
                color: _thumbnailFile != null ? kPrimary : const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kategoriSecici() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _secilenKategoriId,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Kategori Seçin *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items: _kategoriler.map((k) => DropdownMenuItem(
            value: k.egzersizKategoriId,
            child: Text(k.kategoriAdi, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
          )).toList(),
          onChanged: (v) => setState(() => _secilenKategoriId = v),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _inputAlan({
    required TextEditingController controller,
    required String etiket,
    required String ipucu,
    required IconData ikon,
    TextInputType klavye = TextInputType.text,
    int satirSayisi = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: klavye,
      maxLines: satirSayisi,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: etiket,
        hintText: ipucu,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(ikon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _bolumBaslik(String baslik) {
    return Text(baslik,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ));
  }
}
