// Sıla Özer
// lib/views/comparison_screen.dart

import 'result_screen.dart';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/evaluation_service.dart';
import '../widgets/hasta_arama_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// NeuraApp Design System — Klinisyen Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final EvaluationService _evaluationService = EvaluationService();


  // Hasta & Değerlendirme state
  Patient? _selectedPatient;
  bool _isLoadingEvaluations = false;
  String? _evaluationError;
  List<EvaluationDate> _patientEvaluations = [];

  EvaluationDate? _selectedStartDate;
  EvaluationDate? _selectedEndDate;

  Future<void> _selectHastaFromWidget(HastaAramaSonucu hasta) async {
    final patient = Patient(
      hastaId: hasta.hastaId,
      kullaniciId: 0,
      ad: hasta.ad,
      soyad: hasta.soyad,
      tani: hasta.tani ?? 'Tanı Yok',
      durum: 'Aktif Hasta',
      degerlendirmeler: const [],
    );

    await _selectPatient(patient);
  }

  Future<void> _selectPatient(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _selectedStartDate = null;
      _selectedEndDate = null;
      _patientEvaluations = [];
      _evaluationError = null;
      _isLoadingEvaluations = true;
    });
    try {
      final clinicianId = context.read<AuthProvider>().user?.klinisyenId;
      final evaluations =
      await _evaluationService.getEvaluationsForPatient(
        patient.hastaId,
        klinisyenId: clinicianId,
      );
      if (!mounted) return;
      setState(() {
        _patientEvaluations = evaluations;
        _isLoadingEvaluations = false;
        if (evaluations.isEmpty) {
          _evaluationError = 'Bu hastaya ait değerlendirme bulunamadı.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvaluations = false;
        _evaluationError = 'Değerlendirmeler yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  // ── GERİ TUŞU MANTIĞI ──────────────────────────────────────────────────
  // 3 durum var:
  //   1. Hasta seçili → hasta seçimini temizle (arama ekranına dön)
  //   2. Hasta seçili değil + stack'te önceki sayfa var → pop yap
  //   3. Hasta seçili değil + stack'in en altındayız (alt bar) → pop yapma, beyaz ekran çıkar
  void _handleBack() {
    if (_selectedPatient != null) {
      // Durum 1: Hasta seçimini temizle
      setState(() {
        _selectedPatient = null;
        _selectedStartDate = null;
        _selectedEndDate = null;
        _patientEvaluations = [];
        _evaluationError = null;
      });
    } else if (Navigator.canPop(context)) {
      // Durum 2: Önceki sayfa varsa geri git (hızlı erişim kısayolu vb.)
      Navigator.pop(context);
    }
    // Durum 3: Alt bardan açıldıysa ve hasta seçili değilse → hiçbir şey yapma
    // canPop false döner, pop çağrılmaz, beyaz ekran olmaz
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPatient == null) ...[
                    const SizedBox(height: 10),
                  ] else ...[
                    const Text(
                      "SEÇİLİ HASTA",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kTextGrey,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 10),
                    _buildPatientCard(_selectedPatient!),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    "KARŞILAŞTIRILACAK DEĞERLENDİRMELER",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedPatient != null && _isLoadingEvaluations) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: CircularProgressIndicator(color: kPrimary)),
                    ),
                  ] else if (_selectedPatient != null &&
                      _evaluationError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_evaluationError!,
                          style:
                          const TextStyle(color: Colors.redAccent)),
                    ),
                  ] else if (_selectedPatient != null &&
                      _patientEvaluations.isNotEmpty) ...[
                    _buildDropdown(
                      label: "BAŞLANGIÇ DEĞERLENDİRMESİ",
                      value: _selectedStartDate,
                      onChanged: (val) =>
                          setState(() => _selectedStartDate = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: "BİTİŞ DEĞERLENDİRMESİ",
                      value: _selectedEndDate,
                      onChanged: (val) =>
                          setState(() => _selectedEndDate = val),
                    ),
                  ] else ...[
                    _buildPassiveBox(
                      "BAŞLANGIÇ DEĞERLENDİRMESİ",
                      emptyText: _selectedPatient != null
                          ? "Değerlendirme bulunamadı."
                          : "Önce bir hasta seçin...",
                    ),
                    const SizedBox(height: 16),
                    _buildPassiveBox(
                      "BİTİŞ DEĞERLENDİRMESİ",
                      emptyText: _selectedPatient != null
                          ? "Değerlendirme bulunamadı."
                          : "Önce bir hasta seçin...",
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildBottomAction(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Geri okunu göster/gizle:
    //   - Hasta seçiliyse → her zaman göster (hasta seçimini temizler)
    //   - Hasta seçili değil + pop yapılabiliyorsa → göster (hızlı erişim vb.)
    //   - Hasta seçili değil + pop yapılamıyorsa → gizle (alt bar, gidecek yer yok)
    final bool showBack =
        _selectedPatient != null || Navigator.canPop(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Geri butonu — duruma göre gösterilir
              if (showBack)
                GestureDetector(
                  onTap: _handleBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: kPrimary, size: 18),
                  ),
                )
              else
              // Alt bardan açıldığında geri butonu yerine ikon göster
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.compare_arrows,
                      color: kPrimary, size: 20),
                ),
              const Expanded(
                child: Text(
                  "Değerlendirme Karşılaştırma Raporu",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextDark),
                ),
              ),
              if (_selectedPatient != null)
                const Icon(Icons.compare_arrows, color: kTextHint, size: 20),
            ],
          ),

          // Arama kutusu
          if (_selectedPatient == null) ...[
            const SizedBox(height: 16),
            HastaAramaWidget(
              klinisyenId:
                  context.watch<AuthProvider>().user?.klinisyenId?.toString(),
              primaryColor: kPrimary,
              onHastaSecildi: _selectHastaFromWidget,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final bool isSelected =
        _selectedPatient?.hastaId == patient.hastaId;
    return GestureDetector(
      onTap: () => _selectPatient(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? kPrimary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_outline,
                  size: 26, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.tamAd.isNotEmpty
                        ? patient.tamAd
                        : 'Hasta #${patient.hastaId}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kTextDark),
                  ),
                  Text(patient.tani,
                      style: const TextStyle(
                          color: kTextGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(patient.durum,
                          style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isSelected ? kPrimary : kTextHint),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required EvaluationDate? value,
    required Function(EvaluationDate?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kTextGrey,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kInputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: value != null
                    ? kPrimary
                    : const Color(0xFFE2E8F0),
                width: value != null ? 1.5 : 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<EvaluationDate>(
              initialValue: value,
              hint: const Text("Seçiniz...",
                  style:
                  TextStyle(color: kTextHint, fontSize: 14)),
              isExpanded: true,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: kPrimary),
              items: _patientEvaluations
                  .map((eval) => DropdownMenuItem<EvaluationDate>(
                value: eval,
                child: Text(
                  "${eval.tarih} — ${eval.baslik}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, color: kTextDark),
                ),
              ))
                  .toList(),
              onChanged: (val) => onChanged(val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassiveBox(String label,
      {String emptyText = "Önce bir hasta seçin..."}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kTextGrey,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: kInputFill,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: const Color(0xFFE2E8F0))),
          child: Text(emptyText,
              style:
              const TextStyle(color: kTextHint, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final bool allSelected = _selectedPatient != null &&
        _selectedStartDate != null &&
        _selectedEndDate != null;
    final bool ayniSecim = _selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedStartDate!.degerlendirmeId ==
            _selectedEndDate!.degerlendirmeId;

    if (allSelected && !ayniSecim) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                patient: _selectedPatient!,
                startDate: _selectedStartDate!,
                endDate: _selectedEndDate!,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text("Analizi Görüntüle",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
    } else if (ayniSecim) {
      return _buildInfoBox(
        "Karşılaştırma için iki farklı değerlendirme tarihi seçmelisiniz.",
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
        Icons.warning_amber_rounded,
      );
    } else {
      return _buildInfoBox(
        "Analize başlamak için bir hasta ve iki farklı tarih seçmelisiniz.",
        kPrimary,
        kPrimary.withValues(alpha: 0.07),
        Icons.info_outline_rounded,
      );
    }
  }

  Widget _buildInfoBox(
      String text, Color color, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
