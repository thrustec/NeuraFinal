// lib/services/agenda_service.dart

import 'package:flutter/foundation.dart';
import '../models/agenda_item.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';

class AgendaService {
  final ApiClient _client;

  AgendaService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<AgendaItem>> getWeeklyAgenda({
    required int hastaId,
    required DateTime haftaBaslangic,
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
      return data
          .map((item) => _parseAgendaItem(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AgendaService.getWeeklyAgenda error: $e');
      rethrow;
    }
  }

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

  Future<List<Map<String, dynamic>>> getPatientsForDropdown() async {
    final path =
        '${ApiConstants.hastalar}?select=hastaId,kullanicilar!inner(ad,soyad)';

    final data = await _client.get(path);

    return data.map<Map<String, dynamic>>((p) {
      final user = p['kullanicilar'];

      return {
        'id': p['hastaId'].toString(),
        'name': user != null
            ? '${user['ad'] ?? ''} ${user['soyad'] ?? ''}'.trim()
            : 'Hasta ${p['hastaId']}',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getClinicianMeetings({
    required int klinisyenId,
  }) async {
    final path = '${ApiConstants.toplantilar}'
        '?select=toplantiId,hastaId,klinisyenId,baslik,baslangicZamani,bitisZamani,notlar,'
        'hastalar!inner(kullanicilar!inner(ad,soyad)),'
        'toplantiIstekleri(durum,talep)'
        '&klinisyenId=eq.$klinisyenId'
        '&order=baslangicZamani.asc';

    final data = await _client.get(path);

    return data.map<Map<String, dynamic>>((t) {
      final hasta = t['hastalar']?['kullanicilar'];

      final istekList = t['toplantiIstekleri'];
      final istek = (istekList is List && istekList.isNotEmpty)
          ? istekList.first as Map<String, dynamic>
          : <String, dynamic>{};

      final dt = t['baslangicZamani'] != null
          ? DateTime.parse(t['baslangicZamani'])
          : null;

      final durum = istek['durum'] ?? 'Planlandı';

      return {
        'id': t['toplantiId'].toString(),
        'hastaId': t['hastaId'],
        'patient': hasta != null
            ? '${hasta['ad'] ?? ''} ${hasta['soyad'] ?? ''}'.trim()
            : 'Hasta',
        'diagnosis': t['baslik'] ?? 'Randevu',
        'date': dt != null
            ? '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
            : '-',
        'time': dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : '-',
        'status': durum,
        'approved': durum == 'Onaylandı'
            ? true
            : durum == 'İptal'
            ? false
            : null,
        'request': istek['talep'] ?? t['notlar'] ?? 'Randevu',
      };
    }).toList();
  }

  Future<void> createClinicianMeeting({
    required int hastaId,
    required int klinisyenId,
    required DateTime baslangicZamani,
    String baslik = 'Randevu',
    String? notlar,
  }) async {
    final bitisZamani = baslangicZamani.add(const Duration(hours: 1));

    final created = await _client.post(
      ApiConstants.toplantilar,
      {
        'hastaId': hastaId,
        'klinisyenId': klinisyenId,
        'baslik': baslik,
        'baslangicZamani': baslangicZamani.toIso8601String(),
        'bitisZamani': bitisZamani.toIso8601String(),
        'notlar': notlar,
      },
    );

    final List createdList = created as List;
    final toplantiId = createdList.first['toplantiId'];

    await _client.post(
      ApiConstants.toplantiIstekleri,
      {
        'toplantiId': toplantiId,
        'hastaId': hastaId,
        'klinisyenId': klinisyenId,
        'durum': 'Planlandı',
        'talep': notlar ?? 'Randevu',
      },
    );
  }

  Future<void> updateMeetingStatus({
    required int toplantiId,
    required String durum,
  }) async {
    await _client.patch(
      '${ApiConstants.toplantiIstekleri}?toplantiId=eq.$toplantiId',
      {'durum': durum},
    );
  }

  AgendaItem _parseAgendaItem(Map<String, dynamic> map) {
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
      'durum': istek['durum'] ?? 'Planlandı',
      'kategori': istek['talep'] ?? 'Randevu',
      'tamamlandiMi': false,
    });
  }
}