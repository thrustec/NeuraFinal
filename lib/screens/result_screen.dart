// Sıla Özer
// lib/views/result_screen.dart

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/comparison_result.dart';


// NeuraApp Design System — Klinisyen Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class ResultsScreen extends StatelessWidget {
  final Patient patient;
  final EvaluationDate startDate;
  final EvaluationDate endDate;

  const ResultsScreen({
    super.key,
    required this.patient,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final List<ComparisonResult> dynamicResults =
    endDate.testSonuclari.map((currentTest) {
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

    final int iyilesmeCount =
        dynamicResults.where((r) => r.iyilesme).length;

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(context, iyilesmeCount, dynamicResults.length),
          _buildDatesHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: kPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Skor Karşılaştırması",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
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

  Widget _buildHeader(
      BuildContext context, int iyilesmeCount, int totalCount) {
    final bool majorityImproved = iyilesmeCount >= totalCount / 2;
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
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: kPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Karşılaştırma Sonuçları",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                Text(
                  patient.tamAd,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: majorityImproved
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$iyilesmeCount/$totalCount İyileşti",
              style: TextStyle(
                color: majorityImproved
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _dateInfoBox("ÖNCE", startDate.tarih, startDate.baslik)),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward,
                color: kPrimary, size: 16),
          ),
          Expanded(
            child: _dateInfoBox("SONRA", endDate.tarih, endDate.baslik,
                isBlue: true),
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
            color: isBlue ? kPrimary : kTextGrey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tarih,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: kTextDark,
          ),
        ),
        Text(
          baslik,
          style: const TextStyle(color: kTextGrey, fontSize: 11),
          textAlign: isBlue ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildMeasureCard(ComparisonResult result) {
    final bool isNeutral = result.fark == 0;
    final Color statusColor = isNeutral
        ? kTextGrey
        : (result.iyilesme
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626));
    final Color statusBg = isNeutral
        ? kInputFill
        : (result.iyilesme
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.testAdi,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${result.fark > 0 ? '+' : ''}${result.fark.toStringAsFixed(1)} ${result.birim}",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _scoreChip("ÖNCE", result.baselineDeger, result.birim,
                  kTextGrey, kInputFill),
              const SizedBox(width: 8),
              _scoreChip("SONRA", result.guncelDeger, result.birim,
                  statusColor, statusBg),
            ],
          ),
          const SizedBox(height: 14),
          _buildBar(
            label: "Başlangıç",
            value: result.baselineDeger,
            maxValue: result.maxDeger,
            color: kTextHint,
          ),
          const SizedBox(height: 8),
          _buildBar(
            label: "Güncel",
            value: result.guncelDeger,
            maxValue: result.maxDeger,
            color: isNeutral
                ? kPrimary
                : (result.iyilesme
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, double score, String birim, Color color,
      Color bgColor) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: kTextGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)} $birim",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
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
            style: const TextStyle(fontSize: 11, color: kTextGrey),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / maxValue).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
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
            color: kTextGrey,
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextGrey,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text(
                "PDF Raporu",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text(
                "Paylaş",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}