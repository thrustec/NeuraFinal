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

      backgroundColor: AppTheme.background,

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

                      const Text("HASTA LİSTESİ", style: AppTheme.sectionLabel),

                      const SizedBox(height: 10),

                      ..._filteredPatients.map((p) => _buildPatientCard(p)),

                    ] else

                      const SizedBox(height: 10),

                  ] else ...[

                    const Text("SEÇİLİ HASTA", style: AppTheme.sectionLabel),

                    const SizedBox(height: 10),

                    _buildPatientCard(_selectedPatient!),

                  ],



                  const SizedBox(height: 24),

                  Text(

                    "KARŞILAŞTIRILACAK DEĞERLENDİRMELER",

                    style: AppTheme.sectionLabel.copyWith(

                      color: const Color(0xFF2D3A4C),

                    ),

                  ),

                  const SizedBox(height: 12),



// DEĞERLENDİRME DROPDOWNLARI

// loading / error / empty / dolu state'leri

                  if (_selectedPatient != null && _isLoadingEvaluations) ...[

                    const Padding(

                      padding: EdgeInsets.symmetric(vertical: 24),

                      child: Center(child: CircularProgressIndicator()),

                    ),

                  ] else if (_selectedPatient != null && _evaluationError != null) ...[

                    Padding(

                      padding: const EdgeInsets.only(top: 8),

                      child: Text(

                        _evaluationError!,

                        style: const TextStyle(color: Colors.redAccent),

                      ),

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

                  ] else if (_selectedPatient != null) ...[

                    _buildPassiveBox("BAŞLANGIÇ DEĞERLENDİRMESİ",

                        emptyText: "Bu hastaya ait değerlendirme bulunamadı."),

                    const SizedBox(height: 16),

                    _buildPassiveBox("BİTİŞ DEĞERLENDİRMESİ",

                        emptyText: "Bu hastaya ait değerlendirme bulunamadı."),

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

      decoration: AppTheme.headerDecoration,

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

                      color: AppTheme.primaryLight,

                      borderRadius: BorderRadius.circular(10),

                    ),

                    child: const Icon(Icons.arrow_back_ios_new,

                        color: AppTheme.primary, size: 18),

                  ),

                )

              else

                Container(

                  width: 36,

                  height: 36,

                  decoration: BoxDecoration(

                    color: AppTheme.primary,

                    borderRadius: BorderRadius.circular(10),

                  ),

                  child: const Icon(Icons.compare_arrows,

                      color: Colors.white, size: 20),

                ),

              const SizedBox(width: 12),

              const Expanded(

                child: Text(

                  "Değerlendirme Karşılaştırma Raporu",

                  style: AppTheme.pageTitle,

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

                    style: const TextStyle(

                        fontSize: 14, color: AppTheme.textPrimary),

                    decoration: AppTheme.inputDecoration(

                      "HASTA ARA",

                      hint: "Kimlik, ad veya tanı girin...",

                      prefix: const Icon(Icons.search,

                          color: AppTheme.textHint, size: 20),

                    ),

                  ),

                ),

                const SizedBox(width: 10),

                ElevatedButton(

                  onPressed: _handleSearch,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: AppTheme.primary,

                    foregroundColor: Colors.white,

                    minimumSize: const Size(80, 52),

                    shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(12)),

                    elevation: 0,

                  ),

                  child: const Text("Bul",

                      style: TextStyle(fontWeight: FontWeight.w600)),

                ),

              ],

            ),

// Arama sonuç listesi — header altında açılır

            if (_searchQuery.trim().isNotEmpty) ...[

              const SizedBox(height: 10),

              Container(

                constraints: const BoxConstraints(maxHeight: 220),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: AppTheme.divider),

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

                  child: Center(child: CircularProgressIndicator()),

                )

                    : _filteredPatients.isNotEmpty

                    ? ListView.separated(

                  shrinkWrap: true,

                  itemCount: _filteredPatients.length,

                  separatorBuilder: (_, __) =>

                  const Divider(height: 1, color: AppTheme.divider),

                  itemBuilder: (context, index) {

                    final patient = _filteredPatients[index];

                    return ListTile(

                      leading: const Icon(Icons.person_outline,

                          color: AppTheme.primary),

                      title: Text(patient.tamAd.trim().isNotEmpty

                          ? patient.tamAd

                          : 'Hasta #${patient.hastaId}'),

                      subtitle: Text(patient.tani),

                      onTap: () => _selectPatient(patient),

                    );

                  },

                )

                    : Padding(

                  padding: const EdgeInsets.all(16),

                  child: Text(

                    _searchError ?? 'Sonuç bulunamadı.',

                    style:

                    const TextStyle(color: Colors.redAccent),

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

          color: isSelected ? AppTheme.primaryLight : AppTheme.background,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(

            color: isSelected ? AppTheme.primary : AppTheme.divider,

            width: isSelected ? 1.5 : 1,

          ),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withValues(alpha: 0.04),

              blurRadius: 8,

              offset: const Offset(0, 2),

            ),

          ],

        ),

        child: Row(

          children: [

            Container(

              width: 48,

              height: 48,

              decoration: BoxDecoration(

                color: AppTheme.primaryLight,

                borderRadius: BorderRadius.circular(12),

              ),

              child: const Icon(Icons.person_outline,

                  size: 26, color: AppTheme.primary),

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

                    style: AppTheme.cardTitle,

                  ),

                  const SizedBox(height: 2),

                  Text(patient.tani, style: AppTheme.bodyText),

                  const SizedBox(height: 2),

                  Row(

                    children: [

                      Container(

                        width: 6,

                        height: 6,

                        decoration: const BoxDecoration(

                          color: AppTheme.success,

                          shape: BoxShape.circle,

                        ),

                      ),

                      const SizedBox(width: 5),

                      Text(

                        patient.durum,

                        style: const TextStyle(

                          color: AppTheme.success,

                          fontSize: 12,

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

            Icon(Icons.chevron_right,

                color: isSelected ? AppTheme.primary : AppTheme.textHint),

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

        Text(label, style: AppTheme.sectionLabel),

        const SizedBox(height: 8),

        Container(

          decoration: BoxDecoration(

            color: AppTheme.surface,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(

              color: value != null ? AppTheme.primary : AppTheme.divider,

              width: value != null ? 1.5 : 1,

            ),

          ),

          child: DropdownButtonHideUnderline(

            child: DropdownButtonFormField<EvaluationDate>(

              value: value,

              hint: const Text("Seçiniz...",

                  style: TextStyle(color: AppTheme.textHint, fontSize: 14)),

              isExpanded: true,

              decoration: const InputDecoration(

                border: InputBorder.none,

                contentPadding:

                EdgeInsets.symmetric(horizontal: 16, vertical: 4),

              ),

              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),

// API'dan gelen _patientEvaluations listesi

              items: _patientEvaluations.map((eval) {

                return DropdownMenuItem<EvaluationDate>(

                  value: eval,

                  child: Text(

                    "${eval.tarih} — ${eval.baslik}",

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(

                        fontSize: 14, color: AppTheme.textPrimary),

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

        Text(label, style: AppTheme.sectionLabel),

        const SizedBox(height: 8),

        Container(

          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          decoration: BoxDecoration(

            color: AppTheme.surface,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: AppTheme.divider),

          ),

          child: Text(emptyText,

              style: const TextStyle(color: AppTheme.textHint, fontSize: 14)),

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

        _selectedStartDate!.degerlendirmeId == _selectedEndDate!.degerlendirmeId;



    if (allSelected && !ayniSecim) {

      return ElevatedButton.icon(

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

        style: AppTheme.primaryButtonStyle,

        icon: const Icon(Icons.bar_chart_rounded, size: 20),

        label: const Text("Analizi Görüntüle"),

      );

    } else if (ayniSecim) {

      return Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: const Color(0xFFFEF3C7),

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: const Color(0xFFFCD34D)),

        ),

        child: const Row(

          children: [

            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),

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

          color: AppTheme.primaryLight,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: AppTheme.primaryBorder),

        ),

        child: const Row(

          children: [

            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),

            SizedBox(width: 12),

            Expanded(

              child: Text(

                "Analize başlamak için bir hasta ve iki farklı tarih seçmelisiniz.",

                style: TextStyle(

                    color: AppTheme.primary,

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