import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comparison_report.dart';
import 'supabase_service.dart';

class ReportService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<int?> getClinicianIdByUserId(int kullaniciId) async {
    final data = await _client
        .schema('neura')
        .from('klinisyenler')
        .select('klinisyenId')
        .eq('kullaniciId', kullaniciId)
        .maybeSingle();

    if (data == null) return null;

    return int.tryParse(data['klinisyenId'].toString());
  }

  static Future<void> addReport(ComparisonReport report) async {
    await _client.schema('neura').from('karsilastirmaRaporlari').insert({
      'klinisyenId': report.klinisyenId,
      'hastaId': report.hastaId,
      'hastaAdi': report.hastaAdi,
      'baslangicTarihi': report.baslangicTarihi,
      'bitisTarihi': report.bitisTarihi,
      'raporBasligi': report.raporBasligi,
      'durum': report.durum,
      'filePath': report.filePath,
    });
  }

  static Future<List<ComparisonReport>> getReportsByClinician(
      int klinisyenId,
      ) async {
    final data = await _client
        .schema('neura')
        .from('karsilastirmaRaporlari')
        .select()
        .eq('klinisyenId', klinisyenId)
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(data)
        .map((e) => ComparisonReport.fromJson(e))
        .toList();
  }
}