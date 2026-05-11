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
    String? zoomlink,
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
      'zoomlink': zoomlink?.trim().isEmpty == true ? null : zoomlink?.trim(),
      'notlar': notlar?.trim().isEmpty == true ? null : notlar?.trim(),
      'baslatildimi': false,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createMeetingRequest({
    int? toplantiId,
    required int hastaId,
    required int klinisyenId,
    String durum = 'Beklemede',
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
      'talep': talep.trim(),
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> approveMeetingRequest({
    required int toplantiIstegiId,
    required int hastaId,
    required int klinisyenId,
    required String baslik,
    required DateTime baslangicZamani,
    required DateTime bitisZamani,
    String? zoomlink,
    String? notlar,
  }) async {
    final createdMeeting = await createMeeting(
      hastaId: hastaId,
      klinisyenId: klinisyenId,
      baslik: baslik,
      baslangicZamani: baslangicZamani,
      bitisZamani: bitisZamani,
      zoomlink: zoomlink,
      notlar: notlar,
    );

    final int toplantiId = createdMeeting['toplantiId'] as int;

    await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .update({
      'durum': 'Onaylandı',
      'toplantiId': toplantiId,
    })
        .eq('toplantiIstegiId', toplantiIstegiId);

    return createdMeeting;
  }

  Future<void> rejectMeetingRequest({
    required int toplantiIstegiId,
  }) async {
    await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .update({
      'durum': 'Reddedildi',
      'toplantiId': null,
    })
        .eq('toplantiIstegiId', toplantiIstegiId);
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

  Future<void> startMeeting(int toplantiId) async {
    await _supabase
        .schema('neura')
        .from('toplantilar')
        .update({
      'baslatildimi': true,
      'guncellemeTarihi': DateTime.now().toIso8601String(),
    })
        .eq('toplantiId', toplantiId);
  }

  Future<void> cancelMeeting(int toplantiId) async {
    await _supabase
        .schema('neura')
        .from('toplantilar')
        .update({
      'durum': 'İptal Edildi',
      'baslatildimi': false,
      'guncellemeTarihi': DateTime.now().toIso8601String(),
    })
        .eq('toplantiId', toplantiId);
  }

  Future<void> postponeMeeting({
    required int toplantiId,
    required DateTime yeniBaslangicZamani,
    required DateTime yeniBitisZamani,
  }) async {
    await _supabase
        .schema('neura')
        .from('toplantilar')
        .update({
      'baslangicZamani': yeniBaslangicZamani.toIso8601String(),
      'bitisZamani': yeniBitisZamani.toIso8601String(),
      'baslatildimi': false,
      'durum': 'Ertelendi',
      'guncellemeTarihi': DateTime.now().toIso8601String(),
    })
        .eq('toplantiId', toplantiId);
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await _supabase
        .schema('neura')
        .from('hastalar')
        .select('hastaId, kullaniciId, kullanicilar(ad, soyad, eposta)')
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
        .select(
      '*, hastalar(hastaId, kullanicilar(ad, soyad, eposta)), kullanicilar(ad, soyad, eposta)',
    )
        .order('baslangicZamani', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetingsByClinician(
      int klinisyenId,
      ) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .select('*, hastalar(hastaId, kullanicilar(ad, soyad, eposta))')
        .eq('klinisyenId', klinisyenId)
        .order('baslangicZamani', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetingsByPatient(int hastaId) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .select('*')
        .eq('hastaId', hastaId)
        .order('baslangicZamani', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeetingRequests() async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .select(
      '*, hastalar(hastaId, kullanicilar(ad, soyad, eposta)), kullanicilar(ad, soyad, eposta)',
    )
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPendingRequestsByClinician(
      int klinisyenId,
      ) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .select('*, hastalar(hastaId, kullanicilar(ad, soyad, eposta))')
        .eq('klinisyenId', klinisyenId)
        .eq('durum', 'Beklemede')
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRequestsByPatient(int hastaId) async {
    final response = await _supabase
        .schema('neura')
        .from('toplantiIstekleri')
        .select('*, toplantilar(*)')
        .eq('hastaId', hastaId)
        .order('olusturmaTarihi', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getClinicianByUserId(int kullaniciId) async {
    final response = await _supabase
        .schema('neura')
        .from('klinisyenler')
        .select('*')
        .eq('kullaniciId', kullaniciId)
        .maybeSingle();

    return response == null ? null : Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPatientsByClinician(
      int klinisyenId,
      ) async {
    final response = await _supabase
        .schema('neura')
        .from('hastalar')
        .select('hastaId, klinisyenId, kullanicilar(ad, soyad, eposta)')
        .eq('klinisyenId', klinisyenId)
        .order('hastaId', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getAssignedClinicianForPatient(int hastaId) async {
    final patient = await _supabase
        .schema('neura')
        .from('hastalar')
        .select('hastaId, klinisyenId')
        .eq('hastaId', hastaId)
        .maybeSingle();

    if (patient == null) return null;

    final klinisyenId = patient['klinisyenId'];
    if (klinisyenId == null) return null;

    final clinician = await _supabase
        .schema('neura')
        .from('klinisyenler')
        .select('klinisyenId, kullaniciId, unvan')
        .eq('klinisyenId', klinisyenId)
        .maybeSingle();

    if (clinician == null) return null;

    final user = await _supabase
        .schema('neura')
        .from('kullanicilar')
        .select('kullaniciId, ad, soyad, eposta')
        .eq('kullaniciId', clinician['kullaniciId'])
        .maybeSingle();

    return {
      'klinisyenId': clinician['klinisyenId'],
      'kullaniciId': clinician['kullaniciId'],
      'unvan': clinician['unvan'],
      'kullanicilar': user,
    };
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