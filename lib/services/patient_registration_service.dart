import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_form_data.dart';
import 'supabase_service.dart';

class PatientService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> registerPatient(
    PatientFormData formData, {
    required int klinisyenId, // klinisyenler.klinisyenId → hastalar.klinisyenId
  }) async {
    Map<String, dynamic>? existingUser;
    Map<String, dynamic>? updatedPatient;
    Map<String, dynamic>? createdEmpatica;

    try {
      existingUser = await _supabase
          .schema('neura')
          .from('kullanicilar')
          .select()
          .eq('eposta', formData.patientEmail.trim())
          .single();

      final int hastaKullaniciId = existingUser['kullaniciId'] as int;

      await _supabase
          .schema('neura')
          .from('kullanicilar')
          .update({
            'ad': formData.name.trim(),
            'soyad': formData.surname.trim(),
            'aktifMi': formData.aktifMi,
          })
          .eq('kullaniciId', hastaKullaniciId);

      final existingPatient = await _supabase
          .schema('neura')
          .from('hastalar')
          .select()
          .eq('kullaniciId', hastaKullaniciId)
          .single();

      final int hastaId = existingPatient['hastaId'] as int;

      updatedPatient = await _supabase
          .schema('neura')
          .from('hastalar')
          .update({
            'klinisyenId': klinisyenId,
            'cinsiyetId': formData.genderId,
            'medeniDurumId': formData.maritalStatusId,
            'egitimDurumId': formData.educationId,
            'meslekId': formData.occupationId,
            'sigaraDurumId': formData.smokingStatusId,
            'baskinId': formData.dominantSideId,
            'dogumTarihi': _convertDateToIso(formData.birthDate),
            'telefonNo': formData.phone.trim(),
            'adres': formData.city.trim(),
            'acilKisiAdi': formData.emergencyContactName.trim(),
            'acilKisiTelefonu': formData.emergencyPhone.trim(),
            'boy': formData.heightValue,
            'kilo': formData.weightValue,
            'hastalikId': formData.diagnosisId,
            'baslangicTarihi': _convertDateToIso(formData.complaintDate),
            'notlar': formData.complaintHistory.trim().isEmpty
                ? null
                : formData.complaintHistory.trim(),
          })
          .eq('hastaId', hastaId)
          .select()
          .single();

      if (formData.empeticaId.trim().isNotEmpty) {
        final existingEmpatica = await _supabase
            .schema('neura')
            .from('empatica')
            .select()
            .eq('hastaId', hastaId)
            .maybeSingle();

        if (existingEmpatica != null) {
          createdEmpatica = await _supabase
              .schema('neura')
              .from('empatica')
              .update({'cihazKimlik': formData.empeticaId.trim()})
              .eq('hastaId', hastaId)
              .select()
              .single();
        } else {
          createdEmpatica = await _supabase
              .schema('neura')
              .from('empatica')
              .insert({
                'hastaId': hastaId,
                'cihazKimlik': formData.empeticaId.trim(),
              })
              .select()
              .single();
        }

        final int empaticaId = createdEmpatica['empaticaId'] as int;

        await _supabase
            .schema('neura')
            .from('hastalar')
            .update({'empaticaId': empaticaId})
            .eq('hastaId', hastaId);
      }

      return {
        'user': existingUser,
        'patient': updatedPatient,
        'empatica': createdEmpatica,
      };
    } catch (e) {
      rethrow;
    }
  }

  String? _convertDateToIso(String rawDate) {
    final value = rawDate.trim();
    if (value.isEmpty) return null;

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso.toIso8601String();

    final normalized = value.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalized.split('/');
    if (parts.length != 3) return null;

    try {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);
      final third = int.parse(parts[2]);

      if (parts[0].length == 4) {
        final date = DateTime(first, second, third);
        if (date.year != first || date.month != second || date.day != third) {
          return null;
        }
        return date.toIso8601String();
      }

      final day = first;
      final month = second;
      final year = third;
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date.toIso8601String();
    } catch (_) {
      return null;
    }
  }
}
