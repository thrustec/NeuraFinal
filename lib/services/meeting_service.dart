import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MeetingService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> createMeeting({
    required int hastaId,
    required int klinisyenId,
    required String baslik,
    required DateTime baslangicZamani,
    required DateTime bitisZamani,
    String? notlar,
  }) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .insert({
      'hastaId': hastaId,
      'klinisyenId': klinisyenId,
      'baslik': baslik,
      'baslangicZamani': baslangicZamani.toIso8601String(),
      'bitisZamani': bitisZamani.toIso8601String(),
      'notlar': (notlar == null || notlar.trim().isEmpty)
          ? null
          : notlar.trim(),
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createMeetingRequest({
    int? toplantiId,
    required int hastaId,
    required int klinisyenId,
    required String durum,
    required String talep,
  }) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .insert({
      'toplantiId': toplantiId,
      'hastaId': hastaId,
      'klinisyenId': klinisyenId,
      'durum': durum,
      'talep': talep,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateMeetingRequestStatus({
    required int toplantiIstegiId,
    required String durum,
    int? toplantiId,
  }) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .update({
      'durum': durum,
      'toplantiId': toplantiId,
    })
        .eq('toplantiIstegiId', toplantiIstegiId)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await _supabase
        .schema('neura')
        .from('hastalar')
        .select('hastaId, kullaniciId')
        .order('hastaId', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getClinicians() async {
    final response = await _supabase
        .schema('neura')
        .from('kullanicilar')
        .select('kullaniciId, ad, soyad, eposta, rolId')
        .eq('rolId', 1)
        .order('kullaniciId', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetings() async {
    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .select()
        .order('baslangicZamani', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetingsByPatient(int hastaId) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .select()
        .eq('hastaId', hastaId)
        .order('baslangicZamani', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetingRequests() async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .select()
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getEmailLogs() async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiEpostaKayitlari')
        .select()
        .order('epostaKayitId', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}