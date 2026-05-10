import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/report_service.dart';
import '../models/comparison_report.dart';

// NeuraApp Design System — Klinisyen Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _downloadReport(
      BuildContext context,
      ComparisonReport report,
      ) async {
    if (report.filePath == null || report.filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu rapor için PDF dosyası bulunamadı."),
        ),
      );
      return;
    }

    final sourceFile = File(report.filePath!);

    if (!await sourceFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF dosyası cihazda bulunamadı."),
        ),
      );
      return;
    }

    final targetDirectory = Directory('/storage/emulated/0/Download');

    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final safeTitle = report.raporBasligi
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');

    final targetPath =
        '${targetDirectory.path}/${safeTitle}_${report.id}.pdf';

    final targetFile = await sourceFile.copy(targetPath);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PDF indirildi: ${targetFile.path}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ComparisonReport> reports = ReportService.getReports();

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: reports.isEmpty
                ? const Center(
              child: Text(
                "Henüz oluşturulmuş rapor yok.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];

                return _buildReportCard(context, report);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bar_chart,
              color: kPrimary,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              "Karşılaştırma Raporları",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context,
      ComparisonReport report,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.raporBasligi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${report.baslangicTarihi} - ${report.bitisTarihi}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.durum,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadReport(context, report),
            icon: const Icon(
              Icons.download_rounded,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}