// Sıla Özer
// lib/views/comparison_screen.dart
// API bağlantısı: EvaluationService → Supabase REST
// UI: Geri tuşu ve navigasyon akışı güncellendi

import 'dart:async';
import 'result_screen.dart';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/evaluation_service.dart';

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

  // 300ms debounce ile arama
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
      final evaluations = await _evaluationService.getEvaluationsForPatient(patient.hastaId);
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
                  if (_selectedPatient == null) ...[
                      const SizedBox(height: 10),
                  ] else ...[
                    const Text(
                      "SEÇİLİ HASTA",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextGrey, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 10),
                    _buildPatientCard(_selectedPatient!),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    "KARŞILAŞTIRILACAK DEĞERLENDİRMELER",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextDark, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedPatient != null && _isLoadingEvaluations) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: kPrimary)),
                    ),
                  ] else if (_selectedPatient != null && _evaluationError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_evaluationError!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ] else if (_selectedPatient != null && _patientEvaluations.isNotEmpty) ...[
                    _buildDropdown(
                      label: "BAŞLANGIÇ DEĞERLENDİRMESİ",
                      value: _selectedStartDate,
                      onChanged: (val) => setState(() => _selectedStartDate = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: "BİTİŞ DEĞERLENDİRMESİ",
                      value: _selectedEndDate,
                      onChanged: (val) => setState(() => _selectedEndDate = val),
                    ),
                  ] else ...[
                    _buildPassiveBox("BAŞLANGIÇ DEĞERLENDİRMESİ",
                        emptyText: _selectedPatient != null ? "Değerlendirme bulunamadı." : "Önce bir hasta seçin..."),
                    const SizedBox(height: 16),
                    _buildPassiveBox("BİTİŞ DEĞERLENDİRMESİ",
                        emptyText: _selectedPatient != null ? "Değerlendirme bulunamadı." : "Önce bir hasta seçin..."),
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
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // --- DİNAMİK GERİ TUŞU ---
              GestureDetector(
                onTap: () {
                  if (_selectedPatient != null) {
                    setState(() {
                      _selectedPatient = null;
                      _selectedStartDate = null;
                      _selectedEndDate = null;
                      _filteredPatients = [];
                      _patientEvaluations = [];
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: kPrimary, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Değerlendirme Karşılaştırma Raporu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                ),
              ),
              if (_selectedPatient != null)
                const Icon(Icons.compare_arrows, color: kTextHint, size: 20),
            ],
          ),

          if (_selectedPatient == null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _handleSearch(),
                    style: const TextStyle(fontSize: 14, color: kTextDark),
                    decoration: InputDecoration(
                      hintText: "Kimlik, ad veya tanı girin...",
                      hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: kTextHint, size: 20),
                      filled: true,
                      fillColor: kInputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Bul", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: kPrimary)),
                )
                    : _filteredPatients.isNotEmpty
                    ? ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredPatients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final p = _filteredPatients[index];
                    return ListTile(
                      title: Text(p.tamAd, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(p.tani, style: const TextStyle(fontSize: 12)),
                      onTap: () => _selectPatient(p),
                    );
                  },
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _searchError ?? 'Sonuç bulunamadı.',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
    final bool isSelected = _selectedPatient?.hastaId == patient.hastaId;
    return GestureDetector(
      onTap: () => _selectPatient(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kPrimary : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_outline, size: 26, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.tamAd.isNotEmpty ? patient.tamAd : 'Hasta #${patient.hastaId}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
                  Text(patient.tani, style: const TextStyle(color: kTextGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(patient.durum, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isSelected ? kPrimary : kTextHint),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required EvaluationDate? value, required Function(EvaluationDate?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextGrey, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kInputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value != null ? kPrimary : const Color(0xFFE2E8F0), width: value != null ? 1.5 : 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<EvaluationDate>(
              initialValue: value,
              hint: const Text("Seçiniz...", style: TextStyle(color: kTextHint, fontSize: 14)),
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
              icon: const Icon(Icons.keyboard_arrow_down, color: kPrimary),
              items: _patientEvaluations.map((eval) => DropdownMenuItem<EvaluationDate>(
                value: eval,
                child: Text("${eval.tarih} — ${eval.baslik}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: kTextDark)),
              )).toList(),
              onChanged: (val) => onChanged(val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassiveBox(String label, {String emptyText = "Önce bir hasta seçin..."}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextGrey, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: kInputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Text(emptyText, style: const TextStyle(color: kTextHint, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final bool allSelected = _selectedPatient != null && _selectedStartDate != null && _selectedEndDate != null;
    final bool ayniSecim = _selectedStartDate != null && _selectedEndDate != null && _selectedStartDate!.degerlendirmeId == _selectedEndDate!.degerlendirmeId;

    if (allSelected && !ayniSecim) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsScreen(patient: _selectedPatient!, startDate: _selectedStartDate!, endDate: _selectedEndDate!))),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text("Analizi Görüntüle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
    } else if (ayniSecim) {
      return _buildInfoBox("Karşılaştırma için iki farklı değerlendirme tarihi seçmelisiniz.", const Color(0xFFD97706), const Color(0xFFFEF3C7), Icons.warning_amber_rounded);
    } else {
      return _buildInfoBox("Analize başlamak için bir hasta ve iki farklı tarih seçmelisiniz.", kPrimary, kPrimary.withValues(alpha: 0.07), Icons.info_outline_rounded);
    }
  }

  Widget _buildInfoBox(String text, Color color, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha:0.2))),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)))]),
    );
  }
}