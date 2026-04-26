// Sıla Özer
// lib/views/comparison_screen.dart
// API bağlantısı: EvaluationService → Supabase REST
// UI değişmedi, sadece mock_data → API ile değiştirildi

import 'dart:async';
import 'result_screen.dart';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/evaluation_service.dart';
import '../core/app_theme.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final EvaluationService _evaluationService = EvaluationService();

  // Arama state
  String _searchQuery = "";
  bool _isSearching = false;
  String? _searchError;
  List<Patient> _filteredPatients = [];
  Timer? _searchDebounce;

  // Hasta & Değerlendirme state
  Patient? _selectedPatient;
  bool _isLoadingEvaluations = false;
  String? _evaluationError;
  List<EvaluationDate> _patientEvaluations = [];

  EvaluationDate? _selectedStartDate;
  EvaluationDate? _selectedEndDate;

  // 300ms debounce ile arama — gereksiz API isteği önler
  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _searchError = null;
      if (val.trim().isEmpty) {
        _filteredPatients = [];
        _isSearching = false;
      }
    });
    _searchDebounce?.cancel();
    if (val.trim().isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 300), _handleSearch);
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _searchError = null;
      _filteredPatients = [];
    });
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }
    setState(() => _isSearching = true);
    try {
      // EvaluationService → GET /hastalar?q=:query (Supabase)
      final results = await _evaluationService.searchPatients(query);
      if (!mounted) return;
      setState(() {
        _filteredPatients = results;
        _isSearching = false;
        if (results.isEmpty) _searchError = 'Aramaya uygun hasta bulunamadı.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Hasta araması yapılamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  // Hasta seçilince değerlendirmelerini API'dan yükle
  Future<void> _selectPatient(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _filteredPatients = [];
      _searchQuery = "";
      _searchController.clear();
      _selectedStartDate = null;
      _selectedEndDate = null;
      _patientEvaluations = [];
      _evaluationError = null;
      _isLoadingEvaluations = true;
    });
    try {
      // EvaluationService → GET /degerlendirmeler?hastaId=eq.:id (Supabase)
      final evaluations =
      await _evaluationService.getEvaluationsForPatient(patient.hastaId);
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
        _evaluationError =
        'Değerlendirmeler yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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
                  // HASTA ALANI
                  if (_selectedPatient == null) ...[
                    if (_filteredPatients.isNotEmpty) ...[
                      const Text(
                        "HASTA LİSTESİ",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kTextGrey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._filteredPatients.map((p) => _buildPatientCard(p)),
                    ] else
                      const SizedBox(height: 10),
                  ] else ...[
                    const Text(
                      "SEÇİLİ HASTA",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kTextGrey,
                        letterSpacing: 0.8,
                      ),
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
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DEĞERLENDİRME DROPDOWNLARI
                  if (_selectedPatient != null &&
                      _isLoadingEvaluations) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimary),
                      ),
                    ),
                  ] else if (_selectedPatient != null &&
                      _evaluationError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _evaluationError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
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
                  ] else if (_selectedPatient != null) ...[
                    _buildPassiveBox("BAŞLANGIÇ DEĞERLENDİRMESİ",
                        emptyText:
                        "Bu hastaya ait değerlendirme bulunamadı."),
                    const SizedBox(height: 16),
                    _buildPassiveBox("BİTİŞ DEĞERLENDİRMESİ",
                        emptyText:
                        "Bu hastaya ait değerlendirme bulunamadı."),
                  ] else ...[
                    _buildPassiveBox("BAŞLANGIÇ DEĞERLENDİRMESİ"),
                    const SizedBox(height: 16),
                    _buildPassiveBox("BİTİŞ DEĞERLENDİRMESİ"),
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
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_selectedPatient != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPatient = null;
                      _selectedStartDate = null;
                      _selectedEndDate = null;
                      _filteredPatients = [];
                      _patientEvaluations = [];
                      _evaluationError = null;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: kPrimary, size: 16),
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.compare_arrows,
                      color: Colors.white, size: 20),
                ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Değerlendirme Karşılaştırma Raporu",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),

          // Arama kutusu — yalnızca hasta seçilmemişken
          if (_selectedPatient == null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _handleSearch(),
                    style:
                    const TextStyle(fontSize: 14, color: kTextDark),
                    decoration: InputDecoration(
                      hintText: "Kimlik, ad veya tanı girin...",
                      hintStyle:
                      const TextStyle(color: kTextHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: kTextHint, size: 20),
                      filled: true,
                      fillColor: kInputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: kPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(72, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Bul",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Arama sonuç listesi
            if (_searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child:
                    CircularProgressIndicator(color: kPrimary),
                  ),
                )
                    : _filteredPatients.isNotEmpty
                    ? ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredPatients.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final patient = _filteredPatients[index];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.person_outline,
                            color: kPrimary,
                            size: 20),
                      ),
                      title: Text(
                        patient.tamAd.trim().isNotEmpty
                            ? patient.tamAd
                            : 'Hasta #${patient.hastaId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      subtitle: Text(
                        patient.tani,
                        style: const TextStyle(
                            color: kTextGrey, fontSize: 12),
                      ),
                      onTap: () => _selectPatient(patient),
                    );
                  },
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _searchError ?? 'Sonuç bulunamadı.',
                    style: const TextStyle(
                        color: Colors.redAccent),
                  ),
                ),
              ),
            ],
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
          color: isSelected ? kPrimary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline,
                  size: 26, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.tamAd.trim().isNotEmpty
                        ? patient.tamAd
                        : 'Hasta #${patient.hastaId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.tani,
                    style: const TextStyle(
                        color: kTextGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        patient.durum,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isSelected ? kPrimary : kTextHint,
            ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: kTextGrey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kInputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value != null ? kPrimary : const Color(0xFFE2E8F0),
              width: value != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<EvaluationDate>(
              value: value,
              hint: const Text("Seçiniz...",
                  style: TextStyle(color: kTextHint, fontSize: 14)),
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: kPrimary),
              // API'dan gelen _patientEvaluations listesi
              items: _patientEvaluations.map((eval) {
                return DropdownMenuItem<EvaluationDate>(
                  value: eval,
                  child: Text(
                    "${eval.tarih} — ${eval.baslik}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, color: kTextDark),
                  ),
                );
              }).toList(),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: kTextGrey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: kInputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            emptyText,
            style: const TextStyle(color: kTextHint, fontSize: 14),
          ),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  patient: _selectedPatient!,
                  startDate: _selectedStartDate!,
                  endDate: _selectedEndDate!,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text(
            "Analizi Görüntüle",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      );
    } else if (ayniSecim) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD97706), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Karşılaştırma için iki farklı değerlendirme tarihi seçmelisiniz.",
                style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimary.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Analize başlamak için bir hasta ve iki farklı tarih seçmelisiniz.",
                style: TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
  }
}