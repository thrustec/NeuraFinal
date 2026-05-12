import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class NotificationService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<int?> getHastaKullaniciId(int hastaId) async {
    final data = await _client
        .schema('neura')
        .from('hastalar')
        .select('kullaniciId')
        .eq('hastaId', hastaId)
        .maybeSingle();

    if (data == null) return null;

    return int.tryParse(data['kullaniciId'].toString());
  }

  static Future<void> createNotification({
    required int kullaniciId,
    required String baslik,
    required String mesaj,
    int? degerlendirmeId,
  }) async {
    await _client.schema('neura').from('bildirimler').insert({
      'kullaniciId': kullaniciId,
      'baslik': baslik,
      'mesaj': mesaj,
      'okunduMu': false,
      if (degerlendirmeId != null) 'degerlendirmeId': degerlendirmeId,
    });
  }

  static Future<void> createPatientNotificationByHastaId({
    required int hastaId,
    required String baslik,
    required String mesaj,
  }) async {
    final kullaniciId = await getHastaKullaniciId(hastaId);

    if (kullaniciId == null) {
      throw Exception('Hasta kullaniciId bulunamadı. hastaId: $hastaId');
    }

    await createNotification(
      kullaniciId: kullaniciId,
      baslik: baslik,
      mesaj: mesaj,
    );
  }
  static Future<int?> getKlinisyenKullaniciId(int klinisyenId) async {
    final data = await _client
        .schema('neura')
        .from('klinisyenler')
        .select('kullaniciId')
        .eq('klinisyenId', klinisyenId)
        .maybeSingle();

    if (data == null) return null;

    return int.tryParse(data['kullaniciId'].toString());
  }

  static Future<void> createClinicianNotificationByKlinisyenId({
    required int klinisyenId,
    required String baslik,
    required String mesaj,
  }) async {
    final kullaniciId = await getKlinisyenKullaniciId(klinisyenId);

    if (kullaniciId == null) {
      throw Exception('Klinisyen kullaniciId bulunamadı. klinisyenId: $klinisyenId');
    }

    await createNotification(
      kullaniciId: kullaniciId,
      baslik: baslik,
      mesaj: mesaj,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotificationsByUserId(
      int kullaniciId,
      ) async {
    final data = await _client
        .schema('neura')
        .from('bildirimler')
        .select('bildirimId,kullaniciId,baslik,mesaj,okunduMu,olusturmaTarihi')
        .eq('kullaniciId', kullaniciId)
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<int> getUnreadCount(int kullaniciId) async {
    final data = await _client
        .schema('neura')
        .from('bildirimler')
        .select('bildirimId')
        .eq('kullaniciId', kullaniciId)
        .eq('okunduMu', false);

    return List<Map<String, dynamic>>.from(data).length;
  }

  static Future<void> markAsRead(int bildirimId) async {
    await _client
        .schema('neura')
        .from('bildirimler')
        .update({'okunduMu': true})
        .eq('bildirimId', bildirimId);
  }

  static Future<void> markAllAsRead(int kullaniciId) async {
    await _client
        .schema('neura')
        .from('bildirimler')
        .update({'okunduMu': true})
        .eq('kullaniciId', kullaniciId)
        .eq('okunduMu', false);
  }
}