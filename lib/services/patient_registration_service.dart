import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_form_data.dart';
import 'supabase_service.dart';

class PatientService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> registerPatient(
      PatientFormData formData, {
        required int klinisyenId, // klinisyenler.klinisyenId → hastalar.klinisyenId
        required int kullaniciId, // kullanicilar.kullaniciId → degerlendirmeler.klinisyenId
      }) async {
    Map<String, dynamic>? existingUser;
    Map<String, dynamic>? updatedPatient;
    Map<String, dynamic>? createdEmpatica;
    Map<String, dynamic>? createdEvaluation;

    try {
      existingUser = await _supabase
          .schema('neura')
          .from('kullanicilar')
          .select()
          .eq('eposta', formData.patientEmail.trim())
          .single();

      final int hastaKullaniciId = existingUser['kullaniciId'] as int;

      await _supabase.schema('neura').from('kullanicilar').update({
        'ad': formData.name.trim(),
        'soyad': formData.surname.trim(),
        'aktifMi': formData.aktifMi,
      }).eq('kullaniciId', hastaKullaniciId);

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
              .update({
            'cihazKimlik': formData.empeticaId.trim(),
          })
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

        await _supabase.schema('neura').from('hastalar').update({
          'empaticaId': empaticaId,
        }).eq('hastaId', hastaId);
      }

      createdEvaluation = await _supabase
          .schema('neura')
          .from('degerlendirmeler')
          .insert({
        'hastaId': hastaId,
        'klinisyenId': kullaniciId,
        'sigaraDurumId': formData.smokingStatusId,
        'hikaye': formData.complaintHistory.trim().isEmpty
            ? null
            : formData.complaintHistory.trim(),
        'baslangicTarihi': _convertDateToIso(formData.complaintDate),
        'hastalikId': formData.diagnosisId,
        'kullanilanIlaclar': formData.medications.trim().isEmpty
            ? null
            : formData.medications.trim(),
        'sporAliskanligi': formData.exerciseStatus.trim().isEmpty
            ? null
            : formData.exerciseStatus.trim(),
        'yardimciCihaz': formData.assistiveDeviceStatus.trim().isEmpty
            ? null
            : formData.assistiveDeviceStatus.trim(),
        'bakiciKisi': formData.caregiverStatus.trim().isEmpty
            ? null
            : formData.caregiverStatus.trim(),
        'klinisyenNotlari': formData.clinicianNotes.trim().isEmpty
            ? null
            : formData.clinicianNotes.trim(),
      })
          .select()
          .single();

      return {
        'user': existingUser,
        'patient': updatedPatient,
        'empatica': createdEmpatica,
        'evaluation': createdEvaluation,
      };
    } catch (e) {
      rethrow;
    }
  }

  String? _convertDateToIso(String rawDate) {
    if (rawDate.trim().isEmpty) return null;

    try {
      final parts = rawDate.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day).toIso8601String();
    } catch (_) {
      return null;
    }
  }
}