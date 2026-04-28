// ============================================================
// DOSYA 1: lib/views/clinical_evaluation/evaluation_list_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart' as patient_model;
import '../../providers/evaluation_provider.dart';
import '../result_screen.dart';
import 'evaluation_form_screen.dart';

import 'package:flutter/foundation.dart';
import '../../services/evaluation_service.dart';

class EvaluationListScreen extends StatefulWidget {
  final int? hastaId;
  final String? hastaAdi;

  const EvaluationListScreen({super.key, this.hastaId, this.hastaAdi});

  @override
  State<EvaluationListScreen> createState() => _EvaluationListScreenState();
}

class _EvaluationListScreenState extends State<EvaluationListScreen> {
  static const _bg = Color(0xFFF8F9FC);
  static const _surface = Colors.white;
  static const _primary = Color(0xFF0F766E);
  static const _primarySoft = Color(0xFFE7F5F3);
  static const _border = Color(0xFFE2E8F0);
  static const _inputFill = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF1E293B);
  static const _textMid = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);
  static const _success = Color(0xFF0A8C3B);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Karşılaştırma seçim modu
  bool _compareMode = false;
  final List<dynamic> _selectedEvaluations = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EvaluationProvider>();
      if (widget.hastaId != null) {
        provider.loadEvaluationsByPatient(widget.hastaId!);
      } else {
        provider.clearFilter();
        provider.loadEvaluations();
      }
    });
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _selectedEvaluations.clear();
    });
  }

  void _toggleSelection(dynamic ev) {
    setState(() {
      final alreadySelected = _selectedEvaluations.any(
            (e) => e.degerlendirmeId == ev.degerlendirmeId,
      );
      if (alreadySelected) {
        _selectedEvaluations.removeWhere(
              (e) => e.degerlendirmeId == ev.degerlendirmeId,
        );
      } else if (_selectedEvaluations.length < 2) {
        _selectedEvaluations.add(ev);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('En fazla 2 değerlendirme seçebilirsiniz.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  bool _isSelected(dynamic ev) {
    return _selectedEvaluations.any(
          (e) => e.degerlendirmeId == ev.degerlendirmeId,
    );
  }

  /// Evaluation nesnesinden EvaluationDate oluşturur.
  /// Test sonuçları bu ekranda mevcut değilse boş liste döner —
  /// gerçek projede provider'dan testler çekilebilir.
  Future<patient_model.EvaluationDate> _toEvaluationDateWithTests(
      dynamic ev) async {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(ev.degerlendirmeTarihi.toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = parsedDate.month.toString().padLeft(2, '0');
    final year = parsedDate.year.toString();

    // API'den test sonuçlarını çek
    List<patient_model.TestResult> testSonuclari = [];
    try {
      final rawTests = await EvaluationService().getTestSonuclari(
        degerlendirmeId: ev.degerlendirmeId as int,
        hastaId: ev.hastaId as int,
      );
      // EvaluationService.TestResult → patient_model.TestResult dönüşümü
      testSonuclari = rawTests
          .map((t) => patient_model.TestResult(
        testSonucId: t.testSonucId,
        testId: t.testId,
        testAdi: t.testAdi,
        olculenDeger: t.olculenDeger,
        maxDeger: t.maxDeger,
        birim: t.birim,
        isLowerBetter: t.isLowerBetter,
      ))
          .toList();
    } catch (e) {
      debugPrint('Test sonuçları alınamadı: $e');
    }

    return patient_model.EvaluationDate(
      degerlendirmeId: ev.degerlendirmeId as int,
      tarih: '$day/$month/$year',
      baslik: (ev.hastalikAdi?.toString().isNotEmpty == true
          ? ev.hastalikAdi
          : ev.diagnosis?.toString().isNotEmpty == true
          ? ev.diagnosis
          : 'Değerlendirme') ??
          'Değerlendirme',
      testSonuclari: testSonuclari,
    );
  }

  /// Seçilen 2 değerlendirmeden Patient nesnesi oluşturur.
  patient_model.Patient _buildPatient(dynamic ev) {
    final adSoyad = (ev.hastaAdSoyad ?? '').toString().trim();
    final parts = adSoyad.split(' ');
    final ad = parts.isNotEmpty ? parts.first : 'Bilinmeyen';
    final soyad = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return patient_model.Patient(
      hastaId: ev.hastaId as int? ?? 0,
      kullaniciId: ev.hastaId as int? ?? 0,
      ad: ad,
      soyad: soyad,
      tani: (ev.hastalikAdi ?? ev.diagnosis ?? 'Tanı Yok').toString(),
      durum: 'Aktif Hasta',
      degerlendirmeler: [],
    );
  }

  Future<void> _navigateToResults() async {
    if (_selectedEvaluations.length != 2) return;

    // Yükleniyor göstergesi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
      ),
    );

    try {
      // Tarihe göre sırala
      final sorted = List<dynamic>.from(_selectedEvaluations);
      sorted.sort((a, b) {
        DateTime dtA, dtB;
        try {
          dtA = DateTime.parse(a.degerlendirmeTarihi.toString());
        } catch (_) {
          dtA = DateTime.now();
        }
        try {
          dtB = DateTime.parse(b.degerlendirmeTarihi.toString());
        } catch (_) {
          dtB = DateTime.now();
        }
        return dtA.compareTo(dtB);
      });

      final startEv = sorted[0];
      final endEv = sorted[1];

      // Test sonuçlarını API'den çek (paralel)
      final results = await Future.wait([
        _toEvaluationDateWithTests(startEv),
        _toEvaluationDateWithTests(endEv),
      ]);

      final startDate = results[0];
      final endDate = results[1];
      final patient = _buildPatient(startEv);

      if (!mounted) return;
      Navigator.pop(context); // loading dialog'u kapat

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            patient: patient,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loading dialog'u kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenemedi: $e')),
      );
    }
  }

  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _textLight, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Hasta adına göre ara',
                hintStyle: TextStyle(
                  color: _textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_searchQuery.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon:
              const Icon(Icons.close_rounded, color: _textLight, size: 20),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Future<void> _openForm({bool isEdit = false}) async {
    final provider = context.read<EvaluationProvider>();
    if (!isEdit) provider.clearSelection();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: EvaluationFormScreen(isEdit: isEdit),
        ),
      ),
    );

    if (widget.hastaId != null) {
      await provider.loadEvaluationsByPatient(widget.hastaId!);
    } else {
      await provider.loadEvaluations();
    }
  }

  Future<void> _deleteEvaluation(int id) async {
    final provider = context.read<EvaluationProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Değerlendirmeyi sil'),
        content: const Text(
          'Bu değerlendirmeyi silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    await provider.delete(id);
    if (widget.hastaId != null) {
      await provider.loadEvaluationsByPatient(widget.hastaId!);
    } else {
      await provider.loadEvaluations();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değerlendirme silindi')),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return 'AK';
    return parts.map((e) => e[0]).join().toUpperCase();
  }

  String _safeText(dynamic value, {String fallback = '—'}) {
    final text = value?.toString() ?? '';
    final trimmed = text.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _safeHastaAdi(dynamic value) {
    return _safeText(value, fallback: 'Bilinmeyen hasta');
  }

  String _resolveDiagnosis(dynamic ev) {
    String firstMeaningfulLine(String value) {
      for (final raw in value.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final lower = line.toLowerCase();
        if (lower == 'klinisyen notları' ||
            lower == 'semptomlar:' ||
            lower == 'hastalık:' ||
            lower == 'fonksiyonel:' ||
            lower == 'klinik tip:' ||
            lower == 'klinik tip') {
          continue;
        }
        return line;
      }
      return '';
    }

    final diagnosisText = (ev.diagnosis ?? '').toString().trim();
    if (diagnosisText.isNotEmpty) return diagnosisText;

    final hastalikAdi = (ev.hastalikAdi ?? '').toString().trim();
    if (hastalikAdi.isNotEmpty) return hastalikAdi;

    final candidates = [
      (ev.klinisyenNotlari ?? '').toString(),
      (ev.notlar ?? '').toString(),
      (ev.hikaye ?? '').toString(),
    ];

    for (final block in candidates) {
      final line = firstMeaningfulLine(block);
      if (line.isNotEmpty) return line;
    }

    return 'Tanı veya not bilgisi yok.';
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: _primary, size: 22),
          ),
        ),
      ),
      title: const Text(
        'Klinik Değerlendirmeler',
        style: TextStyle(
          color: _textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        // Karşılaştırma modu toggle butonu
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: _toggleCompareMode,
            icon: Icon(
              _compareMode ? Icons.close_rounded : Icons.compare_arrows_rounded,
              size: 18,
              color: _compareMode ? Colors.redAccent : _primary,
            ),
            label: Text(
              _compareMode ? 'İptal' : 'Karşılaştır',
              style: TextStyle(
                color: _compareMode ? Colors.redAccent : _primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _textDark,
                size: 27,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4A4A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 6),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'AK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _border),
      ),
    );
  }

  Widget _topHeader() {
    final baslik = widget.hastaAdi != null
        ? '${widget.hastaAdi} — Değerlendirmeler'
        : 'Hasta Değerlendirmelerim';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              baslik,
              style: const TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Karşılaştırma modu aktifken üstte gösterilen seçim bilgi bandı
  Widget _compareSelectionBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: Color(0xFFCCE9E6))),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedEvaluations.isEmpty
                  ? 'Karşılaştırmak için 2 değerlendirme seçin'
                  : _selectedEvaluations.length == 1
                  ? '1 değerlendirme seçildi — 1 tane daha seçin'
                  : '2 değerlendirme seçildi',
              style: const TextStyle(
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_selectedEvaluations.length == 2)
            ElevatedButton.icon(
              onPressed: _navigateToResults,
              icon: const Icon(Icons.compare_arrows_rounded,
                  size: 16, color: Colors.white),
              label: const Text(
                'Karşılaştır',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: _primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Henüz değerlendirme yok',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hasta kayıtlarını takip etmek için yeni bir değerlendirme oluşturun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Yeni Değerlendirme',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractPackedSection(String source, String title) {
    final text = source.trim();
    if (text.isEmpty) return '';

    final header = '$title:\n';
    final start = text.lastIndexOf(header);
    if (start == -1) return '';

    final contentStart = start + header.length;
    final nextHeaders = [
      '\n\nSemptomlar:\n',
      '\n\nHastalık:\n',
      '\n\nKlinisyen Notları:\n',
      '\n\nFonksiyonel:\n',
      '\n\nKlinik tip:',
    ];

    int? end;
    for (final marker in nextHeaders) {
      final idx = text.indexOf(marker, contentStart);
      if (idx != -1 && (end == null || idx < end)) {
        end = idx;
      }
    }

    final result = end == null
        ? text.substring(contentStart)
        : text.substring(contentStart, end);

    return result.trim();
  }

  int _savedSymptomCount(dynamic ev) {
    const emptyValues = {
      'yok',
      'none',
      '-',
      'seçilmedi',
      'secilmedi',
      'boş',
      'bos',
    };

    int countListSymptoms(dynamic symptomsValue) {
      if (symptomsValue is! List) return 0;
      final uniqueSymptoms = <String>{};
      for (final raw in symptomsValue) {
        final symptom = raw?.toString().trim() ?? '';
        if (symptom.isEmpty) continue;
        final normalized = symptom.toLowerCase();
        if (emptyValues.contains(normalized)) continue;
        if (normalized.startsWith('yeni bulgu:')) continue;
        uniqueSymptoms.add(normalized);
      }
      return uniqueSymptoms.length;
    }

    final listCount = countListSymptoms(ev.symptoms);
    if (listCount > 0) return listCount;

    final notlar = (ev.notlar ?? '').toString().trim();
    if (notlar.isEmpty) return 0;

    final semptomlar = _extractPackedSection(notlar, 'Semptomlar');
    if (semptomlar.isEmpty) return 0;

    const labels = [
      'Motor',
      'Duyusal',
      'Emosyonel',
      'Kognitif',
      'Pulmoner',
      'Diğer',
    ];

    final uniqueSymptoms = <String>{};

    for (final rawLine in semptomlar.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      String? matchedLabel;
      for (final label in labels) {
        if (line.toLowerCase().startsWith('${label.toLowerCase()}:')) {
          matchedLabel = label;
          break;
        }
      }

      if (matchedLabel == null) continue;

      final value = line.substring(matchedLabel.length + 1).trim();
      if (value.isEmpty) continue;

      final lower = value.toLowerCase();
      final extraIndex = lower.indexOf('yeni bulgu:');
      final selectedPart = extraIndex == -1
          ? value
          : value.substring(0, extraIndex).trim();

      if (selectedPart.isEmpty) continue;

      for (final item in selectedPart.split(',')) {
        final symptom = item.trim();
        if (symptom.isEmpty) continue;
        final normalized = symptom.toLowerCase();
        if (emptyValues.contains(normalized)) continue;
        if (normalized.startsWith('yeni bulgu:')) continue;
        uniqueSymptoms.add(normalized);
      }
    }

    return uniqueSymptoms.length;
  }

  Widget _card(EvaluationProvider provider, dynamic ev) {
    final previewText = _resolveDiagnosis(ev);
    final hastaAdi = _safeHastaAdi(ev.hastaAdSoyad);
    final olusturmaTarihi = ev.olusturmaTarihi as DateTime?;
    final symptomCount = _savedSymptomCount(ev);
    final selected = _isSelected(ev);

    return GestureDetector(
      onTap: _compareMode ? () => _toggleSelection(ev) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _primary.withOpacity(0.06) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Seçim modu: checkbox veya avatar
                if (_compareMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected ? _primary : _primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: selected
                          ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24)
                          : Text(
                        _initials(hastaAdi),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _initials(hastaAdi),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hastaAdi,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(olusturmaTarihi),
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_compareMode)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        provider.select(ev);
                        await _openForm(isEdit: true);
                      }
                      if (value == 'delete' && ev.id != null) {
                        await _deleteEvaluation(ev.id!);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                previewText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    symptomCount == 0
                        ? 'Semptom seçilmedi'
                        : '$symptomCount semptom',
                    style: const TextStyle(
                      color: _success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (!_compareMode)
                  TextButton.icon(
                    onPressed: () async {
                      provider.select(ev);
                      await _openForm(isEdit: true);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Aç'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Text(
                    selected ? '✓ Seçildi' : 'Seçmek için dokun',
                    style: TextStyle(
                      color: selected ? _primary : _textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => const _EvaluationSkeletonCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Consumer<EvaluationProvider>(
        builder: (context, provider, _) {
          final filteredEvaluations = provider.evaluations.where((ev) {
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) return true;
            final hastaAdi = _safeHastaAdi(ev.hastaAdSoyad).toLowerCase();
            return hastaAdi.contains(query);
          }).toList();

          if (provider.isListLoading && provider.evaluations.isEmpty) {
            return _loadingList();
          }

          if (provider.evaluations.isEmpty) {
            return Column(
              children: [
                _topHeader(),
                _searchBar(),
                Expanded(child: _emptyState()),
              ],
            );
          }

          return Column(
            children: [
              _topHeader(),
              if (_compareMode) _compareSelectionBanner(),
              _searchBar(),
              Expanded(
                child: filteredEvaluations.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.search_off_rounded,
                          color: _textLight,
                          size: 42,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aramaya uygun değerlendirme bulunamadı.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textMid,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : RefreshIndicator(
                  color: _primary,
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    itemCount: filteredEvaluations.length,
                    itemBuilder: (_, i) {
                      final ev = filteredEvaluations[i];
                      return _card(provider, ev);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _compareMode
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Değerlendirme',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EvaluationSkeletonCard extends StatelessWidget {
  const _EvaluationSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}