import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evaluation_model.dart';
import '../../providers/evaluation_provider.dart';
import '../../models/patient_model.dart' as patient_model;
import '../../services/patient_service.dart';
import '../../services/evaluation_service.dart';
import '../../providers/auth_provider.dart';
import '../patient_step_1_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  final bool isEdit;

  const EvaluationFormScreen({super.key, this.isEdit = false});

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  static const _bg = Color(0xFFF8F9FC);
  static const _surface = Colors.white;
  static const _primary = Color(0xFF0F766E);
  static const _primarySoft = Color(0xFFE7F5F3);
  static const _border = Color(0xFFE2E8F0);
  static const _inputFill = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF1E293B);
  static const _textMid = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);
  static const _successBg = Color(0xFFE9F7EE);
  static const _successText = Color(0xFF0A8C3B);

  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  int? _hastaId;
  int? _sigaraDurumId;
  patient_model.Patient? _selectedDbPatient;
  List<patient_model.Patient> _dbPatients = [];

  final _hastaSearchCtrl = TextEditingController();
  final _patientQueryCtrl = TextEditingController();
  final _newPatientFirstNameCtrl = TextEditingController();
  final _newPatientLastNameCtrl = TextEditingController();
  final _newPatientEmailCtrl = TextEditingController();

  final _birthDateCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _maritalCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _complaintDateCtrl = TextEditingController();
  final _caregiverCtrl = TextEditingController();
  final _medicalHistoryCtrl = TextEditingController();
  String? _dominantSide;

  final _motorExtraCtrl = TextEditingController();
  final _sensoryExtraCtrl = TextEditingController();
  final _emotionalExtraCtrl = TextEditingController();
  final _cognitiveExtraCtrl = TextEditingController();
  final _pulmonaryExtraCtrl = TextEditingController();
  final _otherExtraCtrl = TextEditingController();

  final _diseaseNoteCtrl = TextEditingController();

  final _alzExtraCtrl = TextEditingController();
  final _pdExtraCtrl = TextEditingController();
  final _alsExtraCtrl = TextEditingController();
  final _msExtraCtrl = TextEditingController();
  final _ataxiaExtraCtrl = TextEditingController();

  final _chairStandCtrl = TextEditingController();
  final _timedUpGoCtrl = TextEditingController();
  final _pegRightCtrl = TextEditingController();
  final _pegLeftCtrl = TextEditingController();

  final _ctsibFirmOpenCtrl = TextEditingController();
  final _ctsibFirmClosedCtrl = TextEditingController();
  final _ctsibSoftOpenCtrl = TextEditingController();
  final _ctsibSoftClosedCtrl = TextEditingController();

  final _pstAnteriorPosteriorCtrl = TextEditingController();
  final _pstMedialLateralCtrl = TextEditingController();
  final _pstOverallCtrl = TextEditingController();

  final _trailPartACtrl = TextEditingController();
  final _trailPartBCtrl = TextEditingController();
  final _stroopCtrl = TextEditingController();

  bool _motorOpen = true;
  bool _sensoryOpen = false;
  bool _emotionalOpen = false;
  bool _cognitiveOpen = false;
  bool _pulmonaryOpen = false;
  bool _otherOpen = false;

  bool _alzOpen = true;
  bool _pdOpen = true;
  bool _alsOpen = false;
  bool _msOpen = false;
  bool _ataxiaOpen = false;

  bool _generalTestOpen = true;
  bool _ctsibOpen = true;
  bool _pstOpen = true;
  bool _trailOpen = true;
  bool _stroopOpen = true;

  final Set<String> _motorSymptoms = {};
  final Set<String> _sensorySymptoms = {};
  final Set<String> _emotionalSymptoms = {};
  final Set<String> _cognitiveSymptoms = {};
  final Set<String> _pulmonarySymptoms = {};
  final Set<String> _otherSymptoms = {};

  final Set<String> _alzSymptoms = {};
  final Set<String> _pdSymptoms = {};
  final Set<String> _alsSymptoms = {};
  final Set<String> _msSymptoms = {};
  final Set<String> _ataxiaSymptoms = {};

  final List<_StepItem> _steps = const [
    _StepItem('Demografik', Icons.person_outline),
    _StepItem('Semptomlar', Icons.monitor_heart_outlined),
    _StepItem('Hastalık', Icons.psychology_outlined),
    _StepItem('Fonksiyonel', Icons.bolt_outlined),
  ];

  bool get _isLastStep => _currentStep == _steps.length - 1;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateEditData());
    _loadDbPatients();
  }

  @override
  void dispose() {
    _hastaSearchCtrl.dispose();
    _patientQueryCtrl.dispose();
    _newPatientFirstNameCtrl.dispose();
    _newPatientLastNameCtrl.dispose();
    _newPatientEmailCtrl.dispose();

    _birthDateCtrl.dispose();
    _diagnosisCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _educationCtrl.dispose();
    _maritalCtrl.dispose();
    _occupationCtrl.dispose();
    _locationCtrl.dispose();
    _complaintDateCtrl.dispose();
    _caregiverCtrl.dispose();
    _medicalHistoryCtrl.dispose();

    _motorExtraCtrl.dispose();
    _sensoryExtraCtrl.dispose();
    _emotionalExtraCtrl.dispose();
    _cognitiveExtraCtrl.dispose();
    _pulmonaryExtraCtrl.dispose();
    _otherExtraCtrl.dispose();

    _diseaseNoteCtrl.dispose();

    _alzExtraCtrl.dispose();
    _pdExtraCtrl.dispose();
    _alsExtraCtrl.dispose();
    _msExtraCtrl.dispose();
    _ataxiaExtraCtrl.dispose();

    _chairStandCtrl.dispose();
    _timedUpGoCtrl.dispose();
    _pegRightCtrl.dispose();
    _pegLeftCtrl.dispose();

    _ctsibFirmOpenCtrl.dispose();
    _ctsibFirmClosedCtrl.dispose();
    _ctsibSoftOpenCtrl.dispose();
    _ctsibSoftClosedCtrl.dispose();

    _pstAnteriorPosteriorCtrl.dispose();
    _pstMedialLateralCtrl.dispose();
    _pstOverallCtrl.dispose();

    _trailPartACtrl.dispose();
    _trailPartBCtrl.dispose();
    _stroopCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDbPatients() async {
    try {
      final auth = context.read<AuthProvider>();
      final hastalar = await PatientService.getHastalar(
        klinisyenId: auth.user?.klinisyenId,
      );
      debugPrint('DB hasta sayısı: ${hastalar.length}');
      if (!mounted) return;

      setState(() {
        _dbPatients = hastalar;
      });

      final provider = context.read<EvaluationProvider>();
      final targetHastaId =
          provider.selected?.hastaId ?? provider.filterHastaId ?? _hastaId;

      if (targetHastaId != null) {
        final listPatient = _findDbPatientById(targetHastaId);
        patient_model.Patient? dbPatient = listPatient;
        try {
          dbPatient = await PatientService.getHastaById(targetHastaId);
        } catch (e) {
          debugPrint('Patient detail could not be loaded during preload: $e');
        }
        if (dbPatient == null) return;
        _applySelectedDbPatient(dbPatient);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Hastalar yüklenemedi: $e', isError: true);
    }
  }

  patient_model.Patient? _findDbPatientByName(String fullName) {
    final normalized = fullName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final patient in _dbPatients) {
      if (patient.tamAd.trim().toLowerCase() == normalized) {
        return patient;
      }
    }
    return null;
  }

  patient_model.Patient? _findDbPatientById(int hastaId) {
    for (final patient in _dbPatients) {
      if (patient.hastaId == hastaId) return patient;
    }
    return null;
  }

  patient_model.Patient? _findSelectedPatient() {
    if (_hastaId == null) return null;
    for (final p in _dbPatients) {
      if (p.hastaId == _hastaId) return p;
    }
    return null;
  }

  void _applySelectedDbPatient(patient_model.Patient patient) {
    _selectedDbPatient = patient;
    _hastaId = patient.hastaId;
    _hastaSearchCtrl.text = patient.tamAd;

    if ((patient.hastalikAdi ?? '').trim().isNotEmpty) {
      _diagnosisCtrl.text = patient.hastalikAdi!;
    }
    if (patient.boy != null) {
      _heightCtrl.text = patient.boy!.toString();
    }
    if (patient.kilo != null) {
      _weightCtrl.text = patient.kilo!.toString();
    }
    if ((patient.dogumTarihi ?? '').trim().isNotEmpty) {
      _birthDateCtrl.text = patient.dogumTarihi!;
    }
    if ((patient.egitimDurumAdi ?? '').trim().isNotEmpty) {
      _educationCtrl.text = patient.egitimDurumAdi!;
    }
    if ((patient.medeniDurumAdi ?? '').trim().isNotEmpty) {
      _maritalCtrl.text = patient.medeniDurumAdi!;
    }
    if ((patient.meslekAdi ?? '').trim().isNotEmpty) {
      _occupationCtrl.text = patient.meslekAdi!;
    }
    if ((patient.adres ?? '').trim().isNotEmpty) {
      _locationCtrl.text = patient.adres!;
    }
    if ((patient.baslangicTarihi ?? '').trim().isNotEmpty) {
      _complaintDateCtrl.text = _formatPatientDate(patient.baslangicTarihi!);
    }
    if ((patient.bakiciKisi ?? '').trim().isNotEmpty) {
      _caregiverCtrl.text = patient.bakiciKisi!;
    } else {
      // No degerlendirmeler row yet: derive caregiver presence from emergency contact.
      _caregiverCtrl.text = (patient.acilKisiAdi ?? '').trim().isNotEmpty
          ? 'Var'
          : 'Yok';
    }
    if (patient.sigaraDurumId != null) {
      _sigaraDurumId = patient.sigaraDurumId;
    }
    final dominantSide = _normalizeDominantSide(
      patient.baskinElAdi ?? patient.baskinId?.toString(),
    );
    if (dominantSide != null) {
      _dominantSide = dominantSide;
    }
    if ((patient.notlar ?? '').trim().isNotEmpty) {
      _medicalHistoryCtrl.text = patient.notlar!;
    }
  }

  String _formatPatientDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String? _normalizeDominantSide(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == '1' ||
        normalized == 'right' ||
        normalized == 'sağ' ||
        normalized == 'sag') {
      return 'Right';
    }
    if (normalized == '2' || normalized == 'left' || normalized == 'sol') {
      return 'Left';
    }
    if (normalized == '3' ||
        normalized == 'both' ||
        normalized == 'her ikisi' ||
        normalized == 'her i̇kisi') {
      return 'Both';
    }
    return null;
  }

  String _extractSection(String source, String title) {
    final text = source.trim();
    if (text.isEmpty) return '';

    final header = '$title:\n';
    // Use the FIRST occurrence so any later string that accidentally
    // spells the same header (e.g. inside an accumulated clinician note)
    // cannot redirect the start of the real section.
    final start = text.indexOf(header);
    if (start == -1) return '';

    final contentStart = start + header.length;
    final nextHeaders = [
      '\n\nSemptomlar:\n',
      '\n\nHastalık:\n',
      '\n\nKlinisyen Notları:\n',
      '\n\nFonksiyonel:\n',
      '\n\nKlinik tip:',
    ];

    int? end;
    for (final marker in nextHeaders) {
      final idx = text.indexOf(marker, contentStart);
      if (idx != -1) {
        if (end == null || idx < end) {
          end = idx;
        }
      }
    }

    final result = end == null
        ? text.substring(contentStart)
        : text.substring(contentStart, end);

    return result.trim();
  }

  // Extract only the body of the "Klinisyen Notları" sub-section inside the
  // disease block. The disease block uses headers WITHOUT a trailing colon
  // (e.g. "Parkinson\n...", "Klinisyen Notları\n...") so we cannot reuse
  // _extractSection (which expects "Title:\n"). The body is bounded by any
  // other disease sub-section header on a new paragraph.
  String _extractDiseaseClinicianNote(String diseaseSection) {
    final text = diseaseSection.trim();
    if (text.isEmpty) return '';
    const header = 'Klinisyen Notları\n';
    final start = text.indexOf(header);
    if (start == -1) return '';
    final contentStart = start + header.length;
    const otherHeaders = [
      '\n\nHafif Kognitif Bozukluk / Alzheimer Hastalığı\n',
      '\n\nParkinson\n',
      '\n\nALS\n',
      '\n\nMS\n',
      '\n\nAtaksi\n',
      '\n\nKlinisyen Notları\n',
    ];
    int? end;
    for (final marker in otherHeaders) {
      final idx = text.indexOf(marker, contentStart);
      if (idx != -1 && (end == null || idx < end)) {
        end = idx;
      }
    }
    final body = end == null
        ? text.substring(contentStart)
        : text.substring(contentStart, end);
    return body.trim();
  }

  String _extractInlineValue(String source, String label) {
    if (source.trim().isEmpty) return '';
    final pattern = RegExp(
      '^${RegExp.escape(label)}\\s*:[ \\t]*(.*)\$',
      caseSensitive: false,
    );

    for (final rawLine in source.split('\n')) {
      final match = pattern.firstMatch(rawLine.trimRight());
      if (match != null) {
        return (match.group(1) ?? '').trim();
      }
    }

    return '';
  }

  void _fillFunctionalControllersFromText(String text) {
    _chairStandCtrl.text = _extractInlineValue(
      text,
      '30-sec Chair Stand Test (Reps)',
    );
    _timedUpGoCtrl.text = _extractInlineValue(text, 'Timed Up & Go Test (Sec)');
    _pegRightCtrl.text = _extractInlineValue(
      text,
      '9-Hole Peg – Right Hand (Sec)',
    );
    _pegLeftCtrl.text = _extractInlineValue(
      text,
      '9-Hole Peg – Left Hand (Sec)',
    );
    _ctsibFirmOpenCtrl.text = _extractInlineValue(
      text,
      'Eyes Open – Firm Surface (Sec)',
    );
    _ctsibFirmClosedCtrl.text = _extractInlineValue(
      text,
      'Eyes Closed – Firm Surface (Sec)',
    );
    _ctsibSoftOpenCtrl.text = _extractInlineValue(
      text,
      'Eyes Open – Soft Surface (Sec)',
    );
    _ctsibSoftClosedCtrl.text = _extractInlineValue(
      text,
      'Eyes Closed – Soft Surface (Sec)',
    );
    _pstAnteriorPosteriorCtrl.text = _extractInlineValue(
      text,
      'Anterior – Posterior',
    );
    _pstMedialLateralCtrl.text = _extractInlineValue(text, 'Medial – Lateral');
    _pstOverallCtrl.text = _extractInlineValue(text, 'Overall Score');
    _trailPartACtrl.text = _extractInlineValue(text, 'Part A (Sec)');
    _trailPartBCtrl.text = _extractInlineValue(text, 'Part B (Sec)');
    _stroopCtrl.text = _extractInlineValue(text, 'Stroop');
  }

  void _clearEvaluationFormFields() {
    _diagnosisCtrl.clear();
    _heightCtrl.clear();
    _weightCtrl.clear();
    _birthDateCtrl.clear();
    _educationCtrl.clear();
    _maritalCtrl.clear();
    _occupationCtrl.clear();
    _locationCtrl.clear();
    _complaintDateCtrl.clear();
    _caregiverCtrl.clear();
    _medicalHistoryCtrl.clear();
    _diseaseNoteCtrl.clear();

    _alzExtraCtrl.clear();
    _pdExtraCtrl.clear();
    _alsExtraCtrl.clear();
    _msExtraCtrl.clear();
    _ataxiaExtraCtrl.clear();

    _chairStandCtrl.clear();
    _timedUpGoCtrl.clear();
    _pegRightCtrl.clear();
    _pegLeftCtrl.clear();
    _ctsibFirmOpenCtrl.clear();
    _ctsibFirmClosedCtrl.clear();
    _ctsibSoftOpenCtrl.clear();
    _ctsibSoftClosedCtrl.clear();
    _pstAnteriorPosteriorCtrl.clear();
    _pstMedialLateralCtrl.clear();
    _pstOverallCtrl.clear();
    _trailPartACtrl.clear();
    _trailPartBCtrl.clear();
    _stroopCtrl.clear();

    _motorSymptoms.clear();
    _sensorySymptoms.clear();
    _emotionalSymptoms.clear();
    _cognitiveSymptoms.clear();
    _pulmonarySymptoms.clear();
    _otherSymptoms.clear();
    _alzSymptoms.clear();
    _pdSymptoms.clear();
    _alsSymptoms.clear();
    _msSymptoms.clear();
    _ataxiaSymptoms.clear();
  }

  void _restoreSymptomsFromText(String text) {
    void fillGroup(
      String label,
      Set<String> target,
      TextEditingController extraCtrl,
    ) {
      final rawValue = _extractInlineValue(text, label);
      if (rawValue.isEmpty) return;

      final lower = rawValue.toLowerCase();
      final extraIndex = lower.indexOf('yeni bulgu:');

      final selectedPart = extraIndex == -1
          ? rawValue
          : rawValue.substring(0, extraIndex).trim();

      final extraPart = extraIndex == -1
          ? ''
          : rawValue.substring(extraIndex + 'yeni bulgu:'.length).trim();

      if (extraPart.isNotEmpty) {
        extraCtrl.text = extraPart;
      }

      if (selectedPart.trim().isEmpty) return;

      final parts = selectedPart.split(',').map((e) => e.trim()).where((e) {
        if (e.isEmpty) return false;
        final low = e.toLowerCase();
        return low != 'yok' &&
            low != 'none' &&
            low != '-' &&
            low != 'seçilmedi' &&
            low != 'secilmedi' &&
            low != 'boş' &&
            low != 'bos';
      });

      target.addAll(parts);
    }

    fillGroup('Motor', _motorSymptoms, _motorExtraCtrl);
    fillGroup('Duyusal', _sensorySymptoms, _sensoryExtraCtrl);
    fillGroup('Emosyonel', _emotionalSymptoms, _emotionalExtraCtrl);
    fillGroup('Kognitif', _cognitiveSymptoms, _cognitiveExtraCtrl);
    fillGroup('Pulmoner', _pulmonarySymptoms, _pulmonaryExtraCtrl);
    fillGroup('Diğer', _otherSymptoms, _otherExtraCtrl);
  }

  void _restoreDiseaseSelectionsFromText(String text) {
    if (text.trim().isEmpty) return;

    void fillSection(
      String header,
      Set<String> target,
      TextEditingController extraCtrl,
    ) {
      final start = text.indexOf('$header\n');
      if (start == -1) return;

      final contentStart = start + header.length + 1;
      final otherHeaders = [
        'Hafif Kognitif Bozukluk / Alzheimer Hastalığı\n',
        'Parkinson\n',
        'ALS\n',
        'MS\n',
        'Ataksi\n',
        'Klinisyen Notları\n',
      ];

      int? end;
      for (final marker in otherHeaders) {
        final idx = text.indexOf('\n\n$marker', contentStart);
        if (idx != -1) {
          if (end == null || idx < end) {
            end = idx;
          }
        }
      }

      final body = end == null
          ? text.substring(contentStart)
          : text.substring(contentStart, end);

      final lower = body.toLowerCase();
      final extraIndex = lower.indexOf('yeni bulgu:');

      final selectedPart = extraIndex == -1
          ? body
          : body.substring(0, extraIndex);
      final extraPart = extraIndex == -1
          ? ''
          : body.substring(extraIndex + 'yeni bulgu:'.length).trim();

      // selectedPart may end with a trailing ", " left by the join before
      // "Yeni bulgu:"; trim that off before splitting.
      var trimmedSelected = selectedPart.trim();
      if (trimmedSelected.endsWith(',')) {
        trimmedSelected = trimmedSelected
            .substring(0, trimmedSelected.length - 1)
            .trim();
      }

      final values = trimmedSelected
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      target.addAll(values);

      if (extraPart.isNotEmpty) {
        extraCtrl.text = extraPart;
      }
    }

    fillSection(
      'Hafif Kognitif Bozukluk / Alzheimer Hastalığı',
      _alzSymptoms,
      _alzExtraCtrl,
    );
    fillSection('Parkinson', _pdSymptoms, _pdExtraCtrl);
    fillSection('ALS', _alsSymptoms, _alsExtraCtrl);
    fillSection('MS', _msSymptoms, _msExtraCtrl);
    fillSection('Ataksi', _ataxiaSymptoms, _ataxiaExtraCtrl);
  }

  void _restoreDemographicsFromText(String text) {
    final diagnosis = _extractInlineValue(text, 'Tanı');
    if (diagnosis.isNotEmpty) _diagnosisCtrl.text = diagnosis;

    final height = _extractInlineValue(text, 'Boy');
    if (height.isNotEmpty) _heightCtrl.text = height;

    final weight = _extractInlineValue(text, 'Kilo');
    if (weight.isNotEmpty) _weightCtrl.text = weight;

    final birthDate = _extractInlineValue(text, 'Doğum Tarihi');
    if (birthDate.isNotEmpty) _birthDateCtrl.text = birthDate;

    final education = _extractInlineValue(text, 'Eğitim');
    if (education.isNotEmpty) _educationCtrl.text = education;

    final marital = _extractInlineValue(text, 'Medeni Durum');
    if (marital.isNotEmpty) _maritalCtrl.text = marital;

    final occupation = _extractInlineValue(text, 'Meslek');
    if (occupation.isNotEmpty) _occupationCtrl.text = occupation;

    final location = _extractInlineValue(text, 'Lokasyon');
    if (location.isNotEmpty) _locationCtrl.text = location;

    final complaintDate = _extractInlineValue(text, 'İlk Şikayet Tarihi');
    if (complaintDate.isNotEmpty) _complaintDateCtrl.text = complaintDate;

    final caregiver = _extractInlineValue(text, 'Bakım Veren');
    if (caregiver.isNotEmpty) _caregiverCtrl.text = caregiver;

    final dominantSide = _extractInlineValue(text, 'Dominant Taraf');
    if (dominantSide.isNotEmpty) {
      if (dominantSide == 'Sağ') {
        _dominantSide = 'Right';
      } else if (dominantSide == 'Sol') {
        _dominantSide = 'Left';
      } else if (dominantSide == 'Her İkisi') {
        _dominantSide = 'Both';
      }
    }

    final story = _extractSection(text, 'Hikaye');
    if (story.isNotEmpty) {
      _medicalHistoryCtrl.text = story;
    }
  }

  void _populateEditData() {
    final provider = context.read<EvaluationProvider>();

    if (!widget.isEdit) {
      final linkedHastaId = provider.filterHastaId;
      if (linkedHastaId != null) {
        _hastaId = linkedHastaId;
        final dbPatient = _findDbPatientById(linkedHastaId);
        if (dbPatient != null) {
          _applySelectedDbPatient(dbPatient);
        }
      }
      setState(() {});
      return;
    }

    final ev = provider.selected;
    if (ev == null) return;

    _hastaId = ev.hastaId;
    _hastaSearchCtrl.text = ev.hastaAdSoyad ?? '';

    final dbPatient = _findDbPatientById(ev.hastaId);
    if (dbPatient != null) {
      _applySelectedDbPatient(dbPatient);
    }

    _clearEvaluationFormFields();

    _sigaraDurumId = ev.sigaraDurumId;

    final packedHikaye = (ev.hikaye ?? '').trim();
    final packedNotlar = (ev.notlar ?? '').trim();
    final packedClinicianNotes = (ev.klinisyenNotlari ?? '').trim();

    _restoreDemographicsFromText(packedHikaye);
    final symptomsSection = _extractSection(packedNotlar, 'Semptomlar');
    _restoreSymptomsFromText(symptomsSection);
    final diseaseSection = _extractSection(packedNotlar, 'Hastalık');
    // CRITICAL: do NOT assign the entire Hastalık section back into
    // _diseaseNoteCtrl. _composeDiseaseNote later wraps this controller's
    // text under a "Klinisyen Notları" sub-header, so dumping the whole
    // disease block in here would re-embed every previous round-trip on
    // the next save and grow the saved notlar without bound. Only the
    // Klinisyen Notları sub-section (free-text the user typed) belongs
    // in this controller; if it isn't present, leave it empty so a
    // resave produces an unchanged Hastalık block.
    _diseaseNoteCtrl.text = _extractDiseaseClinicianNote(diseaseSection);
    _restoreDiseaseSelectionsFromText(diseaseSection);
    final functionalSection = _extractSection(
      packedClinicianNotes,
      'Fonksiyonel',
    );
    if (functionalSection.isNotEmpty) {
      _fillFunctionalControllersFromText(functionalSection);
    }

    _motorOpen =
        _motorSymptoms.isNotEmpty || _motorExtraCtrl.text.trim().isNotEmpty;
    _sensoryOpen =
        _sensorySymptoms.isNotEmpty || _sensoryExtraCtrl.text.trim().isNotEmpty;
    _emotionalOpen =
        _emotionalSymptoms.isNotEmpty ||
        _emotionalExtraCtrl.text.trim().isNotEmpty;
    _cognitiveOpen =
        _cognitiveSymptoms.isNotEmpty ||
        _cognitiveExtraCtrl.text.trim().isNotEmpty;
    _pulmonaryOpen =
        _pulmonarySymptoms.isNotEmpty ||
        _pulmonaryExtraCtrl.text.trim().isNotEmpty;
    _otherOpen =
        _otherSymptoms.isNotEmpty || _otherExtraCtrl.text.trim().isNotEmpty;

    _alzOpen = _alzSymptoms.isNotEmpty || _alzExtraCtrl.text.trim().isNotEmpty;
    _pdOpen = _pdSymptoms.isNotEmpty || _pdExtraCtrl.text.trim().isNotEmpty;
    _alsOpen = _alsSymptoms.isNotEmpty || _alsExtraCtrl.text.trim().isNotEmpty;
    _msOpen = _msSymptoms.isNotEmpty || _msExtraCtrl.text.trim().isNotEmpty;
    _ataxiaOpen =
        _ataxiaSymptoms.isNotEmpty || _ataxiaExtraCtrl.text.trim().isNotEmpty;

    _generalTestOpen =
        _chairStandCtrl.text.trim().isNotEmpty ||
        _timedUpGoCtrl.text.trim().isNotEmpty ||
        _pegRightCtrl.text.trim().isNotEmpty ||
        _pegLeftCtrl.text.trim().isNotEmpty;

    _ctsibOpen =
        _ctsibFirmOpenCtrl.text.trim().isNotEmpty ||
        _ctsibFirmClosedCtrl.text.trim().isNotEmpty ||
        _ctsibSoftOpenCtrl.text.trim().isNotEmpty ||
        _ctsibSoftClosedCtrl.text.trim().isNotEmpty;

    _pstOpen =
        _pstAnteriorPosteriorCtrl.text.trim().isNotEmpty ||
        _pstMedialLateralCtrl.text.trim().isNotEmpty ||
        _pstOverallCtrl.text.trim().isNotEmpty;

    _trailOpen =
        _trailPartACtrl.text.trim().isNotEmpty ||
        _trailPartBCtrl.text.trim().isNotEmpty;

    _stroopOpen = _stroopCtrl.text.trim().isNotEmpty;

    if (_diagnosisCtrl.text.trim().isEmpty) {
      _diagnosisCtrl.text = ev.diagnosis ?? ev.hastalikAdi ?? '';
    }
    if (_caregiverCtrl.text.trim().isEmpty) {
      _caregiverCtrl.text = ev.caregiver ?? '';
    }

    setState(() {});
  }

  Future<void> _fillPatientProfile(patient_model.Patient patient) async {
    patient_model.Patient resolvedPatient = patient;
    try {
      resolvedPatient = await PatientService.getHastaById(patient.hastaId);
    } catch (e) {
      debugPrint('Patient detail could not be loaded, using list row: $e');
    }
    if (!mounted) return;
    _applySelectedDbPatient(resolvedPatient);
    setState(() {});
  }

  Future<void> _openPatientSelector() async {
    _patientQueryCtrl.clear();

    if (_dbPatients.isEmpty) {
      await _loadDbPatients();
    }

    final selectedPatient = await showModalBottomSheet<patient_model.Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = _patientQueryCtrl.text.trim().toLowerCase();
            final results = query.isEmpty
                ? _dbPatients
                : _dbPatients.where((p) {
                    final fullName = p.tamAd.toLowerCase();
                    final email = (p.eposta ?? '').toLowerCase();
                    return fullName.contains(query) ||
                        email.contains(query) ||
                        p.hastaId.toString().contains(query);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 18,
                    bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9DFEA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Hasta Seç',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mevcut Supabase hastalarını ara ve seç.',
                        style: TextStyle(
                          color: _textMid,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _patientQueryCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: _inputDecoration(
                          'Hasta adı, e-posta veya hasta ID ile ara',
                          suffixIcon: const Icon(
                            Icons.search_rounded,
                            color: _textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _openCreatePatientSheet();
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Yeni Hasta Ekle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textMid,
                            side: const BorderSide(color: _border),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: results.isEmpty
                            ? const Center(
                                child: Text(
                                  'Bu arama için hasta bulunamadı.',
                                  style: TextStyle(
                                    color: _textMid,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final patient = results[index];
                                  final initials = patient.tamAd
                                      .split(' ')
                                      .where((e) => e.isNotEmpty)
                                      .take(2)
                                      .map((e) => e[0])
                                      .join()
                                      .toUpperCase();

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, patient),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _border),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x05000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: _primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: _primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  patient.tamAd,
                                                  style: const TextStyle(
                                                    color: _textDark,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  patient.eposta ??
                                                      'E-posta bilgisi yok',
                                                  style: const TextStyle(
                                                    color: _textMid,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '#${patient.hastaId}',
                                            style: const TextStyle(
                                              color: _textLight,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                            color: _textLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedPatient == null) return;
    await _fillPatientProfile(selectedPatient);
  }

  Future<patient_model.Patient?> _openCreatePatientSheet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientStep1Screen()),
    );

    if (!mounted) return null;
    await _loadDbPatients();
    return null;
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    if (_currentStep == 0) {
      final providerHastaId = context.read<EvaluationProvider>().filterHastaId;
      final dbHastaId = _selectedDbPatient?.hastaId;
      final effectiveHastaId = dbHastaId ?? providerHastaId ?? _hastaId;

      if (effectiveHastaId == null) {
        _showSnack('Lütfen bir hasta seçin.', isError: true);
        return;
      }

      _hastaId = effectiveHastaId;

      if (_medicalHistoryCtrl.text.trim().isEmpty) {
        _showSnack('Hastalık hikayesi zorunludur.', isError: true);
        return;
      }
    }

    if (!_isLastStep) {
      setState(() => _currentStep++);
      return;
    }

    await _saveEvaluation();
  }

  String _joinSelected(Set<String> values, TextEditingController extraCtrl) {
    final items = [...values];
    if (extraCtrl.text.trim().isNotEmpty) {
      items.add('Yeni bulgu: ${extraCtrl.text.trim()}');
    }
    return items.join(', ');
  }

  String _composeSymptomsNote() {
    final lines = <String>[
      'Motor: ${_joinSelected(_motorSymptoms, _motorExtraCtrl)}',
      'Duyusal: ${_joinSelected(_sensorySymptoms, _sensoryExtraCtrl)}',
      'Emosyonel: ${_joinSelected(_emotionalSymptoms, _emotionalExtraCtrl)}',
      'Kognitif: ${_joinSelected(_cognitiveSymptoms, _cognitiveExtraCtrl)}',
      'Pulmoner: ${_joinSelected(_pulmonarySymptoms, _pulmonaryExtraCtrl)}',
      'Diğer: ${_joinSelected(_otherSymptoms, _otherExtraCtrl)}',
    ];

    return lines.join('\n');
  }

  String _composeDiseaseNote() {
    final sections = <String>[];

    final alz = _joinSelected(_alzSymptoms, _alzExtraCtrl);
    if (alz.isNotEmpty) {
      sections.add("Hafif Kognitif Bozukluk / Alzheimer Hastalığı\n$alz");
    }

    final pd = _joinSelected(_pdSymptoms, _pdExtraCtrl);
    if (pd.isNotEmpty) {
      sections.add("Parkinson\n$pd");
    }

    final als = _joinSelected(_alsSymptoms, _alsExtraCtrl);
    if (als.isNotEmpty) {
      sections.add("ALS\n$als");
    }

    final ms = _joinSelected(_msSymptoms, _msExtraCtrl);
    if (ms.isNotEmpty) {
      sections.add("MS\n$ms");
    }

    final ataxia = _joinSelected(_ataxiaSymptoms, _ataxiaExtraCtrl);
    if (ataxia.isNotEmpty) {
      sections.add("Ataksi\n$ataxia");
    }

    if (_diseaseNoteCtrl.text.trim().isNotEmpty) {
      sections.add('Klinisyen Notları\n${_diseaseNoteCtrl.text.trim()}');
    }

    return sections.join('\n\n');
  }

  String _composeFunctionalNote() {
    final sections = <String>[];

    final general = <String>[];
    if (_chairStandCtrl.text.trim().isNotEmpty) {
      general.add(
        '30-sec Chair Stand Test (Reps): ${_chairStandCtrl.text.trim()}',
      );
    }
    if (_timedUpGoCtrl.text.trim().isNotEmpty) {
      general.add('Timed Up & Go Test (Sec): ${_timedUpGoCtrl.text.trim()}');
    }
    if (_pegRightCtrl.text.trim().isNotEmpty) {
      general.add(
        '9-Hole Peg – Right Hand (Sec): ${_pegRightCtrl.text.trim()}',
      );
    }
    if (_pegLeftCtrl.text.trim().isNotEmpty) {
      general.add('9-Hole Peg – Left Hand (Sec): ${_pegLeftCtrl.text.trim()}');
    }
    if (general.isNotEmpty) {
      sections.add('Genel Test\n${general.join('\n')}');
    }

    final ctsib = <String>[];
    if (_ctsibFirmOpenCtrl.text.trim().isNotEmpty) {
      ctsib.add(
        'Eyes Open – Firm Surface (Sec): ${_ctsibFirmOpenCtrl.text.trim()}',
      );
    }
    if (_ctsibFirmClosedCtrl.text.trim().isNotEmpty) {
      ctsib.add(
        'Eyes Closed – Firm Surface (Sec): ${_ctsibFirmClosedCtrl.text.trim()}',
      );
    }
    if (_ctsibSoftOpenCtrl.text.trim().isNotEmpty) {
      ctsib.add(
        'Eyes Open – Soft Surface (Sec): ${_ctsibSoftOpenCtrl.text.trim()}',
      );
    }
    if (_ctsibSoftClosedCtrl.text.trim().isNotEmpty) {
      ctsib.add(
        'Eyes Closed – Soft Surface (Sec): ${_ctsibSoftClosedCtrl.text.trim()}',
      );
    }
    if (ctsib.isNotEmpty) {
      sections.add('CTSIB Testi\n${ctsib.join('\n')}');
    }

    final pst = <String>[];
    if (_pstAnteriorPosteriorCtrl.text.trim().isNotEmpty) {
      pst.add('Anterior – Posterior: ${_pstAnteriorPosteriorCtrl.text.trim()}');
    }
    if (_pstMedialLateralCtrl.text.trim().isNotEmpty) {
      pst.add('Medial – Lateral: ${_pstMedialLateralCtrl.text.trim()}');
    }
    if (_pstOverallCtrl.text.trim().isNotEmpty) {
      pst.add('Overall Score: ${_pstOverallCtrl.text.trim()}');
    }
    if (pst.isNotEmpty) {
      sections.add('PST – Postural Stability Test\n${pst.join('\n')}');
    }

    final trail = <String>[];
    if (_trailPartACtrl.text.trim().isNotEmpty) {
      trail.add('Part A (Sec): ${_trailPartACtrl.text.trim()}');
    }
    if (_trailPartBCtrl.text.trim().isNotEmpty) {
      trail.add('Part B (Sec): ${_trailPartBCtrl.text.trim()}');
    }
    if (trail.isNotEmpty) {
      sections.add('Trail Making Testi\n${trail.join('\n')}');
    }

    if (_stroopCtrl.text.trim().isNotEmpty) {
      sections.add('Stroop Testi\nStroop: ${_stroopCtrl.text.trim()}');
    }

    return sections.join('\n\n');
  }

  // Builds the list of structured test rows to persist in
  // degerlendirmeTestSonuclari.  Each non-empty controller becomes one row.
  // testIdMap is keyed by lowercase testAdi/testKodu from the testler table.
  // Rows also carry _test* metadata so EvaluationService can find/create a
  // non-null testId before inserting into degerlendirmeTestSonuclari.
  List<Map<String, dynamic>> _collectTestRows({
    required int degerlendirmeId,
    required int hastaId,
    required Map<String, int> testIdMap,
  }) {
    final rows = <Map<String, dynamic>>[];

    void add(
      TextEditingController ctrl, {
      required String testAdi,
      required String testKodu,
      required String kategori,
      required String metrikAdi,
      required String birim,
    }) {
      final raw = ctrl.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) return;
      final value = double.tryParse(raw);
      if (value == null) return;
      final testId =
          testIdMap[testAdi.toLowerCase()] ?? testIdMap[testKodu.toLowerCase()];
      rows.add({
        'degerlendirmeId': degerlendirmeId,
        'hastaId': hastaId,
        if (testId != null) 'testId': testId,
        '_testAdi': testAdi,
        '_testKodu': testKodu,
        '_testKategori': kategori,
        'metrikAdi': metrikAdi,
        'olculenDeger': value,
        'birim': birim,
      });
    }

    add(
      _chairStandCtrl,
      testAdi: 'Genel Test',
      testKodu: 'GENEL_TEST',
      kategori: 'Fonksiyonel',
      metrikAdi: '30-sec Chair Stand Test (Reps)',
      birim: 'Tekrar',
    );
    add(
      _timedUpGoCtrl,
      testAdi: 'Genel Test',
      testKodu: 'GENEL_TEST',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Timed Up & Go Test (Sec)',
      birim: 'Saniye',
    );
    add(
      _pegRightCtrl,
      testAdi: 'Genel Test',
      testKodu: 'GENEL_TEST',
      kategori: 'Fonksiyonel',
      metrikAdi: '9-Hole Peg – Right Hand (Sec)',
      birim: 'Saniye',
    );
    add(
      _pegLeftCtrl,
      testAdi: 'Genel Test',
      testKodu: 'GENEL_TEST',
      kategori: 'Fonksiyonel',
      metrikAdi: '9-Hole Peg – Left Hand (Sec)',
      birim: 'Saniye',
    );
    add(
      _ctsibFirmOpenCtrl,
      testAdi: 'CTSIB Testi',
      testKodu: 'CTSIB',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Eyes Open – Firm Surface (Sec)',
      birim: 'Saniye',
    );
    add(
      _ctsibFirmClosedCtrl,
      testAdi: 'CTSIB Testi',
      testKodu: 'CTSIB',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Eyes Closed – Firm Surface (Sec)',
      birim: 'Saniye',
    );
    add(
      _ctsibSoftOpenCtrl,
      testAdi: 'CTSIB Testi',
      testKodu: 'CTSIB',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Eyes Open – Soft Surface (Sec)',
      birim: 'Saniye',
    );
    add(
      _ctsibSoftClosedCtrl,
      testAdi: 'CTSIB Testi',
      testKodu: 'CTSIB',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Eyes Closed – Soft Surface (Sec)',
      birim: 'Saniye',
    );
    add(
      _pstAnteriorPosteriorCtrl,
      testAdi: 'PST',
      testKodu: 'PST',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Anterior – Posterior',
      birim: 'mm',
    );
    add(
      _pstMedialLateralCtrl,
      testAdi: 'PST',
      testKodu: 'PST',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Medial – Lateral',
      birim: 'mm',
    );
    add(
      _pstOverallCtrl,
      testAdi: 'PST',
      testKodu: 'PST',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Overall Score',
      birim: 'Puan',
    );
    add(
      _trailPartACtrl,
      testAdi: 'Trail Making Testi',
      testKodu: 'TRAIL_MAKING',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Part A (Sec)',
      birim: 'Saniye',
    );
    add(
      _trailPartBCtrl,
      testAdi: 'Trail Making Testi',
      testKodu: 'TRAIL_MAKING',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Part B (Sec)',
      birim: 'Saniye',
    );
    add(
      _stroopCtrl,
      testAdi: 'Stroop Testi',
      testKodu: 'STROOP',
      kategori: 'Fonksiyonel',
      metrikAdi: 'Stroop',
      birim: 'Saniye',
    );

    return rows;
  }

  List<Map<String, dynamic>> _collectStructuredBelirtiler() {
    final rows = <Map<String, dynamic>>[];

    void addGroup(
      String kategoriAdi,
      Set<String> selected,
      TextEditingController extraCtrl, {
      String? hastalikAdi,
    }) {
      for (final value in selected) {
        final belirtiAdi = value.trim();
        if (belirtiAdi.isEmpty) continue;
        rows.add({
          'belirtiAdi': belirtiAdi,
          'kategoriAdi': kategoriAdi,
          if ((hastalikAdi ?? '').trim().isNotEmpty)
            'hastalikAdi': hastalikAdi!.trim(),
        });
      }

      final custom = extraCtrl.text.trim();
      if (custom.isNotEmpty) {
        rows.add({
          'belirtiAdi': custom,
          'kategoriAdi': kategoriAdi,
          'notlar': 'Yeni bulgu',
          if ((hastalikAdi ?? '').trim().isNotEmpty)
            'hastalikAdi': hastalikAdi!.trim(),
        });
      }
    }

    addGroup('Motor', _motorSymptoms, _motorExtraCtrl);
    addGroup('Duyusal', _sensorySymptoms, _sensoryExtraCtrl);
    addGroup('Emosyonel', _emotionalSymptoms, _emotionalExtraCtrl);
    addGroup('Kognitif', _cognitiveSymptoms, _cognitiveExtraCtrl);
    addGroup('Pulmoner', _pulmonarySymptoms, _pulmonaryExtraCtrl);
    addGroup('Diğer', _otherSymptoms, _otherExtraCtrl);
    addGroup(
      'Hafif Kognitif Bozukluk / Alzheimer Hastalığı',
      _alzSymptoms,
      _alzExtraCtrl,
      hastalikAdi: 'Alzheimer',
    );
    addGroup('Parkinson', _pdSymptoms, _pdExtraCtrl, hastalikAdi: 'Parkinson');
    addGroup('ALS', _alsSymptoms, _alsExtraCtrl, hastalikAdi: 'ALS');
    addGroup('MS', _msSymptoms, _msExtraCtrl, hastalikAdi: 'MS');
    addGroup(
      'Ataksi',
      _ataxiaSymptoms,
      _ataxiaExtraCtrl,
      hastalikAdi: 'Ataksi',
    );

    return rows;
  }

  Map<String, Map<String, dynamic>> _collectFunctionalStructuredRows() {
    double? number(TextEditingController ctrl) {
      final raw = ctrl.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) return null;
      return double.tryParse(raw);
    }

    String? notes(List<MapEntry<String, TextEditingController>> items) {
      final lines = <String>[];
      for (final item in items) {
        final value = item.value.text.trim();
        if (value.isEmpty) continue;
        lines.add('${item.key}: $value');
      }
      return lines.isEmpty ? null : lines.join('\n');
    }

    final rows = <String, Map<String, dynamic>>{};

    final genelPuan = number(_chairStandCtrl);
    final genelSure =
        number(_timedUpGoCtrl) ?? number(_pegRightCtrl) ?? number(_pegLeftCtrl);
    final genelNotlar = notes([
      MapEntry('30 Saniye Otur Kalk', _chairStandCtrl),
      MapEntry('Zamanlı Kalk ve Yürü', _timedUpGoCtrl),
      MapEntry('9-Delikli Peg Sağ', _pegRightCtrl),
      MapEntry('9-Delikli Peg Sol', _pegLeftCtrl),
    ]);
    final genel = <String, dynamic>{};
    genel['puan'] = genelPuan;
    genel['sure'] = genelSure;
    genel['notlar'] = genelNotlar;
    genel.removeWhere((_, value) => value == null);
    if (genel.isNotEmpty) rows['fonksiyonelGenel'] = genel;

    final ctsibNotlar = notes([
      MapEntry('Gözler Açık - Sert Zemin', _ctsibFirmOpenCtrl),
      MapEntry('Gözler Kapalı - Sert Zemin', _ctsibFirmClosedCtrl),
      MapEntry('Gözler Açık - Yumuşak Zemin', _ctsibSoftOpenCtrl),
      MapEntry('Gözler Kapalı - Yumuşak Zemin', _ctsibSoftClosedCtrl),
    ]);
    if (ctsibNotlar != null) {
      rows['fonksiyonelCtsib'] = {'notlar': ctsibNotlar};
    }

    final pstNotlar = notes([
      MapEntry('Anterior - Posterior', _pstAnteriorPosteriorCtrl),
      MapEntry('Medial - Lateral', _pstMedialLateralCtrl),
      MapEntry('Toplam Skor', _pstOverallCtrl),
    ]);
    final pstPuan = number(_pstOverallCtrl);
    final pst = <String, dynamic>{};
    pst['puan'] = pstPuan;
    pst['notlar'] = pstNotlar;
    pst.removeWhere((_, value) => value == null);
    if (pst.isNotEmpty) rows['fonksiyonelPst'] = pst;

    final trailPartA = number(_trailPartACtrl);
    final trailPartB = number(_trailPartBCtrl);
    final trailNotlar = notes([
      MapEntry('İz Koşu Test A', _trailPartACtrl),
      MapEntry('İz Koşu Test B', _trailPartBCtrl),
    ]);
    final izKosu = <String, dynamic>{};
    if (trailPartA != null && trailPartB == null) {
      izKosu['sure'] = trailPartA;
    }
    if (trailPartB != null && trailPartA == null) {
      izKosu['sure'] = trailPartB;
    }
    izKosu['notlar'] = trailNotlar;
    izKosu.removeWhere((_, value) => value == null);
    if (izKosu.isNotEmpty) rows['fonksiyonelIzKosu'] = izKosu;

    final stroopNotlar = notes([MapEntry('Stroop', _stroopCtrl)]);
    if (stroopNotlar != null) {
      rows['fonksiyonelStroop'] = {'notlar': stroopNotlar};
    }

    return rows;
  }

  String? _toIsoDateOrNull(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final parsedDirect = DateTime.tryParse(value);
    if (parsedDirect != null) {
      return DateTime(
        parsedDirect.year,
        parsedDirect.month,
        parsedDirect.day,
      ).toIso8601String();
    }

    final match = RegExp(
      r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$',
    ).firstMatch(value);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.day != day || parsed.month != month || parsed.year != year) {
      return null;
    }

    return parsed.toIso8601String();
  }

  Future<int> _resolveCurrentDoctorId() async {
    final provider = context.read<EvaluationProvider>();
    final auth = context.read<AuthProvider>();

    final providerDoctorId = provider.currentDoctorId;
    if (providerDoctorId > 0) return providerDoctorId;

    // degerlendirmeler.klinisyenId stores kullaniciId (from kullanicilar), not klinisyenId
    final kullaniciId = auth.kullaniciId;
    if (kullaniciId > 0) {
      provider.setDoctorId(kullaniciId);
      return kullaniciId;
    }

    // Last resort: email lookup returns kullaniciId from kullanicilar table
    final email = auth.user?.eposta.trim() ?? '';
    if (email.isNotEmpty) {
      final serviceId =
          await EvaluationService().getClinicianIdByEmail(email) ?? 0;
      if (serviceId > 0) {
        provider.setDoctorId(serviceId);
        return serviceId;
      }
    }

    return 0;
  }

  Future<void> _saveEvaluation() async {
    setState(() => _isSaving = true);
    try {
      await _saveEvaluationImpl();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEvaluationImpl() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EvaluationProvider>();
    // Capture klinisyenId before any await (hastalar.klinisyenId ownership check)
    final clinicianKlinisyenId =
        context.read<AuthProvider>().user?.klinisyenId ?? 0;

    final currentDoctorId = await _resolveCurrentDoctorId();
    if (currentDoctorId <= 0) {
      _showSnack(
        'Klinisyen kullanıcı ID bulunamadı. Lütfen tekrar giriş yapın.',
        isError: true,
      );
      return;
    }

    if (_selectedDbPatient == null && _hastaSearchCtrl.text.trim().isNotEmpty) {
      _selectedDbPatient = _findDbPatientByName(_hastaSearchCtrl.text.trim());
      if (_selectedDbPatient != null) {
        _hastaId = _selectedDbPatient!.hastaId;
      }
    }

    final dbHastaId = _selectedDbPatient?.hastaId;
    final effectiveHastaId = dbHastaId ?? provider.filterHastaId ?? _hastaId;

    if (effectiveHastaId == null) {
      _showSnack('Lütfen bir hasta seçin.', isError: true);
      return;
    }

    _hastaId = effectiveHastaId;

    // Validate: patient must belong to this doctor (hastalar.klinisyenId = klinisyenler.klinisyenId)
    if (clinicianKlinisyenId > 0) {
      final isOwned = await PatientService.isPatientOwnedByClinician(
        effectiveHastaId,
        clinicianKlinisyenId,
      );
      if (!isOwned) {
        _showSnack(
          'Bu hasta size kayıtlı olmadığı için değerlendirme oluşturulamaz.',
          isError: true,
        );
        return;
      }
    }

    final patient = _selectedDbPatient;

    // C5: resolve hastalikId from diagnosis text; fallback to existing id on edit
    int? resolvedHastalikId;
    final diagnosisLookupText = _diagnosisCtrl.text.trim();
    if (diagnosisLookupText.isNotEmpty) {
      try {
        resolvedHastalikId = await EvaluationService().getHastalikIdByAdi(
          diagnosisLookupText,
        );
      } catch (_) {}
    }
    if (resolvedHastalikId == null && widget.isEdit) {
      resolvedHastalikId = provider.selected?.hastalikId;
    }

    final allSymptoms = <String>{
      ..._motorSymptoms,
      ..._sensorySymptoms,
      ..._emotionalSymptoms,
      ..._cognitiveSymptoms,
      ..._pulmonarySymptoms,
      ..._otherSymptoms,
    }.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);

    final symptomsNoteText = _composeSymptomsNote().trim();
    final diseaseNoteText = _composeDiseaseNote().trim();
    final functionalsNoteText = _composeFunctionalNote().trim();

    final packedHikaye = [
      if (_diagnosisCtrl.text.trim().isNotEmpty)
        'Tanı: ${_diagnosisCtrl.text.trim()}',
      if (_heightCtrl.text.trim().isNotEmpty) 'Boy: ${_heightCtrl.text.trim()}',
      if (_weightCtrl.text.trim().isNotEmpty)
        'Kilo: ${_weightCtrl.text.trim()}',
      if (_birthDateCtrl.text.trim().isNotEmpty)
        'Doğum Tarihi: ${_birthDateCtrl.text.trim()}',
      if (_educationCtrl.text.trim().isNotEmpty)
        'Eğitim: ${_educationCtrl.text.trim()}',
      if (_maritalCtrl.text.trim().isNotEmpty)
        'Medeni Durum: ${_maritalCtrl.text.trim()}',
      if (_occupationCtrl.text.trim().isNotEmpty)
        'Meslek: ${_occupationCtrl.text.trim()}',
      if (_locationCtrl.text.trim().isNotEmpty)
        'Lokasyon: ${_locationCtrl.text.trim()}',
      if (_complaintDateCtrl.text.trim().isNotEmpty)
        'İlk Şikayet Tarihi: ${_complaintDateCtrl.text.trim()}',
      if (_caregiverCtrl.text.trim().isNotEmpty)
        'Bakım Veren: ${_caregiverCtrl.text.trim()}',
      if ((_dominantSide ?? '').trim().isNotEmpty)
        'Dominant Taraf: ${_dominantSide == 'Right'
            ? 'Sağ'
            : _dominantSide == 'Left'
            ? 'Sol'
            : 'Her İkisi'}',
      if (_medicalHistoryCtrl.text.trim().isNotEmpty)
        'Hikaye:\n${_medicalHistoryCtrl.text.trim()}',
    ].join('\n\n');

    final packedNotlar = [
      if (symptomsNoteText.isNotEmpty) 'Semptomlar:\n$symptomsNoteText',
      if (diseaseNoteText.isNotEmpty) 'Hastalık:\n$diseaseNoteText',
    ].join('\n\n');

    final packedKlinisyenNotlari = [
      if (functionalsNoteText.isNotEmpty) 'Fonksiyonel:\n$functionalsNoteText',
    ].join('\n\n');

    final evaluation = Evaluation(
      degerlendirmeId: widget.isEdit ? (provider.selected?.id ?? 0) : 0,
      doctorId: currentDoctorId,
      hastaId: effectiveHastaId,
      degerlendirmeTarihi: widget.isEdit && provider.selected != null
          ? provider.selected!.degerlendirmeTarihi
          : DateTime.now().toIso8601String(),

      hastaAdSoyad: _hastaSearchCtrl.text.trim().isNotEmpty
          ? _hastaSearchCtrl.text.trim()
          : (patient?.tamAd ?? ''),

      sigaraDurumId: _sigaraDurumId,
      hastalikId: resolvedHastalikId,

      diagnosis: _diagnosisCtrl.text.trim().isEmpty
          ? null
          : _diagnosisCtrl.text.trim(),

      hikaye: packedHikaye.isEmpty ? null : packedHikaye,
      baslangicTarihi: _toIsoDateOrNull(_complaintDateCtrl.text),

      notlar: packedNotlar.isEmpty ? null : packedNotlar,

      // Önemli: update işleminde provider/service bu alanları eski değerlerle birleştirmemeli; tamamen replace etmeli.
      klinisyenNotlari: packedKlinisyenNotlari.isEmpty
          ? null
          : packedKlinisyenNotlari,

      caregiver: _caregiverCtrl.text.trim().isEmpty
          ? null
          : _caregiverCtrl.text.trim(),

      kullanilanIlaclar: null,

      symptoms: allSymptoms,
      symptomsNote: symptomsNoteText.isEmpty ? null : symptomsNoteText,
      diseaseNote: diseaseNoteText.isEmpty ? null : diseaseNoteText,
      functionalsNote: functionalsNoteText.isEmpty ? null : functionalsNoteText,
    );

    final success = widget.isEdit && provider.selected?.id != null
        ? await provider.update(provider.selected!.id!, evaluation)
        : await provider.create(evaluation);

    if (!mounted) return;

    if (success) {
      // After the evaluation row is persisted, also write structured test rows
      // to degerlendirmeTestSonuclari so the comparison screen can read them.
      // provider.selected is set to the saved Evaluation by create/update.
      final savedId =
          provider.selected?.id ?? provider.selected?.degerlendirmeId;
      if (savedId != null && savedId > 0) {
        final svc = EvaluationService();
        try {
          final muayeneId = await svc.createMuayene(
            hastaId: effectiveHastaId,
            degerlendirmeId: savedId,
            muayeneTarihi: evaluation.degerlendirmeTarihi,
            notlar: null,
          );

          if (muayeneId != null) {
            await svc.getOrCreateKlinikDegerlendirme(
              hastaId: effectiveHastaId,
              muayeneId: muayeneId,
              notlar: diseaseNoteText.isEmpty ? null : diseaseNoteText,
            );
            await svc.getOrCreateDemografikBilgiler(
              degerlendirmeId: savedId,
              hastaId: effectiveHastaId,
              muayeneId: muayeneId,
            );
            await svc.saveMuayeneBelirtileri(
              muayeneId: muayeneId,
              belirtiler: _collectStructuredBelirtiler(),
              hastalikId: resolvedHastalikId,
            );
            await svc.saveFunctionalStructuredRows(
              muayeneId: muayeneId,
              rowsByTable: _collectFunctionalStructuredRows(),
            );
          }
        } catch (e) {
          debugPrint(
            '_saveEvaluation: yapılandırılmış klinik veriler kaydedilemedi: $e',
          );
        }

        try {
          final testIdMap = await svc.getTestIdMap();
          final testRows = _collectTestRows(
            degerlendirmeId: savedId,
            hastaId: effectiveHastaId,
            testIdMap: testIdMap,
          );
          await svc.upsertTestSonuclari(
            degerlendirmeId: savedId,
            hastaId: effectiveHastaId,
            rows: testRows,
          );
        } catch (e) {
          debugPrint('_saveEvaluation: test sonuçları kaydedilemedi: $e');
        }
      }
      if (!mounted) return;
      _showSnack(
        widget.isEdit
            ? 'Değerlendirme güncellendi.'
            : 'Değerlendirme kaydedildi.',
      );
      Navigator.pop(context, true);
    } else {
      _showSnack(provider.formError ?? 'İşlem başarısız oldu.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _successText,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _textLight,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _textMid,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: const TextStyle(
        color: _textDark,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(hint, suffixIcon: suffixIcon),
    );
  }

  PreferredSizeWidget _topAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _primary,
              size: 18,
            ),
          ),
        ),
      ),
      title: const Text(
        'Klinik Değerlendirme',
        style: TextStyle(
          color: _textDark,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _border),
      ),
    );
  }

  Widget _headerBand() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Klinik Değerlendirmeler',
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTabs() {
    return Container(
      color: _surface,
      child: Row(
        children: List.generate(_steps.length, (index) {
          final item = _steps[index];
          final selected = index == _currentStep;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentStep = index),
              child: Container(
                padding: const EdgeInsets.only(top: 14, bottom: 12),
                decoration: BoxDecoration(
                  color: selected ? _primary.withOpacity(0.06) : _surface,
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? _primary : _border,
                      width: selected ? 2.2 : 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      item.icon,
                      color: selected ? _primary : _textLight,
                      size: 22,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? _primary : _textLight,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionIntro() {
    final step = _steps[_currentStep];
    final sectionTitle = switch (_currentStep) {
      0 => 'Demografik Bilgiler',
      1 => 'Bulgular / Semptomlar',
      2 => 'Hastalığa Özgü Bilgiler',
      _ => 'Fonksiyonel Değerlendirmeler',
    };

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(step.icon, color: _primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionTitle,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bölüm ${_currentStep + 1} / ${_steps.length}',
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Widget child,
    Color color = _surface,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _expandCard({
    required String title,
    required bool open,
    required VoidCallback onTap,
    required Widget child,
    Color titleColor = _primary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _textMid,
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            const Divider(height: 1, color: _border),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ],
      ),
    );
  }

  Widget _symptomChecklist({
    required List<String> options,
    required Set<String> selected,
    required TextEditingController extraCtrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((item) {
            final isSelected = selected.contains(item);
            return FilterChip(
              selected: isSelected,
              label: Text(item),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(item);
                  } else {
                    selected.remove(item);
                  }
                });
              },
              selectedColor: _primarySoft,
              checkmarkColor: _primary,
              labelStyle: TextStyle(
                color: isSelected ? _primary : _textDark,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: isSelected ? _primary : _border),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _field(
          controller: extraCtrl,
          hint: 'Yeni semptom ekle...',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDemographics() {
    context.watch<EvaluationProvider>();
    final selectedPatient = _findSelectedPatient();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          color: _primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hasta Seçimi',
                style: TextStyle(
                  color: _primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _openPatientSelector,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    'Hasta ara veya seç',
                    suffixIcon: const Icon(
                      Icons.search_rounded,
                      color: _textLight,
                    ),
                  ),
                  child: Text(
                    _hastaId == null
                        ? 'Hasta aramak veya seçmek için dokunun'
                        : _hastaSearchCtrl.text,
                    style: TextStyle(
                      color: _hastaId == null ? _textLight : _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selectedPatient != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${selectedPatient.tamAd} adlı hastanın kaydı gösteriliyor',
              style: const TextStyle(
                color: _successText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        _label('Ad Soyad'),
        _field(controller: _hastaSearchCtrl, hint: 'Hasta adı', readOnly: true),
        const SizedBox(height: 18),
        _label('Tanı'),
        _field(controller: _diagnosisCtrl, hint: 'Tanı'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Boy (cm)'),
                  _field(controller: _heightCtrl, hint: 'örn. 170'),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Kilo (kg)'),
                  _field(controller: _weightCtrl, hint: 'örn. 70'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Doğum Tarihi'),
                  _field(controller: _birthDateCtrl, hint: 'dd.mm.yyyy'),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Eğitim Durumu'),
                  _field(controller: _educationCtrl, hint: 'Eğitim durumu'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Medeni Durum'),
                  _field(controller: _maritalCtrl, hint: 'Medeni durum'),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Meslek'),
                  _field(controller: _occupationCtrl, hint: 'Meslek'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Yaşadığı Yer'),
        _field(controller: _locationCtrl, hint: 'İl / İlçe'),
        const SizedBox(height: 18),
        _label('İlk Şikayet Tarihi'),
        _field(controller: _complaintDateCtrl, hint: 'dd.mm.yyyy'),
        const SizedBox(height: 18),
        _label('Hastalık Hikayesi'),
        _field(
          controller: _medicalHistoryCtrl,
          hint: "Hastanın tıbbi öyküsünü yazın...",
          maxLines: 5,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Hastalık hikayesi zorunlu'
              : null,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Sigara Kullanımı'),
                  DropdownButtonFormField<int>(
                    value: _sigaraDurumId,
                    decoration: _inputDecoration('— Seçiniz —'),
                    items: SigaraDurum.defaults
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.ad),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _sigaraDurumId = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Bakım Veren'),
                  _field(controller: _caregiverCtrl, hint: 'Bakım veren'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Dominant Taraf'),
        DropdownButtonFormField<String>(
          value: (_dominantSide == null || _dominantSide!.trim().isEmpty)
              ? null
              : _dominantSide,
          decoration: _inputDecoration('— Seçiniz —'),
          items: const [
            DropdownMenuItem(value: 'Right', child: Text('Sağ')),
            DropdownMenuItem(value: 'Left', child: Text('Sol')),
            DropdownMenuItem(value: 'Both', child: Text('Her İkisi')),
          ],
          onChanged: (v) => setState(() => _dominantSide = v),
        ),
      ],
    );
  }

  Widget _buildSymptoms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _expandCard(
          title: 'Motor semptomlar',
          open: _motorOpen,
          onTap: () => setState(() => _motorOpen = !_motorOpen),
          child: _symptomChecklist(
            options: const [
              'Kas güçsüzlüğü',
              'Denge bozukluğu',
              'Yürüme problemleri',
              'Kas spazmı',
              'Spastisite',
              'Kavrama kuvvetinde azalma',
              'Eklem hareket açıklığında kısıtlılıklar',
              'Konuşma bozukluğu',
              'Yutma problemleri',
              'Günlük yaşam aktivitelerinde etkilenim',
              'Aerobik kapasitede azalma',
              'Yürüme hızında azalma',
            ],
            selected: _motorSymptoms,
            extraCtrl: _motorExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Duyusal semptomlar',
          open: _sensoryOpen,
          onTap: () => setState(() => _sensoryOpen = !_sensoryOpen),
          child: _symptomChecklist(
            options: const [
              'Ağrı',
              'Uyuşukluk',
              'Bulanık görme',
              'Çift görme',
              'Görme keskinliğinin azalması',
              'İşitme problemleri',
            ],
            selected: _sensorySymptoms,
            extraCtrl: _sensoryExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Emosyonel semptomlar',
          open: _emotionalOpen,
          onTap: () => setState(() => _emotionalOpen = !_emotionalOpen),
          child: _symptomChecklist(
            options: const ['Depresyon', 'Anksiyete', 'Emosyonel labilite'],
            selected: _emotionalSymptoms,
            extraCtrl: _emotionalExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Kognitif semptomlar',
          open: _cognitiveOpen,
          onTap: () => setState(() => _cognitiveOpen = !_cognitiveOpen),
          child: _symptomChecklist(
            options: const ['Dikkat problemleri', 'Hafıza problemleri'],
            selected: _cognitiveSymptoms,
            extraCtrl: _cognitiveExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Pulmoner semptomlar',
          open: _pulmonaryOpen,
          onTap: () => setState(() => _pulmonaryOpen = !_pulmonaryOpen),
          child: _symptomChecklist(
            options: const [
              'Dispne',
              'Eforla dispne',
              'Balgam',
              'Göğüs ağrısı',
              'Hırıltılı nefes alma',
              'Horlama',
              'Uykuda solunum problemleri',
              'Öksürük kuvvetinde azalma',
              'Eforla desaturasyon',
            ],
            selected: _pulmonarySymptoms,
            extraCtrl: _pulmonaryExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Diğer semptomlar',
          open: _otherOpen,
          onTap: () => setState(() => _otherOpen = !_otherOpen),
          child: _symptomChecklist(
            options: const [
              'Yorgunluk',
              'Uyku problemleri',
              'Üriner inkontinans',
              'Seksüel disfonksiyon',
            ],
            selected: _otherSymptoms,
            extraCtrl: _otherExtraCtrl,
          ),
        ),
      ],
    );
  }

  Widget _buildDisease() {
    return Column(
      children: [
        _expandCard(
          title: 'Hafif Kognitif Bozukluk / Alzheimer Hastalığı',
          open: _alzOpen,
          onTap: () => setState(() => _alzOpen = !_alzOpen),
          titleColor: _primary,
          child: _symptomChecklist(
            options: const [],
            selected: _alzSymptoms,
            extraCtrl: _alzExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Parkinson',
          open: _pdOpen,
          onTap: () => setState(() => _pdOpen = !_pdOpen),
          titleColor: const Color(0xFF0BAA3A),
          child: _symptomChecklist(
            options: const [
              'Tremor',
              'Rijidite',
              'Bradikinezi',
              'Donma fenomeni',
              'Kas krampları',
              'Postüral instabilite',
              'Fleksör postür',
            ],
            selected: _pdSymptoms,
            extraCtrl: _pdExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'ALS',
          open: _alsOpen,
          onTap: () => setState(() => _alsOpen = !_alsOpen),
          titleColor: const Color(0xFFFF5A00),
          child: _symptomChecklist(
            options: const [
              'Kas seyirmesi',
              'Dilde atrofi',
              'Tenar-hipotenar atrofi',
              'Aktif çene refleksi',
              'Düşük ayak',
              'Klonus',
              'Azalmış derin tendon refleksleri',
            ],
            selected: _alsSymptoms,
            extraCtrl: _alsExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'MS',
          open: _msOpen,
          onTap: () => setState(() => _msOpen = !_msOpen),
          titleColor: const Color(0xFF8B19FF),
          child: _symptomChecklist(
            options: const [
              'Vertigo',
              'Optik nörit',
              'Ataksi',
              'Lhermitte bulgusu',
              'Fasiyal uyuşukluk',
              'Aşırı aktif mesane',
              'Hemiparezi',
            ],
            selected: _msSymptoms,
            extraCtrl: _msExtraCtrl,
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Ataksi',
          open: _ataxiaOpen,
          onTap: () => setState(() => _ataxiaOpen = !_ataxiaOpen),
          titleColor: Colors.redAccent,
          child: _symptomChecklist(
            options: const [
              'Dismetri',
              'Disdiadokokinezi',
              'İntansiyonel tremor',
              'Gövde ataksisi',
              'Nistagmus',
              'Postüral instabilite',
            ],
            selected: _ataxiaSymptoms,
            extraCtrl: _ataxiaExtraCtrl,
          ),
        ),
        const SizedBox(height: 18),
        _field(
          controller: _diseaseNoteCtrl,
          hint: 'Klinisyen notları...',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _scoreBox({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        _field(
          controller: controller,
          hint: hint,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFunctional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _expandCard(
          title: 'General Test',
          open: _generalTestOpen,
          onTap: () => setState(() => _generalTestOpen = !_generalTestOpen),
          titleColor: _primary,
          child: Column(
            children: [
              _scoreBox(
                label: '30 Saniye Otur Kalk Testi',
                hint: 'Tekrar sayısı',
                controller: _chairStandCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Zamanlı Kalk ve Yürü Testi',
                hint: 'Saniye',
                controller: _timedUpGoCtrl,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _scoreBox(
                      label: '9-Delikli Peg Testi Sağ',
                      hint: 'Saniye',
                      controller: _pegRightCtrl,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _scoreBox(
                      label: '9-Delikli Peg Testi Sol',
                      hint: 'Saniye',
                      controller: _pegLeftCtrl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'CTSIB',
          open: _ctsibOpen,
          onTap: () => setState(() => _ctsibOpen = !_ctsibOpen),
          titleColor: const Color(0xFF8B19FF),
          child: Column(
            children: [
              _scoreBox(
                label: 'Gözler Açık - Sert Zemin',
                hint: 'Sayı',
                controller: _ctsibFirmOpenCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Gözler Kapalı - Sert Zemin',
                hint: 'Sayı',
                controller: _ctsibFirmClosedCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Gözler Açık - Yumuşak Zemin',
                hint: 'Sayı',
                controller: _ctsibSoftOpenCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Gözler Kapalı - Yumuşak Zemin',
                hint: 'Sayı',
                controller: _ctsibSoftClosedCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'PST',
          open: _pstOpen,
          onTap: () => setState(() => _pstOpen = !_pstOpen),
          titleColor: const Color(0xFF0BAA3A),
          child: Column(
            children: [
              _scoreBox(
                label: 'Anterior-Posterior Salınım',
                hint: 'Sayı',
                controller: _pstAnteriorPosteriorCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Medio-Lateral Salınım',
                hint: 'Sayı',
                controller: _pstMedialLateralCtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'Total Salınım',
                hint: 'Sayı',
                controller: _pstOverallCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Trail-making Test',
          open: _trailOpen,
          onTap: () => setState(() => _trailOpen = !_trailOpen),
          titleColor: const Color(0xFFFF5A00),
          child: Column(
            children: [
              _scoreBox(
                label: 'TEST A',
                hint: 'Saniye',
                controller: _trailPartACtrl,
              ),
              const SizedBox(height: 18),
              _scoreBox(
                label: 'TEST B',
                hint: 'Saniye',
                controller: _trailPartBCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _expandCard(
          title: 'Stroop Testi',
          open: _stroopOpen,
          onTap: () => setState(() => _stroopOpen = !_stroopOpen),
          titleColor: Colors.red,
          child: _scoreBox(
            label: 'Stroop Testi',
            hint: 'Sonuç',
            controller: _stroopCtrl,
          ),
        ),
      ],
    );
  }

  Widget _currentStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildDemographics();
      case 1:
        return _buildSymptoms();
      case 2:
        return _buildDisease();
      case 3:
        return _buildFunctional();
      default:
        return _buildDemographics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _topAppBar(),
      body: Consumer<EvaluationProvider>(
        builder: (context, provider, _) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                _headerBand(),
                _stepTabs(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    children: [
                      _sectionIntro(),
                      const SizedBox(height: 20),
                      _currentStepBody(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (provider.isFormLoading || _isSaving)
                              ? null
                              : _handleContinue,
                          icon: (provider.isFormLoading || _isSaving)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSaving
                                ? 'Kaydediliyor...'
                                : (_isLastStep
                                    ? 'Değerlendirmeyi Kaydet'
                                    : 'Kaydet ve Devam Et'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            disabledBackgroundColor: _primary.withOpacity(0.45),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _currentStep--),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Önceki Bölüm'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepItem {
  final String label;
  final IconData icon;

  const _StepItem(this.label, this.icon);
}
