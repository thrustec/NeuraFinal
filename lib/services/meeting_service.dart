import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MeetingService {
  final SupabaseClient _supabase = SupabaseService.client;

  // ============================================================================
  // Zoom toplantısı oluştur
  // join_url: hasta için
  // id: daha sonra klinisyenin güncel start_url alması için
  // ============================================================================
  Future<Map<String, dynamic>?> createZoomMeeting({
    required String topic,
    required DateTime startTime,
    int duration = 40,
  }) async {
    try {
      print('ZOOM FUNCTION ÇAĞRILIYOR...');

      final response = await _supabase.functions.invoke(
        'create-zoom-meeting',
        body: {
          'topic': topic,
          'start_time': startTime.toIso8601String(),
          'duration': duration,
        },
      );

      final data = response.data;
      print('ZOOM RESPONSE DATA: $data');

      if (data is Map &&
          data['join_url'] != null &&
          data['id'] != null) {
        return {
          'join_url': data['join_url'].toString(),
          'id': data['id'].toString(),
        };
      }

      if (data is Map && data['error'] != null) {
        print('ZOOM FUNCTION ERROR: ${data['error']}');
        print('ZOOM FUNCTION DETAIL: ${data['detail']}');
      }

      return null;
    } catch (e) {
      print('Zoom meeting oluşturulamadı: $e');
      return null;
    }
  }

  // ============================================================================
  // Klinisyen için güncel host start_url al
  // ============================================================================
  Future<String?> getZoomStartUrl(String zoomMeetingId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-zoom-start-url',
        body: {
          'meeting_id': zoomMeetingId,
        },
      );

      final data = response.data;
      print('GET START URL RESPONSE: $data');

      if (data is Map && data['start_url'] != null) {
        return data['start_url'].toString();
      }

      if (data is Map && data['error'] != null) {
        print('START URL ERROR: ${data['error']}');
        print('START URL DETAIL: ${data['detail']}');
      }

      return null;
    } catch (e) {
      print('Zoom start url alınamadı: $e');
      return null;
    }
  }

  // ============================================================================
  // Toplantı oluştur
  // ============================================================================
  Future<Map<String, dynamic>> createMeeting({
    required int hastaId,
    required int klinisyenId,
    required String baslik,
    required DateTime baslangicZamani,
    required DateTime bitisZamani,
    String? zoomlink,
    String? notlar,
  }) async {
    final gercekBitisZamani =
    baslangicZamani.add(const Duration(minutes: 40));

    String? generatedZoomLink;
    String? zoomMeetingId;

    if (zoomlink?.trim().isNotEmpty == true) {
      generatedZoomLink = zoomlink!.trim();
    } else {
      final zoomData = await createZoomMeeting(
        topic: baslik,
        startTime: baslangicZamani,
        duration: 40,
      );

      generatedZoomLink = zoomData?['join_url']?.toString();
      zoomMeetingId = zoomData?['id']?.toString();
    }

    print('DATABASEE YAZILACAK ZOOM JOIN LINK: $generatedZoomLink');
    print('DATABASEE YAZILACAK ZOOM MEETING ID: $zoomMeetingId');

    final response = await _supabase
        .schema('neura')
        .from('toplantilar')
        .insert({
      'hastaId': hastaId,
      'klinisyenId': klinisyenId,
      'baslik': baslik,
      'baslangicZamani': baslangicZamani.toIso8601String(),
      'bitisZamani': gercekBitisZamani.toIso8601String(),
      'zoomlink': generatedZoomLink,
      'zoomMeetingId': zoomMeetingId,
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
    final gercekYeniBitisZamani =
    yeniBaslangicZamani.add(const Duration(minutes: 40));

    final zoomData = await createZoomMeeting(
      topic: 'Ertelenmiş Telerehabilitasyon Randevusu',
      startTime: yeniBaslangicZamani,
      duration: 40,
    );

    final newZoomLink = zoomData?['join_url']?.toString();
    final newZoomMeetingId = zoomData?['id']?.toString();

    await _supabase
        .schema('neura')
        .from('toplantilar')
        .update({
      'baslangicZamani': yeniBaslangicZamani.toIso8601String(),
      'bitisZamani': gercekYeniBitisZamani.toIso8601String(),
      'zoomlink': newZoomLink,
      'zoomMeetingId': newZoomMeetingId,
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
    final meetingsResponse = await _supabase
        .schema('neura')
        .from('toplantilar')
        .select('*')
        .eq('hastaId', hastaId)
        .order('baslangicZamani', ascending: true);

    final meetings = List<Map<String, dynamic>>.from(meetingsResponse);

    final patientResponse = await _supabase
        .schema('neura')
        .from('hastalar')
        .select('hastaId, kullaniciId, kullanicilar(ad, soyad, eposta)')
        .eq('hastaId', hastaId)
        .maybeSingle();

    final klinisyenIds = meetings
        .map((m) => m['klinisyenId'])
        .whereType<int>()
        .toSet()
        .toList();

    final Map<int, Map<String, dynamic>> clinicianMap = {};

    if (klinisyenIds.isNotEmpty) {
      final cliniciansResponse = await _supabase
          .schema('neura')
          .from('klinisyenler')
          .select(
        'klinisyenId, kullaniciId, unvan, kullanicilar(ad, soyad, eposta)',
      )
          .inFilter('klinisyenId', klinisyenIds);

      for (final c in List<Map<String, dynamic>>.from(cliniciansResponse)) {
        final id = c['klinisyenId'];
        if (id is int) {
          clinicianMap[id] = c;
        }
      }
    }

    return meetings.map((meeting) {
      final klinisyenId = meeting['klinisyenId'];

      return {
        ...meeting,
        'hastaBilgisi': patientResponse == null
            ? null
            : Map<String, dynamic>.from(patientResponse),
        'klinisyenBilgisi': klinisyenId is int
            ? clinicianMap[klinisyenId]
            : null,
      };
    }).toList();
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

  Future<Map<String, dynamic>?> getAssignedClinicianForPatient(
      int hastaId,
      ) async {
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