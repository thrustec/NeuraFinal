import 'package:flutter/material.dart';

import '../models/evaluation_model.dart';
import '../services/evaluation_service.dart';

class EvaluationProvider extends ChangeNotifier {
  EvaluationProvider({required int doctorId}) : _currentDoctorId = doctorId;

  final EvaluationService _service = EvaluationService();

  int _currentDoctorId;
  int get currentDoctorId => _currentDoctorId;

  void setDoctorId(int doctorId) {
    if (_currentDoctorId == doctorId) return;
    _currentDoctorId = doctorId;
    clearSelection();
    clearFilter();
    notifyListeners();
  }

  LoadStatus listStatus = LoadStatus.idle;
  LoadStatus formStatus = LoadStatus.idle;

  bool get isListLoading => listStatus == LoadStatus.loading;
  bool get isFormLoading => formStatus == LoadStatus.loading;

  String? listError;
  String? formError;

  int? filterHastaId;
  Evaluation? selected;

  final Map<int, PatientProfile> _profiles = {};
  final List<Evaluation> _store = [];

  List<Patient> get doctorPatients => const [];

  PatientProfile? getProfile(int patientId) => _profiles[patientId];

  List<Patient> searchDoctorPatients(String query) => const [];

  Future<Patient?> addPatientWithProfile({
    required String ad,
    required String soyad,
    String? eposta,
    required String diagnosis,
    required String height,
    required String weight,
    required String birthDate,
    required String education,
    required String maritalStatus,
    required String occupation,
    required String location,
    required String medicalHistory,
    required String caregiver,
    required String dominantSide,
    required String complaintDate,
    int? smokingId,
  }) async {
    formError =
    'Yeni hasta ekleme henüz Supabase ile bağlanmadı. Lütfen mevcut bir hasta seçin.';
    formStatus = LoadStatus.error;
    notifyListeners();
    return null;
  }

  List<Evaluation> get evaluations {
    final own = [..._store];

    if (filterHastaId != null) {
      return own.where((e) => e.hastaId == filterHastaId).toList()
        ..sort((a, b) {
          final bDate =
              b.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
          final aDate =
              a.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    }

    own.sort((a, b) {
      final bDate =
          b.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
      final aDate =
          a.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return own;
  }

  Future<void> loadEvaluations() async {
    try {
      listStatus = LoadStatus.loading;
      listError = null;
      notifyListeners();

      final items = filterHastaId != null
          ? await _service.getByPatient(filterHastaId!)
          : await _service.getAll(klinisyenId: _currentDoctorId);

      _store
        ..clear()
        ..addAll(items);

      listStatus = LoadStatus.success;
      notifyListeners();
    } catch (e) {
      listStatus = LoadStatus.error;
      listError = 'Değerlendirmeler yüklenemedi: $e';
      notifyListeners();
    }
  }

  Future<void> loadEvaluationsByPatient(int hastaId) async {
    filterHastaId = hastaId;
    await loadEvaluations();
  }

  Future<void> refresh() async {
    await loadEvaluations();
  }

  void select(Evaluation evaluation) {
    selected = evaluation;
    notifyListeners();
  }

  void clearSelection() {
    selected = null;
    notifyListeners();
  }

  void clearFilter() {
    filterHastaId = null;
    notifyListeners();
  }

  void setFilterHastaId(int? value) {
    filterHastaId = value;
    notifyListeners();
  }

  void resetFormStatus() {
    formStatus = LoadStatus.idle;
    formError = null;
    notifyListeners();
  }

  Future<bool> create(Evaluation evaluation) async {
    try {
      formStatus = LoadStatus.loading;
      formError = null;
      notifyListeners();

      final created = await _service.create(evaluation);
      if (filterHastaId == null || filterHastaId == created.hastaId) {
        _store.removeWhere((e) => e.id == created.id);
        _store.insert(0, created);
      }

      selected = created;

      _store.sort((a, b) {
        final bDate =
            b.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
        final aDate =
            a.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      formStatus = LoadStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      formStatus = LoadStatus.error;
      formError = 'Kayıt başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, Evaluation updated) async {
    try {
      formStatus = LoadStatus.loading;
      formError = null;
      notifyListeners();

      final saved = await _service.update(id, updated);

      final index = _store.indexWhere((e) => e.id == id);
      if (index != -1) {
        _store[index] = saved;
      } else {
        _store.insert(0, saved);
      }

      if (selected?.id == id) {
        selected = saved;
      }
      _store.sort((a, b) {
        final bDate =
            b.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
        final aDate =
            a.olusturmaTarihi ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      formStatus = LoadStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      formStatus = LoadStatus.error;
      formError = 'Güncelleme başarısız: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      listError = null;

      await _service.delete(id);
      _store.removeWhere((e) => e.id == id);

      if (selected?.id == id) {
        selected = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      listError = 'Silme başarısız: $e';
      notifyListeners();
      return false;
    }
  }
}