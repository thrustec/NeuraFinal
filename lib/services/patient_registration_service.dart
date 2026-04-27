import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_form_data.dart';
import 'supabase_service.dart';

class PatientService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> registerPatient(
    PatientFormData formData, {
    required int klinisyenId,
  }) async {
    Map<String, dynamic>? createdUser;
    Map<String, dynamic>? createdPatient;
    Map<String, dynamic>? createdEmpatica;
    Map<String, dynamic>? createdEvaluation;

    try {
      // 1) kullanicilar
      createdUser = await _supabase.schema('neura').from('kullanicilar').insert({
        'rolId': formData.rolId,
        'ad': formData.name.trim(),
        'soyad': formData.surname.trim(),
        'eposta': formData.patientEmail.trim(),
        'sifreHash': formData.sifreHash.trim().isEmpty
            ? 'temp_hash_123'
            : formData.sifreHash.trim(),
        'aktifMi': formData.aktifMi,
      }).select().single();

      final int kullaniciId = createdUser['kullaniciId'] as int;

      // 2) hastalar
      createdPatient = await _supabase.schema('neura').from('hastalar').insert({
        'kullaniciId': kullaniciId,
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
      }).select().single();

      final int hastaId = createdPatient['hastaId'] as int;

      // 3) empatica (opsiyonel)
      if (formData.empeticaId.trim().isNotEmpty) {
        createdEmpatica = await _supabase.schema('neura').from('empatica').insert({
          'hastaId': hastaId,
          'cihazKimlik': formData.empeticaId.trim(),
        }).select().single();

        final int empaticaId = createdEmpatica['empaticaId'] as int;

        await _supabase.schema('neura').from('hastalar').update({
          'empaticaId': empaticaId,
        }).eq('hastaId', hastaId);
      }

      // 4) degerlendirmeler
      createdEvaluation =
          await _supabase.schema('neura').from('degerlendirmeler').insert({
        'hastaId': hastaId,
        'klinisyenId': klinisyenId,
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
      }).select().single();

      return {
        'user': createdUser,
        'patient': createdPatient,
        'empatica': createdEmpatica,
        'evaluation': createdEvaluation,
      };
    } catch (e) {
      try {
        if (createdPatient != null) {
          await _supabase
              .schema('neura')
              .from('degerlendirmeler')
              .delete()
              .eq(
            'hastaId',
            createdPatient['hastaId'] as int,
          );

          await _supabase
              .schema('neura')
              .from('empatica')
              .delete()
              .eq(
            'hastaId',
            createdPatient['hastaId'] as int,
          );

          await _supabase
              .schema('neura')
              .from('hastalar')
              .delete()
              .eq(
            'hastaId',
            createdPatient['hastaId'] as int,
          );
        }

        if (createdUser != null) {
          await _supabase
              .schema('neura')
              .from('kullanicilar')
              .delete()
              .eq(
            'kullaniciId',
            createdUser['kullaniciId'] as int,
          );
        }
      } catch (_) {}

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

      final date = DateTime(year, month, day);
      return date.toIso8601String();
    } catch (_) {
      return null;
    }
  }
}