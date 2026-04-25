// Sıla Özer
// lib/views/result_screen.dart

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/comparison_result.dart';
import '../core/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final Patient patient;
  final EvaluationDate startDate;   // degerlendirmeler (başlangıç — baslangicDegerlendirmeId)
  final EvaluationDate endDate;     // degerlendirmeler (güncel — guncelDegerlendirmeId)

  const ResultsScreen({
    super.key,
    required this.patient,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final List<ComparisonResult> dynamicResults = endDate.testSonuclari.map((currentTest) {
      final baselineTest = startDate.testSonuclari.firstWhere(
            (t) => t.testAdi == currentTest.testAdi,
        orElse: () => currentTest,
      );
      return ComparisonResult(
        testAdi: currentTest.testAdi,
        baselineDeger: baselineTest.olculenDeger,
        guncelDeger: currentTest.olculenDeger,
        maxDeger: currentTest.maxDeger,
        birim: currentTest.birim,
        isLowerBetter: currentTest.isLowerBetter,
      );
    }).toList();

    // Kaç metrikte iyileşme var? — header badge için
    final int iyilesmeCount = dynamicResults.where((r) => r.iyilesme).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(context, iyilesmeCount, dynamicResults.length),
          _buildDatesHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text("Skor Karşılaştırması", style: AppTheme.cardTitle),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: dynamicResults.length,
              itemBuilder: (context, index) =>
                  _buildMeasureCard(dynamicResults[index]),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // Üst başlık
  Widget _buildHeader(BuildContext context, int iyilesmeCount, int totalCount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: AppTheme.headerDecoration,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Karşılaştırma Sonuçları", style: AppTheme.pageTitle),
                Text(
                  patient.tamAd,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iyilesmeCount >= totalCount / 2
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$iyilesmeCount/$totalCount İyileşti",
              style: TextStyle(
                color: iyilesmeCount >= totalCount / 2
                    ? AppTheme.success
                    : AppTheme.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Önce → Sonra tarih karşılaştırma kutusu
  // degerlendirmeTarihi ve notlar
  Widget _buildDatesHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(child: _dateInfoBox("ÖNCE", startDate.tarih, startDate.baslik)),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward, color: AppTheme.primary, size: 16),
          ),
          Expanded(
            child: _dateInfoBox("SONRA", endDate.tarih, endDate.baslik, isBlue: true),
          ),
        ],
      ),
    );
  }

  Widget _dateInfoBox(String label, String tarih, String baslik,
      {bool isBlue = false}) {
    return Column(
      crossAxisAlignment:
      isBlue ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBlue ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tarih,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          baslik,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          textAlign: isBlue ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  // Tek bir testin karşılaştırma kartı
  // degerlendirmeTestSonuclari + testler + testMetrikleri verilerini gösterir
  Widget _buildMeasureCard(ComparisonResult result) {
    final bool isNeutral = result.fark == 0;
    final Color statusColor = isNeutral
        ? AppTheme.textSecondary
        : (result.iyilesme ? AppTheme.success : AppTheme.danger);
    final Color statusBg = isNeutral
        ? AppTheme.surface
        : (result.iyilesme
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // testAdi
              Expanded(child: Text(result.testAdi, style: AppTheme.cardTitle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${result.fark > 0 ? '+' : ''}${result.fark.toStringAsFixed(1)} ${result.birim}",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // olculenDeger (başlangıç)
              _scoreChip("ÖNCE", result.baselineDeger, result.birim,
                  AppTheme.textSecondary, AppTheme.surface),
              const SizedBox(width: 8),
              // olculenDeger (güncel)
              _scoreChip("SONRA", result.guncelDeger, result.birim,
                  statusColor, statusBg),
            ],
          ),
          const SizedBox(height: 14),
          _buildBar(
            label: "Başlangıç",
            value: result.baselineDeger,
            maxValue: result.maxDeger,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 8),
          _buildBar(
            label: "Güncel",
            value: result.guncelDeger,
            maxValue: result.maxDeger,
            color: isNeutral
                ? AppTheme.primary
                : (result.iyilesme ? AppTheme.success : AppTheme.danger),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(
      String label, double score, String birim, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)} $birim",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double value,
    required double maxValue,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / maxValue).clamp(0.0, 1.0),
              backgroundColor: AppTheme.divider,
              color: color,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${value.toStringAsFixed(0)}/${maxValue.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              style: AppTheme.outlinedButtonStyle,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text("PDF Raporu"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text("Paylaş"),
            ),
          ),
        ],
      ),
    );
  }
}