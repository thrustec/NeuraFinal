import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comparison_report.dart';
import '../providers/auth_provider.dart';
import '../services/report_service.dart';

const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  List<ComparisonReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = int.tryParse(
        context.read<AuthProvider>().user?.id ?? '',
      );

      if (userId == null) {
        throw Exception("Kullanıcı bilgisi bulunamadı.");
      }

      final klinisyenId = await ReportService.getClinicianIdByUserId(userId);

      if (klinisyenId == null) {
        throw Exception("Klinisyen bilgisi bulunamadı.");
      }

      final reports = await ReportService.getReportsByClinician(klinisyenId);

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport(
      BuildContext context,
      ComparisonReport report,
      ) async {
    if (report.filePath == null || report.filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu rapor için PDF dosyası bulunamadı.")),
      );
      return;
    }

    final sourceFile = File(report.filePath!);

    if (!await sourceFile.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF dosyası cihazda bulunamadı.")),
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

    final targetPath = '${targetDirectory.path}/${safeTitle}_${report.id}.pdf';

    final targetFile = await sourceFile.copy(targetPath);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF indirildi: ${targetFile.path}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Raporlar yüklenemedi:\n$_error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text(
          "Henüz oluşturulmuş rapor yok.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(context, report);
        },
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
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(
              Icons.refresh,
              color: kPrimary,
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.durum,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
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
        ],
      ),
    );
  }
}