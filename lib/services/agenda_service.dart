// lib/services/agenda_service.dart
//
// Supabase REST API üzerinden toplantilar ve toplantiIstekleri verilerini çeker.
// AgendaItem modeline uyarlandı.

import 'package:flutter/foundation.dart';
import '../models/agenda_item.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';

class AgendaService {
  final ApiClient _client;

  AgendaService({ApiClient? client}) : _client = client ?? ApiClient();

  // ---------------------------------------------------------------------------
  // Bir hastanın belirli haftasındaki tüm toplantılarını getir
  //
  // Supabase REST:
  //   GET /toplantilar
  //     ?select=toplantiId,hastaId,klinisyenId,baslik,baslangicZamani,
  //             bitisZamani,notlar,
  //             toplantiIstekleri(durum,talep)
  //     &hastaId=eq.:hastaId
  //     &baslangicZamani=gte.:haftaBaslangic
  //     &baslangicZamani=lt.:haftaBitis
  //     &order=baslangicZamani.asc
  // ---------------------------------------------------------------------------
  Future<List<AgendaItem>> getWeeklyAgenda({
    required int hastaId,
    required DateTime haftaBaslangic, // Pazartesi 00:00
  }) async {
    final haftaBitis = haftaBaslangic.add(const Duration(days: 7));

    final String baslangicStr = haftaBaslangic.toUtc().toIso8601String();
    final String bitisStr = haftaBitis.toUtc().toIso8601String();

    try {
      final path = '${ApiConstants.toplantilar}'
          '?select=toplantiId,hastaId,klinisyenId,baslik,'
          'baslangicZamani,bitisZamani,notlar,'
          'toplantiIstekleri(durum,talep)'
          '&hastaId=eq.$hastaId'
          '&baslangicZamani=gte.$baslangicStr'
          '&baslangicZamani=lt.$bitisStr'
          '&order=baslangicZamani.asc';

      final data = await _client.get(path);
      return data.map((item) => _parseAgendaItem(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('AgendaService.getWeeklyAgenda error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Toplantı iptal et
  // PATCH /toplantiIstekleri?toplantiId=eq.:id&hastaId=eq.:hastaId
  // durum = 'İptal'
  // ---------------------------------------------------------------------------
  Future<void> cancelAppointment({
    required int toplantiId,
    required int hastaId,
  }) async {
    try {
      await _client.patch(
        '${ApiConstants.toplantiIstekleri}'
            '?toplantiId=eq.$toplantiId&hastaId=eq.$hastaId',
        {'durum': 'İptal'},
      );
    } catch (e) {
      debugPrint('AgendaService.cancelAppointment error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PARSE — Supabase JSON → AgendaItem
  // ---------------------------------------------------------------------------
  AgendaItem _parseAgendaItem(Map<String, dynamic> map) {
    // toplantiIstekleri embedded JOIN (liste olarak gelir, ilk kayıt alınır)
    final istekList = map['toplantiIstekleri'];
    final istek = (istekList is List && istekList.isNotEmpty)
        ? istekList.first as Map<String, dynamic>
        : <String, dynamic>{};

    return AgendaItem.fromMap({
      'toplantiId': map['toplantiId'],
      'hastaId': map['hastaId'],
      'baslangicZamani': map['baslangicZamani'],
      'baslik': map['baslik'],
      'notlar': map['notlar'],
      // toplantiIstekleri.durum → yoksa varsayılan
      'durum': istek['durum'] ?? 'Planlandı',
      // toplantiIstekleri.talep → kategori olarak kullanıyoruz
      'kategori': istek['talep'] ?? 'Randevu',
      'tamamlandiMi': false,
    });
  }
}